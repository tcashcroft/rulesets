
ruleset com.tcashcroft.temperature_store {

  meta {
    name "Temperature Store"
    logging on
    shares temperatures, threshold_violations, inrange_temperatures
    provides temperatures, threshold_violations, inrange_temperatures
  }

  global {
    temperatures = function() {
      ent:temperatures
    } 

    threshold_violations = function() {
      ent:violations
    }

    in_violations = function(obj) {
      in_viols = ent:violations.filter(function(it) {
       timestamp_bool = (it{"timestamp"} == obj{"timestamp"}).klog("Timestamps equal?")
       temperature_bool = (it{"temperature"} == obj{"temperature"}).klog("Temperatures equal?")
       timestamp_bool && temperature_bool
      }).klog("Viols")
      in_viols.length() > 0
    }

    inrange_temperatures = function() {
      res = ent:temperatures.filter(function(it) {
        not in_violations(it)
      })
      return res
    }
  }

  rule init {
    select when wrangler ruleset_installed where event:attrs{"rids"} >< meta:rid
    always {
      ent:temperatures := []
      ent:violations := []
      raise temperature_store event "initialized"
    }
  }

  rule collect_temperatures {
    select when wovyn new_temperature_reading

    always {
      ent:temperatures := ent:temperatures.append({"temperature": event:attrs{"temperature"}, "timestamp": event:attrs{"timestamp"}}).klog("Adding temperature to store")
      raise temperature_store event "received"
    }
  }

  rule collect_threshold_violations {
    select when wovyn threshold_violation

    always {
      ent:violations := ent:violations.append({"threshold": event:attrs{"threshold"}, "temperature": event:attrs{"temperature"}, "timestamp": event:attrs{"timestamp"}}).klog("Adding temperature to store")
      raise temperature_store event "violation_received"
    }
  }

  rule clear_temperatures {
    select when sensor reading_reset
    always {
      ent:temperatures := []
      ent:violations := []
      raise temperature_store event "reset"
    }
  }
} 
