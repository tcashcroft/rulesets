ruleset com.tcashcroft.sensor_profile {

  meta {
    name "Sensor Profile"
    logging on
    shares current_profile
  }

  global {
     
    current_profile = function() {
      ent:current_profile
    }
  }

  rule init {
    select when wrangler ruleset_installed where event:attrs{"rids"} >< meta:rid
    always {
      ent:current_profile := {
        "location" : meta:rulesetConfig{"location"},
        "threshold" : meta:rulesetConfig{"threshold"},
        "name" : meta:rulesetConfig{"name"}
      }
    }
  }

  rule process_profile_update {
    select when sensor profile_updated
    pre {
      newLocation = event:attrs{"location"}
      newName = event:attrs{"name"}
      newThreshold = event:attrs{"threshold"}
    }
    send_directive("new_threshold", {"value" : newThreshold})
    always {
      raise sensor event "profile_update_complete" attributes {
        "location" : newLocation,
        "threshold" : newThreshold,
        "name" : newName
      };
      ent:current_profile := {
        "location" : newLocation,
        "threshold" : newThreshold,
        "name" : newName
      };
    }
  }
}
