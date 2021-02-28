ruleset com.tcashcroft.twilio {

  meta {
    name "Twilio"
    logging on
    configure using
      apiKey = ""
      sessionId = "" 
      phoneNumber = ""
    provides getMessages, getMessagesFiltered, sendMessage, getConfiguration
  }
  global {
     baseUrl = "https://api.twilio.com/2010-04-01"
     authString = {"username": sessionId, "password": apiKey}

     getMessages = function() {
       http:get(<<#{baseUrl}/Accounts/#{sessionId}/Messages.json>>, auth=authString){"content"}.decode().klog("get Messages: ")
     }

     getMessagesFiltered = function(filters) {
       http:get(<<#{baseUrl}/Accounts/#{sessionId}/Messages.json>>, auth=authString, qs=filters){"content"}.decode().klog("get Messages: ")
     }

     sendMessage = defaction(targetPhoneNumber, message) {
       formString = {"To": targetPhoneNumber, "From": phoneNumber, "Body": message}.klog("Form string:")
       idToUse = sessionId
       http:post(<<#{baseUrl}/Accounts/#{idToUse}/Messages.json>>, form=formString, auth=authString) setting(response)
       return response{"content"}.decode()
     }

     getConfiguration = function() {
       config = {"apiKey": apiKey, "sessionId": sessionId, "phoneNumber": phoneNumber}
       config || {}
    } 
  }
}
