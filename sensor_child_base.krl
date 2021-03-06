ruleset com.tcashcroft.sensor_child_base {
  meta {
    name "Sensor Child Base"
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias subscription
    use module com.tcashcroft.temperature_store alias temp_store
    shares managers
  }

  global {
    manager_name = function(id) {
       "Manager " + id
    }
    
    raise_event = function(eci, attrs, host){
      event:send({
        "eci": eci,
        "eid": "threshold_violation",
        "domain": "wovyn",
        "type": "threshold_violation",
        "attrs": attrs
      }, host)
    }

    managers = function(){
      ent:managers
    }
  }

  rule init {
    select when wrangler ruleset_installed where event:attrs{"rids"} >< meta:rid
    always {
      ent:managers := {}
      ent:counter := 1
    }
  }

  rule delete {
    select when wrangler child_deletion_request
    always {
      raise wrangler event "ready_for_deletion"
    }
  }

  rule subscribe_to_parent_manager {
    select when wrangler ruleset_installed
      where event:attrs{"rids"} >< meta:rid
    pre {
      parent_eci = wrangler:parent_eci()
      wellKnown_eci = wrangler:picoQuery(parent_eci, "com.tcashcroft.manage_sensors", "get_wellKnown_eci", {})
      is_not_null = not wellKnown_eci.isnull().klog("is not null value: ")
      sensor_name = event:attrs{"name"}
    }
    if is_not_null then noop()
    fired {
      subscription_attrs = {
        "wellKnown_Tx": wellKnown_eci,
        "Rx_role": "sensor",
        "Tx_role": "manager",
        "sensor_name": sensor_name,
        "channel_type": "subscription",
        "name": sensor_name + "-subscription",
        "Tx_host": "http://localhost:3000"
      }
      raise sensor_base event "subscribe" attributes {"subscription_attrs": subscription_attrs}
    }
  }

  rule subscribe_to_manager {
    select when sensor_base subscribe
    pre {
      subscription_attrs = event:attrs{"subscription_attrs"}
    }
    always {
      raise wrangler event "subscription" attributes subscription_attrs
    }
  }

  rule store_subscription {
    select when wrangler subscription_added
    always {
      manager_name = manager_name(ent:counter)
      ent:counter := ent:counter + 1
      ent:managers{event:attrs{"Id"}} := {
        "subscriptionId": event:attrs{"Id"},
        "subscriptionTx": event:attrs{"Tx"},
        "txHost": event:attrs{"bus"}.get("Tx_host"),
        "managerName": manager_name
      }
    }
  }

  rule send_threshold_violation_to_all_managers {
    select when wovyn threshold_violation
    pre {
      violation = event:attrs
    }
    always {
      manager_names = ent:managers.keys()
      raise sensor_child_base event "threshold_violation" attributes {"violation": violation, "manager_names": manager_names}
    }
  }

  rule send_threshold_violation_to_manager {
    select when sensor_child_base threshold_violation
    pre {
      managers = event:attrs{"manager_names"}
      managers_len = managers.length().klog("Managers Length: ")

      manager_name = managers.head().klog("Manager Name: ")
      remaining_managers = managers.slice(1, managers.length() - 1)
      manager_exists = (ent:managers >< manager_name).klog("Manager Exists: ")
      violation = event:attrs{"violation"}
    }
    if managers_len > 0 && manager_exists then event:send({
      "eci": ent:managers{manager_name}.get("subscriptionTx"),
      "eid": "threshold_violation",
      "domain": "wovyn",
      "type": "threshold_violation", 
      "attrs": violation
    }, ent:managers{manager_name}.get("txHost")) 
    fired {
      raise sensor_child_base event "threshold_violation" attributes {"violation": violation, "manager_names": remaining_managers}
    } else {
      raise sensor_child_base event "send_threshold_violation_to_manager_not_sent" attributes event:attrs
    }
  }

  rule scatter_gather_sensor_response {
    select when sensor_base gather_request
      correlation_identifier re#(.+)#
    pre {
      correlation_identifier = event:attrs{"correlation_identifier"}
      temperature = temp_store:current_temperature()
      subscription_id = event:attrs{"subscriptionId"}
      event_type = event:attrs{"event_name"}
      event_domain = event:attrs{"event_domain"}
    }
    event:send({
      "eci": ent:managers{subscription_id}.get("subscriptionTx"),
      "eid": "gather_response",
      "domain": event_domain,
      "type": event_type,
      "attrs": {
        "correlation_identifier": correlation_identifier,
        "temperature": temperature,
        "subscription_id": subscription_id
      }
  }, ent:managers{subscription_id}.get("txHost"))
    fired {
      raise sensor_base event "report_sent" attributes event:attrs
    }
  }
}