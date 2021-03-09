ruleset com.tcashcroft.child_base {
  meta {
    name "Child Base"
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
}