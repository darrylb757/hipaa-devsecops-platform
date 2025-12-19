variable "cluster_name" {
  type = string
}

variable "env" {
  type = string
}

variable "kms_key_arn" {
  type        = string
  description = "KMS key ARN for encrypting CloudWatch Log Group and SNS topic"
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "enable_email_alerts" {
  type    = bool
  default = false
}

variable "alert_email" {
  type        = string
  default     = ""
  description = "Email endpoint for SNS subscription (only used if enable_email_alerts=true)"
}

variable "enable_containerinsights_alarms" {
  type    = bool
  default = false
}

variable "alarm_cpu_threshold" {
  type    = number
  default = 80
}

variable "alarm_mem_threshold" {
  type    = number
  default = 80
}

variable "alarm_evaluation_periods" {
  type    = number
  default = 2
}

variable "alarm_period_seconds" {
  type    = number
  default = 300
}

variable "tags" {
  type    = map(string)
  default = {}
}
