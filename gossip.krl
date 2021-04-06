
ruleset com.tcashcroft.gossip {
    meta {
        name "Gossip Protocol"
        use module io.picolabs.wrangler alias wrangler
        use module io.picolabs.subscription alias subscription
        use module com.tcashcroft.temperature_store alias temperature_store
        shares current_schedule, current_schedule_id, current_temperature, get_wellKnown_eci, get_known_nodes, get_name, get_all_messages, get_seen_messages, who_knows_what, get_temperature_report
    }

    global {
        current_schedule = function() {
            ent:current_gossip_schedule
        }

        current_schedule_id = function() {
            ent:current_schedule_id
        }

        get_wellKnown_eci = function() {
            subscription:wellKnown_Rx(){"id"}
        }

        get_known_nodes = function() {
            ent:known_nodes
        }

        get_name = function() {
            ent:name
        }
         
        get_all_messages = function() {
            ent:all_messages
        }

        get_seen_messages = function() {
            ent:seen_messages
        }

        current_temperature = function(){
            temperature_store:current_temperature()
        }

        who_knows_what = function() {
            ent:who_knows_what
        }

        get_node = function(messageId) {
            messageId.split(re#:#)[0]
        }

        get_sequence = function(messageId) {
            messageId.split(re#:#)[1]
        }

        get_temperature_report = function() {
            message_ids = ent:seen_messages.filter(function(v,k){
                v > 0
            }).map(function(v,k){
                k + ":" + v
            }).values()
            ent:all_messages.filter(function(message) {
                message_ids >< message{"MessageID"}
            })
        }
    }

    rule init {
        select when wrangler ruleset_installed where event:attrs{"rids"} >< meta:rid
        always {
            ent:name := random:word() + "-" + random:word()
            ent:sequence_number := 0
            ent:known_nodes := {}
            ent:current_gossip_schedule := "0 */2 * * * *"
            ent:all_messages := [] // my state
            ent:seen_messages := {} // state summary
            ent:seen_messages{ent:name} := ent:sequence_number
            ent:who_knows_what := {}
            // ent:all_seen_messages := {} // state of gossip network

            raise gossip event "hearbeat_schedule"
        }
    }

    rule gossip_heartbeat_wrapper {
        select when gossip hearbeat_schedule
        pre {
            schedule = event:attrs{"schedule"} || ent:current_gossip_schedule
            sched_exists = (not ent:current_schedule_id.isnull())
            sched_id = ent:current_schedule_id
        }

        if sched_exists then schedule:remove(sched_id)

        always {
            schedule gossip event "heartbeat" repeat schedule attributes {} setting(id)
            ent:current_schedule_id := id{"id"}
            ent:current_gossip_schedule := schedule
        }
    }

    rule subscribe_to_peer {
        select when gossip subscribe_to_peer
        pre {
            target_eci = event:attrs{"target_eci"}
            target_host = event:attrs{"target_host"}
            is_not_null = not target_eci.isnull()
        }
        if is_not_null then noop()
        fired {
            subscription_attrs = {
                "wellKnown_Tx": target_eci,
                "Rx_role": "gossip_node",
                "Tx_role": "gossip_node",
                "name": ent:name,
                "channel_type": "subscription",
                "Tx_host": target_host,
                "sequenceNumber": ent:sequence_number
            }
            raise wrangler event "subscription" attributes subscription_attrs
        }
    }

    rule store_subscription {
        select when wrangler subscription_added 
        pre {
            incoming_name = event:attrs{"name"}
            is_not_my_name = not (incoming_name == ent:name)
        }
        if is_not_my_name then noop()
        fired {
            ent:known_nodes{event:attrs{"name"}} := {
                "subscriptionId": event:attrs{"Id"},
                "subscriptionTx" : event:attrs{"Tx"},
                "txHost" : event:attrs{"bus"}.get("Tx_host"),
                "name" : event:attrs{"name"},
                "sequenceNumber": event:attrs{"sequenceNumber"}
            }
        }
    }

    rule auto_accept_peer_subscription {
        select when wrangler inbound_pending_subscription_added 
          where event:attrs{"Tx_role"}.match("gossip_node")
          && event:attrs{"Rx_role"}.match("gossip_node")
        pre {
            my_role = event:attrs{"Rx_role"}
            their_role = event:attrs{"Tx_role"}
            their_name = event:attrs{"name"}
            subscription_id = event:attrs{"Id"}
            tx_host = event:attrs{"Tx_host"}
            tx = event:attrs{"Tx"}
            sequence_number = event:attrs{"sequenceNumber"}
        }
        fired {
            raise wrangler event "pending_subscription_approval" attributes {
                "Id": event:attrs{"Id"},
                "name": ent:name,
                "sequenceNumber": ent:sequence_number
            }
            ent:known_nodes{their_name} := {
                "name": their_name,
                "subscriptionTx": tx,
                "subscriptionId": subscription_id,
                "txHost": tx_host,
                "sequenceNumber": sequence_number
            }
        }
    }

    rule choose_target {
        // select when gossip target // todo: probably should be gossip heartbeat if I'm chaining these events together
        select when gossip heartbeat
        pre {
            nodes = ent:known_nodes.keys().sort(function(a,b) {
                random:number(lower = -1, upper = 1)
            }).klog("Random keys")
            nodes_needing_gossip = nodes.map(function(x) {ent:known_nodes{x}}).filter(function(y){
                name = y.get("name").klog("Name to consider:")
                their_seen_messages = (ent:who_knows_what{name} || {}).klog("Their Seen Messages")
                res = (their_seen_messages != ent:seen_messages{name} && ent:seen_messages{name}.length() > 0) || their_seen_messages.length() == 0
                res
                // output = ((their_seen_messages.length() == 0 && ent:seen_messages.length() != 0).klog("sub result") => true | 
                //   (
                //       ent:known_nodes.keys().map(
                //               function(yy) { 
                //                 ent:seen_messages{yy}.get("sequenceNumber") > their_seen_messages{yy}.get("sequenceNumber") 
                                
                //               }).filter(
                //                   function(z) {
                //           z || false
                //       }).length() > 0 // This logic is really foul
                //   ).klog("Foul")
                // )
                // output
            }).map(function(node) {node{"name"}}).klog("Nodes Needing Gossip:")
            needed = (nodes_needing_gossip.length() > 0)
            target = nodes_needing_gossip.head().klog("Target:")
        }
        if needed then noop()
        fired {
            raise gossip event "prepare_message" attributes {"target": target}
        } else {
            raise gossip event "no_gossip_target"
        }
    }

    rule prepare_message {
        select when gossip prepare_message
          target re#(.+)#
        pre {
            target = event:attrs{"target"}
            message_type = random:integer(lower = 1, upper = 10)
            // message_type = 1 // currently only testing seen messages
            // message_type = 8 // now testing rumors
        }
        if message_type > 7 then noop()
        fired {
          // gossip a rumor
          raise gossip event "rumor" attributes {"name": target}
        } else {
          // gossip seen messages
          raise gossip event "seen" attributes {"name": target}
        }
    }


    rule gossip_send_seen_messages {
        select when gossip seen
        pre {
            target_node = event:attrs{"name"}
            is_valid = ent:known_nodes >< target_node
        }
        if is_valid then event:send({
            "eci": ent:known_nodes{target_node}.get("subscriptionTx"),
            "eid": "gossip_seen",
            "domain": "gossip",
            "type": "seen_received",
            "attrs": {
                "name": ent:name,
                "seen": ent:seen_messages
            }
        }, ent:known_nodes{target_node}.get("txHost"))
        fired {
            raise gossip event "seen_sent" attributes {"name": event:attrs{"name"}}
        } else {
            raise gossip event "seen_not_sent" attributes {"name": event:attrs{"name"}} 
        }
    }

    rule gossip_send_rumor {
        select when gossip rumor
        pre {
            target_node = event:attrs{"name"}
            target_state = ent:seen_messages{target_node}
            needed_messages = ent:all_messages.filter(function(message) {
                message_node = message{"MessageID"}.split(re#:#)[0]
                message_sequence = message{"MessageID"}.split(re#:#)[1]
                target_state{message_node}.isnull() => true | (target_state{message_node}.get("sequenceNumber") < message_sequence)
            }).klog("Needed Messages:")
            has_needed_messages = (needed_messages.length() > 0)
        }
        // if has_needed_messages then noop()
        if has_needed_messages then event:send({
            "eci": ent:known_nodes{target_node}.get("subscriptionTx"),
            "eid": "gossip_rumor",
            "domain": "gossip",
            "type": "rumor_received",
            "attrs": {
                "name": ent:name,
                "rumors": needed_messages
            }
        })
        fired {
            raise gossip event "rumors_sent" attributes {}
        } else {
            raise gossip event "no_messages_needed" attributes {"name": target_node}
            // raise gossip event "update_temperature" attributes {}
        }
    }

    rule update_my_temperature {
        select when gossip no_gossip_target
        pre {
            rando = random:number(lower = 0, upper = 10)
        }
        if rando > 9 then noop()
        fired {
            raise gossip event"update_temperature" attributes {}
        }
    }

    rule gossip_update_my_state {
        select when gossip update_temperature
        pre {
            temp = current_temperature().klog("CURRENT_TEMPERATURE")
            temperature = current_temperature().get("temperature").klog("TEMPERATURE")
        }
        noop()
        fired {
            raise gossip_test event "add_message" attributes {"temperature": temperature, "sensorID": ent:name}
        }
    }

    rule gossip_receive_seen_messages {
        select when gossip seen_received
        pre {
            received_from = event:attrs{"name"}
            seen_messages = event:attrs{"seen"}
        }
        noop()
        fired {
            ent:who_knows_what{received_from} := seen_messages
            raise gossip event "TESTING_seen_messages_received" attributes {}
        }
    }

    rule gossip_receive_rumor_message {
        select when gossip rumor_received
        pre {
            received_from = event:attrs{"name"}
            new_messages = event:attrs{"rumors"}
        }
        noop()
        fired {
            ent:all_messages := ent:all_messages.union(new_messages)
            raise gossip event "process_messages" attributes {"messages": new_messages} 
        }
    }

    rule temp_add_message {
        select when gossip_test add_message
        pre {
           temperature = event:attrs{"temperature"} 
           sensor = event:attrs{"sensorID"}
           timestamp = time:now()
           message_id = ent:name + ":" + (ent:sequence_number + 1)
           message = {
               "Temperature": temperature,
               "SensorID": sensor,
               "Timestamp": timestamp,
               "MessageID": message_id
           }
        }
        noop()
        fired {
            ent:sequence_number := ent:sequence_number + 1
            ent:all_messages := ent:all_messages.append(message)
            ent:seen_messages{ent:name} := ent:sequence_number
            raise gossip event "process_messages" attributes {"messages": [message]}    
        }
    }
    
    rule clear_state {
        select when gossip_test clear_state
        noop()
        fired {
            ent:sequence_number := 0
            ent:all_messages := [] // my state
            ent:seen_messages := {} // my state
            ent:who_knows_what := {}
        }
    }

    rule remove_known_state {
        select when gossip_test clear_state_of_neighbor
        pre {
            target = event:attrs{"name"}
        }
        noop()
        fired {
            ent:who_knows_what{target} := {}
        }
    }

    rule process_messages {
        select when gossip process_messages
        pre {
            messages = event:attrs{"messages"}
            message = messages.head()
            length = messages.length()
            remaining_messages = messages.slice(1, length - 1)
            message_node = get_node(message{"MessageID"})
            message_sequence = get_sequence(message{"MessageID"})
            is_greater = ent:seen_messages{message_node} < message_sequence
        }
        if length > 0 then noop()
        fired {
          raise gossip event "update_seen" attributes {"messages": remaining_messages, "node": message_node, "sequence": message_sequence}  
        } else {
            raise gossip event "messages_processed" attributes {}
        }
    }

    rule update_seen {
        select when gossip update_seen
        pre {
            remaining_messages = event:attrs{"messages"}
            node = event:attrs{"node"}
            sequence = event:attrs{"sequence"}
            has_seen_entry = ent:seen_messages >< node
        }
        if has_seen_entry then noop()
        fired {
            ent:seen_messages{node} := sequence
            raise gossip event "process_individual_message" attributes {"messages": remaining_messages, "node": node, "sequence": sequence}
        } else {
            ent:seen_messages{node} := 0
            raise gossip event "process_individual_message" attributes {"messages": remaining_messages, "node": node, "sequence": sequence}
        }
    }

    rule process_message {
        select when gossip process_individual_message
        pre {
            messages = event:attrs{"messages"}
            node = event:attrs{"node"}
            sequence = event:attrs{"sequence"}
            is_next_sequence = ent:seen_messages{node} == sequence - 1
        }
        if is_next_sequence then noop()
        fired {
            ent:seen_messages{node} := sequence
            raise gossip event "process_messages" attributes {"messages": messages}
        } else {
            raise gossip event "process_messages" attributes {"messages": messages}
        }
    
    }

    
    // rule recalculate_seen_messages {
    //     select when gossip recalculate_seen_messages
    //     pre {
    //         new_seen_messages = ent:all_seen_messages.sort(function(message1, message2){
    //             message1{"MessageID"} < message2{"MessageID"} => -1 | message1{"MessageID"} == message2{"MessageID"} => 0 | 1
    //         }).filter(function(message){
    //             node = message{"MessageID"}.split(re#:#)[0]
    //             sequence = message{"MessageID"}.split(re#:#)[1]
    //             ent:seen_messages >< node => (ent:seen_messages{node} < sequence => true | false) | true
    //         })
    //     }
    //     noop()
    //     fired {
    //         ent:temp_state := ent:seen_messages
    //         res = new_seen_messages.map(function(message) {
    //             node = message{"MessageID"}.split(re#:#)[0]
    //             sequence = message{"MessageID"}.split(re#:#)[1]
    //             current_sequence = ent:temp_state{node}
    //             current_sequence + 1 == sequence => ent:temp_state{node} := sequence | ent:temp_state{node} := current_sequence
    //         })
    //         ent:seen_messages := state
    //     }
    // }
}
 