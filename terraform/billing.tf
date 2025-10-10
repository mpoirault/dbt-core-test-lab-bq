data "google_billing_account" "xebia-nl" {
  billing_account = var.billing_account_id
}

resource "google_monitoring_notification_channel" "max_poirault_email" {
  display_name = "Max Poirault Email"
  type         = "email"

  labels = {
    email_address = "m.poirault@xebia.com"
  }
}

resource "google_billing_budget" "monthly_budget" {
  billing_account = data.google_billing_account.xebia-nl.id
  display_name    = "max_sandbox_50_euro"

  budget_filter {
    projects = ["projects/${var.project_id}"]
  }

  amount {
    specified_amount {
      currency_code = "EUR"
      units         = "50"
    }
  }

  threshold_rules {
    threshold_percent = 1.0
    spend_basis       = "CURRENT_SPEND"
  }

  all_updates_rule {
    monitoring_notification_channels = [
      google_monitoring_notification_channel.max_poirault_email.id,
    ]
    disable_default_iam_recipients = true
  }
}
