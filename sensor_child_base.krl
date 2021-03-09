ruleset com.tcashcroft.sensor_child_base {
  meta {
    name "Sensor Child Base"
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias subscription
  }

  global {

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
      // raise sensor_base event "subscribed_to_manager" attributes event:attrs
    }
  }
}