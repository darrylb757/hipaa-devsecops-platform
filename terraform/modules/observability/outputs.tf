output "eks_control_plane_log_group_name" {
  value = aws_cloudwatch_log_group.eks_control_plane.name
}

output "alerts_topic_arn" {
  value = aws_sns_topic.alerts.arn
}
