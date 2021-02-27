
ruleset com.tcashcroft.manage_sensors {

  meta {
    name "Sensor Manager"
    logging on
    use module io.picolabs.wrangler alias wrangler
    shares sensors, temperatures, profiles 

  }

  global {
    sensors = function() {
      ent:sensors
    }

    nameFromID = function(id) {
      "Sensor " + id 
    }
  
    temperatures = function() {
      temperatures = ent:sensors.map(function(v, k) { wrangler:picoQuery(v.get("eci"), "com.tcashcroft.temperature_store", "current_temperature", {})})
      temperatures || {}
    }

    profiles = function() {
      profiles = ent:sensors.map(function(v,k){wrangler:picoQuery(v.get("eci"), "com.tcashcroft.sensor_profile", "current_profile", {}) })
      profiles || {}
    }

  }

  rule init {
    select when wrangler ruleset_installed where event:attrs{"rids"} >< meta:rid
    always {
      ent:sensors := {} 
      ent:counter := 1
      raise sensor_manager event "initialized"
      ent:sessionId := meta:rulesetConfig{"sessionId"}
      ent:apiKey := meta:rulesetConfig{"apiKey"}
      ent:phoneNumber := meta:rulesetConfig{"phoneNumber"}
      ent:threshold := meta:rulesetConfig{"threshold"}
      ent:targetPhoneNumber := meta:rulesetConfig{"targetPhoneNumber"}
      ent:location := meta:rulesetConfig{"location"}
    }
  }

  //rule temp {
  //  select when sensor_manager initialized
  //  always {
  //    raise sensor event "new_sensor"
  //  }
  //}

  rule create_managed_sensor {
    select when sensor new_sensor
    pre {
      name_to_use = event:attrs{"name"} || nameFromID(ent:counter)
    }
    always {
      raise wrangler event "new_child_request" attributes {"name": name_to_use, "backgroundColor": "#000000"}
      ent:counter := ent:counter + 1
    }  
  }
  
  rule store_new_sensor {
    select when wrangler new_child_created
    pre {
      sensor_eci = event:attrs{"eci"}
      sensor_meta = {"eci" : sensor_eci }
      sensor_name = event:attrs{"name"}
    }

    always {
      ent:sensors{sensor_name} := sensor_meta
      raise sensor event "stored" attributes {"new_sensor_name" : sensor_name}
    }
  }

  rule add_twilio_base_ruleset {
    select when sensor stored
    pre {
      sensor_name = event:attrs{"new_sensor_name"}
    }
    event:send({
      "eci": ent:sensors{sensor_name}.get("eci"),
      "eid": "install_twilio_base_ruleset",
      "domain": "wrangler",
      "type": "install_ruleset_request",
      "attrs": {
        "absoluteURL": "https://raw.githubusercontent.com/tcashcroft/rulesets/master/twilio.krl",
        "rid": "twilio",
        "config": {},
        "name": sensor_name
      }
    })
    fired {
      raise sensor event "twilio_base_installed" attributes {"new_sensor_name": sensor_name}
    } else {
      raise sensor event "rule_installation_failed" attributes {"new_sensor_name": sensor_name}
    }
  }

  rule add_wovyn_base_ruleset {
    select when sensor twilio_base_installed
    pre {
      sensor_name = event:attrs{"new_sensor_name"}
    }
    event:send({
      "eci": ent:sensors{sensor_name}.get("eci"),
      "eid": "install_wovyn_base_ruleset",
      "domain": "wrangler",
      "type": "install_ruleset_request",
      "attrs": {
        "absoluteURL": "https://raw.githubusercontent.com/tcashcroft/rulesets/master/wovyn.krl",
        "rid": "wovyn",
        "config": {},
        "name": sensor_name
      }
    })

    fired {
      raise sensor event "wovyn_base_installed" attributes {"new_sensor_name": sensor_name}
    } else {
      raise sensor event "rule_installation_failed" attributes {"new_sensor_name": sensor_name}
    }
  }

  rule add_sensor_profile_ruleset {
    select when sensor wovyn_base_installed
    pre {
      sensor_name = event:attrs{"new_sensor_name"}
    }
    event:send({
      "eci": ent:sensors{sensor_name}.get("eci"),
      "eid": "install_wovyn_base_ruleset",
      "domain": "wrangler",
      "type": "install_ruleset_request",
      "attrs": {
        //"absoluteURL": "https://raw.githubusercontent.com/tcashcroft/rulesets/master/sensor_profile.krl",
        //"absoluteURL": "https://raw.githubusercontent.com/tcashcroft/rulesets/lab6/sensor_profile.krl",
        "absoluteURL": "file:///home/tashcrof/workspace/krl/rulesets/sensor_profile.krl",
        "rid": "sensor_profile",
        "config": {},
        "name": sensor_name
      }
    })

    fired {
      raise sensor event "sensor_profile_installed" attributes {"new_sensor_name": sensor_name}
    } else {
      raise sensor event "rule_installation_failed" attributes {"new_sensor_name": sensor_name}
    }
  }

  rule add_temperature_store_ruleset {
    select when sensor sensor_profile_installed
    pre {
      sensor_name = event:attrs{"new_sensor_name"}
    }
    event:send({
      "eci": ent:sensors{sensor_name}.get("eci"),
      "eid": "install_wovyn_base_ruleset",
      "domain": "wrangler",
      "type": "install_ruleset_request",
      "attrs": {
        "absoluteURL": "https://raw.githubusercontent.com/tcashcroft/rulesets/master/temperature_store.krl",
        "rid": "temperature_store",
        "config": {},
        "name": sensor_name
      }
    })

    fired {
      raise sensor event "temperature_store_installed" attributes {"new_sensor_name": sensor_name}
    } else {
      raise sensor event "rule_installation_failed" attributes {"new_sensor_name": sensor_name}
    }
  }

  rule add_wovyn_emitter_ruleset {
    select when sensor temperature_store_installed 
    pre {
      sensor_name = event:attrs{"new_sensor_name"}
    }
    event:send({
      "eci": ent:sensors{sensor_name}.get("eci"),
      "eid": "install_wovyn_base_ruleset",
      "domain": "wrangler",
      "type": "install_ruleset_request",
      "attrs": {
        "absoluteURL": "https://raw.githubusercontent.com/windley/temperature-network/main/io.picolabs.wovyn.emitter.krl",
        "rid": "io.picolabs.wovyn.emitter",
        "config": {},
        "name": sensor_name
      }
    })

    fired {
      raise sensor event "wovyn_emitter_installed" attributes {"new_sensor_name": sensor_name}
    } else {
      raise sensor event "rule_installation_failed" attributes {"new_sensor_name": sensor_name}
    }
  }

  rule update_profile {
    select when sensor profile_update_requested
    pre {
      apiKey = event:attrs{"apiKey"} || ent:apiKey
      sessionId = event:attrs{"sessionId"} || ent:sessionId
      phoneNumber = event:attrs{"phoneNumber"} || ent:phoneNumber
      targetPhoneNumber = event:attrs{"targetPhoneNumber"} || ent:targetPhoneNumber
      name = event:attrs{"name"} || event:attrs{"sensorName"} 
      location = event:attrs{"location"} || ent:location
      threshold = event:attrs{"threshold"} || ent:threshold
      sensorName = event:attrs{"sensorName"}  
    }
    event:send({
      "eci": ent:sensors{sensorName}.get("eci"),
      "eid": "full_profile_updated",
      "domain": "sensor_profile",
      "type": "full_profile_updated",
      "attrs": {
        "apiKey" : apiKey,
        "sessionId" : sessionId,
        "phoneNumber" : phoneNumber,
        "targetPhoneNumber" : targetPhoneNumber,
        "location" : location,
        "threshold" : threshold,
        "name" : name
      }
    })
    fired {
      raise sensor event "child_profile_update_complete" attributes {"new_sensor_name": sensorName}
    }
  }

  rule install_default_profile {
    select when sensor wovyn_emitter_installed
    pre {
      sessionId = event:attrs{"sessionId"} || ent:sessionId
      apiKey = event:attrs{"apiKey"} || ent:apiKey
      phoneNumber = event:attrs{"phoneNumber"} || ent:phoneNumber
      threshold = event:attrs{"threshold"} || ent:threshold
      name = event:attrs{"name"} || event:attrs{"new_sensor_name"} || "Sensor -1"       
      targetPhoneNumber = event:attrs{"targetPhoneNumber"} || ent:targetPhoneNumber
      location = event:attrs{"location"} || ent:location
    }
    always {
      raise sensor event "profile_update_requested" attributes {
        "apiKey": apiKey,
        "sessionId": sessionId,
        "phoneNumber": phoneNumber,
        "targetPhoneNumber": targetPhoneNumber,
        "name": name,
        "sensorName": name,
        "location": location,
        "threshold": threshold
      }
    }
  }

  rule remove_sensor {
    select when sensor unneeded_sensor
    pre {
      sensor_name = event:attrs{"sensor_name"}
      is_present = ent:sensors >< sensor_name
    }
      if is_present then 

    event:send({
      "eci": ent:sensors{sensor_name}.get("eci"),
      "eid": "child_deletion_request",
      "domain": "wrangler",
      "type": "child_deletion_request",
    })
    fired {
      ent:sensors := ent:sensors.delete(sensor_name)
    } 
  }

  rule remove_malformed_sensor_children {
    select when sensor rule_installation_failed
    always {
      raise sensor event "unneeded_sensor" attributes {"sensor_name": event:attrs{"new_sensor_name"}}
    }
  }
}
