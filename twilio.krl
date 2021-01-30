ruleset com.tcashcroft.twilio {

  meta {
    name "Twilio"
    logging on
    configure using
      apiKey = ""
      sessionId = "" 
      phoneNumber = ""
    provides getMessages, sendMessage
  }
  global {
     baseUrl = "https://api.twilio.com/2010-04-01"
     authString = {"username":sessionId, "password":apiKey}

     getMessages = function() {
       http:get(<<#{baseUrl}/Accounts/#{sessionId}/Messages.json>>, auth=authString){"content"}.decode().klog("get Messages: ")
     }

     sendMessage = defaction(targetPhoneNumber, message) {
       formString = {"To": targetPhoneNumber, "From": phoneNumber, "Body": message}.klog("Form string:")
       http:post(<<#{baseUrl}/Accounts/#{sessionId}/Messages.json>>, form=formString, auth=authString) setting(response)
       return response{"content"}.decode()
     }
  }
}
