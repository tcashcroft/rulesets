ruleset com.tcashcroft.sensor_profile {

  meta {
    name "Sensor Profile"
    logging on
    shares current_profile
    use module com.tcashcroft.twilio alias twilio
    with 
      apiKey = meta:rulesetConfig{"apiKey"}
      sessionId = meta:rulesetConfig{"sessionId"}
      phoneNumber = meta:rulesetConfig{"phoneNumber"}
      targetPhoneNumber = meta:rulesetConfig{"targetPhoneNumber"}
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
        "targetPhoneNumber" : meta:rulesetConfig{"targetPhoneNumber"},
        "location" : meta:rulesetConfig{"location"},
        "threshold" : meta:rulesetConfig{"threshold"},
        "name" : meta:rulesetConfig{"name"}
      }
      ent:full_profile := {
        "apiKey" : meta:rulesetConfig{"apiKey"},
        "sessionId" : meta:rulesetConfig{"sessionId"},
        "phoneNumber" : meta:rulesetConfig{"phoneNumber"},
        "targetPhoneNumber" : meta:rulesetConfig{"targetPhoneNumber"},
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
      newTargetPhoneNumber = event:attrs{"targetPhoneNumber"}
    }
    send_directive("new_threshold", {"value" : newThreshold})
    always {
      raise sensor event "profile_update_complete" attributes {
        "apiKey" : meta:rulesetConfig{"apiKey"},
        "sessionId" : meta:rulesetConfig{"sessionId"},
        "phoneNumber" : meta:rulesetConfig{"phoneNumber"},
        "targetPhoneNumber" : newTargetPhoneNumber,
        "location" : newLocation,
        "threshold" : newThreshold,
        "name" : newName
      };
      ent:current_profile := {
        "targetPhoneNumber" : newTargetPhoneNumber,
        "location" : newLocation,
        "threshold" : newThreshold,
        "name" : newName
      };
      ent:full_profile := {
        "apiKey" : meta:rulesetConfig{"apiKey"},
        "sessionId" : meta:rulesetConfig{"sessionId"},
        "phoneNumber" : meta:rulesetConfig{"phoneNumber"},
        "targetPhoneNumber" : newTargetPhoneNumber,
        "location" : newLocation,
        "threshold" : newThreshold,
        "name" : newName
      };
    }
  }

  // added for lab6, attempting to maintain backwards compatibility with lab5
  rule prcoess_full_profile_update {
    select when sensor_profile full_profile_updated
    pre {
      apiKey = event:attrs{"apiKey"}
      sessionId = event:attrs{"sessionId"}
      phoneNumber = event:attrs{"phoneNumber"}
      targetPhoneNumber = event:attrs{"targetPhoneNumber"}
      name = event:attrs{"name"}
      location = event:attrs{"location"}
      threshold = event:attrs{"threshold"}
    }
    always {
      raise sensor event "profile_update_complete" attributes {
        "apiKey" : apiKey,
        "sessionId" : sessionId,
        "phoneNumber" : phoneNumber,
        "targetPhoneNumber" : targetPhoneNumber,
        "location" : location,
        "threshold" : threshold,
        "name" : name
      };
      ent:current_profile := {
        "targetPhoneNumber" : targetPhoneNumber,
        "location" : location,
        "threshold" : threshold,
        "name" : name
      };
      ent:full_profile := {
        "apiKey" : apiKey,
        "sessionId" : sessionId,
        "phoneNumber" : phoneNumber,
        "targetPhoneNumber" : targetPhoneNumber,
        "location" : location,
        "threshold" : threshold,
        "name" : name
      };
    }
  } 
}
