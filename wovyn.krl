
ruleset com.tcashcroft.wovyn_base {

  meta {
    name "Wovyn"
    logging on
    use module com.tcashcroft.twilio alias sdk
    with
      apiKey = meta:rulesetConfig{"apiKey"}
      sessionId = meta:rulesetConfig{"sessionId"}
      phoneNumber = meta:rulesetConfig{"phoneNumber"}
      targetPhoneNumber = meta:rulesetConfig{"targetPhoneNumber"}
  }

  global {
    temperature_threshold = 78
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
      exceed_threshold = event:attrs{"temperature"} > temperature_threshold
    }
    if exceed_threshold then send_directive("wovyn", {"body": "Threshold was exceeded"})

    fired {
      raise wovyn event "threshold_violation" attributes {"temperature": event:attrs{"temperature"}, "timestamp": event:time, "threshold": temperature_threshold}
    }
    
  }

  rule sendMonitoringMessage {
    select when wovyn threshold_violation
    pre {
      message = "Temperature threshold exceeded. Threshold: " + event:attrs{"threshold"} + " Temperature: " + event:attrs{"temperature"}
      messageLen = message.length()
      targetPhoneNumberLen = meta:rulesetConfig{"targetPhoneNumber"}.length().klog("Phone Number Length: ")
      valid = (messageLen != 0 && targetPhoneNumberLen >= 10).klog("valid?: ")
    }

    if valid then sdk:sendMessage(meta:rulesetConfig{"targetPhoneNumber"}, message) setting(response)

    fired {
      raise send event "sent" attributes event:attrs
    }

  }

}
