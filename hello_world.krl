
ruleset hello_world {
    meta {
       name "Hello World" 
       description <<
    A first ruleset for the Quickstart >>
    author "Phil Windley"
    shares hello
    }
    global {
        hello = function(obj) {
            msg = "Hello " + obj;
            msg
        }
    }

    rule hello_world {
        select when echo hello
        send_directive("say", {"something": "Hello World"})
    }

    rule hello_monkey {
        select when echo monkey

        pre {
          name = (event:attrs{"name"}.isnull() => "Monkey" | event:attrs{"name"}).klog("Saying hello to: ");
        }
        send_directive("echo", {"body": name.sprintf("Hello %s")})

    }

}
