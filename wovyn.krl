
ruleset com.tcashcroft.wovyn_base {

  meta {
    name "Wovyn"
    logging on
    shares current_threshold 
  }

  global {
    current_threshold = function() {
      ent:temperature_threshold
    }
  }

  rule init {
    select when wrangler ruleset_installed where event:attrs{"rids"} >< meta:rid
    always {
      ent:temperature_threshold := 78
    }
  }

  rule process_heartbeat {
    select when wovyn heartbeat
    pre {
      valid = not event:attrs{"genericThing"}.isnull().klog("genericThing is null?")
      temperature = event:attrs{"genericThing"}.get(["data", "temperature", "0", "temperatureF"])
    }
    if valid then send_directive("wovyn", {"body" : "temperature received"})
    fired {
      raise wovyn event "new_temperature_reading" attributes {"temperature": temperature, "timestamp": event:time}
    } else {
      raise bogus event "was invalid" attributes {"someOtherVal": -2}
    }
  }

  rule find_high_temps {
    select when wovyn new_temperature_reading
    pre {
      exceed_threshold = event:attrs{"temperature"} > ent:temperature_threshold
    }
    if exceed_threshold then send_directive("wovyn", {"body": "Threshold was exceeded"})

    fired {
      raise wovyn event "threshold_violation" attributes {"temperature": event:attrs{"temperature"}, "timestamp": event:attrs{"timestamp"}, "threshold": ent:temperature_threshold}
    }
    
  }

  rule updateProfile {
    select when sensor profile_update_complete
    pre {
      newThreshold = event:attrs{"threshold"}
    }
    noop()
    always {
      ent:temperature_threshold := newThreshold
    }
  }
}
