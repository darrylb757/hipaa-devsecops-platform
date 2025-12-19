# These alarms assume Container Insights metrics are present under the "ContainerInsights" namespace.
# If metric names/dimensions differ, can adjust after confirmed available metrics.

resource "aws_cloudwatch_metric_alarm" "node_cpu_high" {
  count               = var.enable_containerinsights_alarms ? 1 : 0
  alarm_name          = "${var.env}-${var.cluster_name}-node-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  period              = var.alarm_period_seconds
  threshold           = var.alarm_cpu_threshold
  statistic           = "Average"
  treat_missing_data  = "missing"

  namespace   = "ContainerInsights"
  metric_name = "node_cpu_utilization"

  dimensions = {
    ClusterName = var.cluster_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = merge(var.tags, { Env = var.env })
}

resource "aws_cloudwatch_metric_alarm" "node_mem_high" {
  count               = var.enable_containerinsights_alarms ? 1 : 0
  alarm_name          = "${var.env}-${var.cluster_name}-node-mem-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  period              = var.alarm_period_seconds
  threshold           = var.alarm_mem_threshold
  statistic           = "Average"
  treat_missing_data  = "missing"

  namespace   = "ContainerInsights"
  metric_name = "node_memory_utilization"

  dimensions = {
    ClusterName = var.cluster_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = merge(var.tags, { Env = var.env })
}

resource "aws_cloudwatch_metric_alarm" "eks_node_cpu_high" {
  alarm_name          = "${var.env}-${var.cluster_name}-node-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  period              = 300
  threshold           = 80
  statistic           = "Average"
  treat_missing_data  = "missing"

  namespace   = "ContainerInsights"
  metric_name = "node_cpu_utilization"

  dimensions = {
    ClusterName = var.cluster_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = merge(var.tags, {
    Severity = "warning"
    Env      = var.env
  })
}

resource "aws_cloudwatch_metric_alarm" "eks_node_memory_high" {
  alarm_name          = "${var.env}-${var.cluster_name}-node-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  period              = 300
  threshold           = 80
  statistic           = "Average"
  treat_missing_data  = "missing"

  namespace   = "ContainerInsights"
  metric_name = "node_memory_utilization"

  dimensions = {
    ClusterName = var.cluster_name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = merge(var.tags, {
    Severity = "warning"
    Env      = var.env
  })
}
