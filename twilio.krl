ruleset com.tcashcroft.twilio {

  meta {
    name "Twilio"
    logging on
    configure using
      apiKey = ""
      sessionId = "" 
      phoneNumber = ""
    shares sendMessage
  }
  global {
    baseUrl = "https://api.twilio.com"
    sendMessage = defaction(message, recipientNumber) {
      response = http:post(<<#{baseUrl}/2010-04-01/Accounts/#{sessionId}/Messages.json>>, form = {"To": recipientNumber, "From": phoneNumber, "Body": message}, auth = {"username": sessionId, "password": apiKey})
      response.decode()
    }
  }
}
