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
     authString = {"username": ent:sessionId, "password": ent:apiKey}

     getMessages = function() {
       http:get(<<#{baseUrl}/Accounts/#{ent:sessionId}/Messages.json>>, auth=authString){"content"}.decode().klog("get Messages: ")
     }

     getMessagesFiltered = function(filters) {
       http:get(<<#{baseUrl}/Accounts/#{ent:sessionId}/Messages.json>>, auth=authString, qs=filters){"content"}.decode().klog("get Messages: ")
     }

     sendMessage = defaction(targetPhoneNumber, message) {
       formString = {"To": targetPhoneNumber, "From": ent:phoneNumber, "Body": message}.klog("Form string:")
       idToUse = ent:sessionId
       http:post(<<#{baseUrl}/Accounts/#{idToUse}/Messages.json>>, form=formString, auth=authString) setting(response)
       return response{"content"}.decode()
     }
    
     getConfiguration = function() {
       config = { "sessionId": ent:sessionId, "apiKey": ent:apiKey, "phoneNumber": ent:phoneNumber }
       config || {}
     }
  }

  rule init {
    select when wrangler ruleset_installed where event:attrs{"rids"} >< meta:rid
    always {
      ent:apiKey := apiKey || ""
      ent:sessionId := sessionId || ""
      ent:phoneNumber := phoneNumber || ""
    }
  }

  // added for lab6
  rule update {
    select when twilio update
    pre {
      newApiKey = event:attrs{"apiKey"} || ent:apiKey 
      newSessionId = event:attrs{"sessionId"} || ent:sessionId
      newPhoneNumber = event:attrs{"phoneNumber"} || ent:phoneNumber
    }
    always {
      ent:apiKey := newApiKey
      ent:sessionId := newSessionId
      ent:phoneNumber := newPhoneNumber
    }
  }

}
