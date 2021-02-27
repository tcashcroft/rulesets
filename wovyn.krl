
ruleset com.tcashcroft.wovyn_base {

  meta {
    name "Wovyn"
    logging on
    shares current_threshold, current_target_phone_number, twilio_config
    use module com.tcashcroft.twilio alias sdk
    with
      apiKey = meta:rulesetConfig{"apiKey"}
      sessionId = meta:rulesetConfig{"sessionId"}
      phoneNumber = meta:rulesetConfig{"phoneNumber"}
  }

  global {
    current_threshold = function() {
      ent:temperature_threshold
    }

    current_target_phone_number = function() {
      ent:targetPhoneNumber
    }

    twilio_config = function() {
      config = sdk:getConfiguration() 
      config || {"message": "error getting twilio config"}
    }
  }

  rule init {
    select when wrangler ruleset_installed where event:attrs{"rids"} >< meta:rid
    always {
      ent:temperature_threshold := 78
      ent:targetPhoneNumber := meta:rulesetConfig{"targetPhoneNumber"}
    }
  }

  rule process_heartbeat {
    select when wovyn heartbeat
    pre {
      valid = not event:attrs{"genericThing"}.isnull().klog("genericThing is null?")
      temperature = event:attrs{"genericThing"}.get(["data", "temperature", "0", "temperatureF"])
    }
    if valid then send_directive("wovyn", {"body" : "temperature received"})
    // send_directive("wovyn", {"body": "THE EVENT FIRED"})
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

  rule sendMonitoringMessage {
    select when wovyn threshold_violation
    pre {
      message = "Temperature threshold exceeded. Threshold: " + event:attrs{"threshold"} + " Temperature: " + event:attrs{"temperature"}
      messageLen = message.length()
      targetPhoneNumberLen = ent:targetPhoneNumber.length().klog("Phone Number Length: ")
      valid = (messageLen != 0 && targetPhoneNumberLen >= 10).klog("valid?: ")
    }

    if valid then sdk:sendMessage(ent:targetPhoneNumber, message) setting(response)

    fired {
      raise send event "sent" attributes event:attrs
    }

  }

  rule updateProfile {
    select when sensor profile_update_complete
    pre {
      newThreshold = event:attrs{"threshold"}
    }
    noop()
    always {
      raise twilio event "update" attributes {"apiKey": event:attrs{"apiKey"}, "sessionId": event:attrs{"sessionId"}, "phoneNumber": event:attrs{"phoneNumber"}}
      ent:targetPhoneNumber := event:attrs{"targetPhoneNumber"}
      ent:temperature_threshold := newThreshold
    }
  }

}
