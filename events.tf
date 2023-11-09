resource "aws_cloudwatch_event_rule" "this" {
  event_bus_name = "default"
  name           = "TerminateInstanceRule"

  description = "Calls AWS Lambda that will be responsible to remove an instance for the domain when an EC2 instance is terminated."

  event_pattern = templatefile("./templates/event-rule-instance-termination.json.j2",{})

}

resource "aws_cloudwatch_event_target" "this" {
  event_bus_name = "default"
  rule           = aws_cloudwatch_event_rule.this.name
  target_id      = "eventlambda"
  arn            = aws_lambda_function.lambda.arn
  #role_arn       = aws_iam_role.events_to_sm.arn

  #dead_letter_config {
  #  arn = aws_sqs_queue.arn
  #}

  retry_policy {
    maximum_retry_attempts       = 6
    maximum_event_age_in_seconds = 180
  }
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_rw_fallout_retry_step_deletion_lambda" {
  statement_id = "AllowExecutionFromCloudWatch"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal = "events.amazonaws.com"
  source_arn = aws_cloudwatch_event_rule.this.arn
}