ruleset twilio_app {

  meta {
    use module com.tcashcroft.twilio alias sdk
    with 
      apiKey = meta:rulesetConfig{"apiKey"}
      sessionId = meta:rulesetConfig{"sessionId"}
      phoneNumber = meta:rulesetConfig{"phoneNumber"}
    shares getMessages
  }

  global {

    getMessages = function(filters) {
      filters.isnull() => sdk:getMessages() | sdk:getMessagesFiltered(filters)
    }

  }

  rule sendMessage {
    select when send new_message
    pre {
      message = event:attrs{"message"}
      messageLen = message.length().klog("Message Length: ")
      targetPhoneNumber = event:attrs{"targetPhoneNumber"}.sprintf("%d").klog("Target Phone Number: ")
      targetPhoneNumberLen = targetPhoneNumber.length().klog("Phone Number Length: ")
      valid = (messageLen != 0 && targetPhoneNumberLen >= 10).klog("valid?: ")
    }

    if valid then sdk:sendMessage(targetPhoneNumber, message) setting(response)

    fired {
      raise send event "sent" attributes event:attrs
    }

  }
}
