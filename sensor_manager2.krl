
ruleset com.tcashcroft.manage_sensors {

  meta {
    name "Sensor Manager"
    logging on
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias subscription
    use module com.tcashcroft.twilio alias twilioSdk
    with
      apiKey = meta:rulesetConfig{"apiKey"}
      sessionId = meta:rulesetConfig{"sessionId"}
      phoneNumber = meta:rulesetConfig{"phoneNumber"}
    shares subscribed_sensors, children, children_temperatures, subscribed_sensors_temperatures, children_profiles, subscribed_sensors_profiles, get_wellKnown_eci 
  }

  global {
    subscribed_sensors = function() {
      ent:subscribed_sensors
    }

    children = function(){
      ent:children
    }

    nameFromID = function(id) {
      "Sensor " + id 
    }
  
    children_temperatures = function() {
      temperatures = ent:children.map(function(v, k) { wrangler:picoQuery(v.get("eci"), "com.tcashcroft.temperature_store", "current_temperature", {})})
      temperatures
    }

    subscribed_sensors_temperatures = function() {
      // subscribed_temperatures = ent:subscribed_sensors.map(function(v,k) { wrangler:picoQuery(v.get("subscriptionTx"), "com.tcashcroft.temperature_store", "current_temperature", {})})
      subscribed_temperatures = ent:subscribed_sensors.map(function(v,k){
        url = (v.get("txHost") + "/sky/cloud/" + v.get("subscriptionTx") + "/com.tcashcroft.temperature_store/current_temperature").klog("GET Url: ")
        http:get(url, {}){"content"}.decode()
      })
      subscribed_temperatures
    }

    children_profiles = function() {
      profiles = ent:children.map(function(v,k){wrangler:picoQuery(v.get("eci"), "com.tcashcroft.sensor_profile", "current_profile", {}) })
      profiles
    }

    subscribed_sensors_profiles = function(){
      subscribed_profiles = ent:subscribed_sensors.map(function(v,k){
        wrangler:picoQuery(v.get("subscriptionTx"), "com.tcashcroft.sensor_profile", "current_profile", {}, v.get("txHost"))
      })
      subscribed_profiles
    }

    getTwilioConfig = function() {
      twilio_config = {
        "apiKey" : ent:apiKey,
        "sessionId": ent:sessionId,
        "phoneNumber": ent:phoneNumber
      }
      twilio_config
    }

    get_wellKnown_eci = function(){
      subscription:wellKnown_Rx(){"id"}
    }
  }

  rule init {
    select when wrangler ruleset_installed where event:attrs{"rids"} >< meta:rid
    always {
      ent:subscribed_sensors := {}
      ent:children := {}
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

  rule create_managed_sensor {
    select when sensor new_sensor
    pre {
      name_to_use = event:attrs{"new_sensor_name"} || nameFromID(ent:counter)
      is_valid = ent:sensors >< name_to_use
    }
    if not is_valid then send_directive("Creating child", {"new_sensor_name": name_to_use})
    fired {
      raise wrangler event "new_child_request" attributes {"name": name_to_use, "backgroundColor": "#CC00CC"}
      ent:counter := ent:counter + 1
    } else {  
      raise sensor event "child_exists" attributes {"existing_name" : name_to_use}
    }
  }

  rule child_to_store {
    select when wrangler new_child_created
    pre {
      child_eci = event:attrs{"eci"}
      child_meta = {"eci": child_eci}
      child_name = event:attrs{"name"}
    }
    always {
      ent:children{child_name} := child_meta
      raise sensor event "stored" attributes {"child_name" : child_name}
    } 
  }

  rule stored_child {
    select when sensor stored
    pre {
      child_name = event:attrs{"child_name"}
    }
    event:send({
      "eci": ent:children{child_name}.get("eci"),
      "eid": "install_child_base",
      "domain": "wrangler",
      "type": "install_ruleset_request",
      "attrs": {
        "absoluteURL": "file:///home/tashcrof/workspace/krl/rulesets/child_base.krl",
        "rid": "child_base",
        "config": {},
        "name": child_name
      }
    })
    fired {
      raise sensor event "child_base_installed" attributes {"child_name": child_name}
    } else {
      raise sensor event "rule_installation_failed" attributes {"child_name": child_name}
    }
  }

  rule add_wovyn_base_ruleset {
    select when sensor child_base_installed
    pre {
      child_name = event:attrs{"child_name"}
    }
    event:send({
      "eci": ent:children{child_name}.get("eci"),
      "eid": "install_wovyn_base_ruleset",
      "domain": "wrangler",
      "type": "install_ruleset_request",
      "attrs": {
        //"absoluteURL": "https://raw.githubusercontent.com/tcashcroft/rulesets/lab7/wovyn.krl",
        "absoluteURL": "file:///home/tashcrof/workspace/krl/rulesets/wovyn.krl",
        "rid": "wovyn",
        "config": getTwilioConfig(),
        "name": child_name
      }
    })

    fired {
      raise sensor event "wovyn_base_installed" attributes {"child_name": child_name}
    } else {
      raise sensor event "rule_installation_failed" attributes {"child_name": child_name}
    }
  }

  rule add_sensor_profile_ruleset {
    select when sensor wovyn_base_installed
    pre {
      child_name = event:attrs{"child_name"}
    }
    event:send({
      "eci": ent:children{child_name}.get("eci"),
      "eid": "install_wovyn_base_ruleset",
      "domain": "wrangler",
      "type": "install_ruleset_request",
      "attrs": {
        //"absoluteURL": "https://raw.githubusercontent.com/tcashcroft/rulesets/lab7/sensor_profile.krl",
        "absoluteURL": "file:///home/tashcrof/workspace/krl/rulesets/sensor_profile.krl",
        "rid": "sensor_profile",
        "config": getTwilioConfig(),
        "name": child_name,
        "is_sensor": true
      }
    })

    fired {
      raise sensor event "sensor_profile_installed" attributes {"child_name": child_name, "is_sensor": true}
    } else {
      raise sensor event "rule_installation_failed" attributes {"child_name": child_name}
    }
  }

  rule add_temperature_store_ruleset {
    select when sensor sensor_profile_installed
    pre {
      child_name = event:attrs{"child_name"}
    }
    event:send({
      "eci": ent:children{child_name}.get("eci"),
      "eid": "install_wovyn_base_ruleset",
      "domain": "wrangler",
      "type": "install_ruleset_request",
      "attrs": {
        //"absoluteURL": "https://raw.githubusercontent.com/tcashcroft/rulesets/lab7/temperature_store.krl",
        "absoluteURL": "file:///home/tashcrof/workspace/krl/rulesets/temperature_store.krl",
        "rid": "temperature_store",
        "config": {},
        "name": child_name,
        "is_sensor": true
      }
    })

    fired {
      raise sensor event "temperature_store_installed" attributes {"child_name": child_name, "is_sensor": true}
    } else {
      raise sensor event "rule_installation_failed" attributes {"child_name": child_name}
    }
  }

  rule add_wovyn_emitter_ruleset {
    select when sensor temperature_store_installed 
    pre {
      child_name = event:attrs{"child_name"}
    }
    event:send({
      "eci": ent:children{child_name}.get("eci"),
      "eid": "install_wovyn_base_ruleset",
      "domain": "wrangler",
      "type": "install_ruleset_request",
      "attrs": {
        "absoluteURL": "https://raw.githubusercontent.com/windley/temperature-network/main/io.picolabs.wovyn.emitter.krl",
        "rid": "io.picolabs.wovyn.emitter",
        "config": {},
        "name": child_name,
        "is_sensor": true
      }
    })

    fired {
      raise sensor event "wovyn_emitter_installed" attributes {"child_name": child_name, "is_sensor": true}
    } else {
      raise sensor event "rule_installation_failed" attributes {"child_name": child_name}
    }
  }

  rule add_sensor_base_ruleset {
    select when sensor temperature_store_installed
    pre {
      child_name = event:attrs{"child_name"}
    }
    event:send({
      "eci": ent:children{child_name}.get("eci"),
      "eid": "install_sensor_child_base",
      "domain": "wrangler",
      "type": "install_ruleset_request",
      "attrs": {
        //"absoluteURL": "https://raw.githubusercontent.com/tcashcroft/rulesets/lab7/sensor_child_base.krl",
        "absoluteURL": "file:///home/tashcrof/workspace/krl/rulesets/sensor_child_base.krl",
        "rid": "sensor_child_base",
        "config": {},
        "name": child_name,
        "is_sensor": true
      }
    })
    fired {
      raise sensor event "sensor_base_installed" attributes {"child_name": child_name, "is_sensor": true}
    } else {
      raise sensor event "rule_installation_failed" attributes {"child_name": child_name}
    }
  }

  rule auto_accept_sensor_subscription {
    select when wrangler inbound_pending_subscription_added
      sensor_name re#(.+)#
    pre {
      my_role = event:attrs{"Rx_role"}.klog("my role: ")
      their_role = event:attrs{"Tx_role"}.klog("their role: ")
      sensor_name = event:attrs{"sensor_name"}.klog("sensor name: ")
      name_is_available = not (ent:subscribed_sensors >< sensor_name)
      temp = event:attrs.put("temp", "temp").klog("Subscription Event Attrs")
    }
    if my_role == "manager" && their_role == "sensor" && name_is_available then noop()
    fired {
      // raise wrangler event "pending_subscription_approval" attributes event:attrs
      raise wrangler event "pending_subscription_approval" attributes {"Id": event:attrs{"Id"}}
      ent:subscribed_sensors{sensor_name} := {
        "subscriptionTx" : event:attrs{"Tx"},
        "subscriptionId" : event:attrs{"Id"},
        "txHost" : event:attrs{"Tx_host"}
      }
    }
    else {
      raise wrangler event "inbound_rejection" attributes event:attrs.put("name_is_available", name_is_available)
    }
  }

  rule remove_child {
    select when sensor unneeded_child
    pre {
      child_name = event:attrs{"child_name"}
      is_present = ent:children >< child_name
    }
      if is_present then 

    event:send({
      "eci": ent:children{child_name}.get("eci"),
      "eid": "child_deletion_request",
      "domain": "wrangler",
      "type": "child_deletion_request",
    })
    fired {
      ent:children := ent:children.delete(child_name)
    } 
  }

  rule remove_subscribed_sensor {
    select when sensor unneeded_sensor
    pre {
      sensor_name = event:attrs{"sensor_name"}
      is_present = ent:subscribed_sensors >< sensor_name
    }
    if is_present then noop()
    fired {
      raise wrangler event "subscription_cancellation" attributes { "Id": ent:subscribed_sensors{sensor_name}.get("id")}
      ent:subscribed_sensors := ent:subscribed_sensors.delete(sensor_name)
    }
  }

  rule handle_threshold_violation {
    select when wovyn threshold_violation
    pre {
      message = "Temperature threshold exceeded. Threshold: " + event:attrs{"threshold"} + " Temperature: " + event:attrs{"temperature"}
    }

    twilioSdk:sendMessage(ent:targetPhoneNumber, message)
  }

  rule update_subscribed_profile {
    select when sensor subscribed_profile_update_requested
    pre {
      name = event:attrs{"name"} || event:attrs{"sensorName"} 
      location = event:attrs{"location"} || ent:location
      threshold = event:attrs{"threshold"} || ent:threshold
      sensorName = event:attrs{"sensorName"}  
    }
    event:send({
      "eci": ent:subscribed_sensors{sensorName}.get("subscriptionTx"),
      "eid": "profile_updated",
      "domain": "sensor",
      "type": "profile_updated",
      "attrs": {
        "location" : location,
        "threshold" : threshold,
        "name" : name
      }
    }, ent:subscribed_sensors{sensorName}.get("txHost"))
    fired {
      raise sensor event "subscribed_profile_update_complete" attributes {"new_sensor_name": sensorName}
    }
  }

  rule update_child_profile {
    select when sensor child_profile_update_requested
    pre {
      name = event:attrs{"name"} || event:attrs{"sensorName"} 
      location = event:attrs{"location"} || ent:location
      threshold = event:attrs{"threshold"} || ent:threshold
      sensorName = event:attrs{"sensorName"}  
    }
    event:send({
      "eci": ent:children{sensorName}.get("eci"),
      "eid": "profile_updated",
      "domain": "sensor",
      "type": "profile_updated",
      "attrs": {
        "location" : location,
        "threshold" : threshold,
        "name" : name
      }
    }, ent:subscribed_sensors{sensorName}.get("txHost"))
    fired {
      raise sensor event "child_profile_update_complete" attributes {"new_sensor_name": sensorName}
    }
  }

  rule install_default_profile {
    select when sensor wovyn_emitter_installed
    pre {
      threshold = event:attrs{"threshold"} || ent:threshold
      name = event:attrs{"child_name"} || event:attrs{"name"} || "Sensor -1"       
      location = event:attrs{"location"} || ent:location
    }
    always {
      raise sensor event "child_profile_update_requested" attributes {
        "name": name,
        "sensorName": name,
        "location": location,
        "threshold": threshold,
      }
    }
  }
}
