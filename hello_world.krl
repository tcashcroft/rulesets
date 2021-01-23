
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

        output = hello (name || "Monkey")
        send_directive("echo", {"value": output})
    }

    rule hello_monkey2 {
       select when echo monkey2

       if name.isnull() => send_directive("echo", {"value": "Hello Monkey2"}) | send_directive("echo", {"value": hello name})
    }
}
