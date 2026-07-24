# terraform/modules/connectivity_test/main.tf
#
# The ECS Fargate connectivity-test tooling from architecture.md §6: one ECR
# repository holding a single minimal image, one ECS cluster, one task
# definition with two modes selected at RunTask time via a command override
# ("listen" — a bounded-duration port-80 listener; "check <ip>" — a one-shot TCP
# connect attempt). Tasks are invoked on demand by scripts/run-connectivity-check.sh,
# never left running continuously.
#
# No task role is declared — the container makes no AWS API calls of its own, so
# only the execution role (image pull + log shipping) exists.

resource "aws_ecr_repository" "connectivity_test" {
  name                 = "dual-home-cloudwan-test-connectivity-test"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "dual-home-cloudwan-test-connectivity-test"
  }
}

resource "aws_ecs_cluster" "this" {
  name = "dual-home-cloudwan-test"

  tags = {
    Name = "dual-home-cloudwan-test"
  }
}

resource "aws_cloudwatch_log_group" "connectivity_test" {
  name              = "/ecs/dual-home-cloudwan-test-connectivity-test"
  retention_in_days = 7

  tags = {
    Name = "dual-home-cloudwan-test-connectivity-test"
  }
}

data "aws_iam_policy_document" "task_execution_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task_execution" {
  name               = "dual-home-cloudwan-test-task-execution"
  assume_role_policy = data.aws_iam_policy_document.task_execution_assume.json

  tags = {
    Name = "dual-home-cloudwan-test-task-execution"
  }
}

data "aws_iam_policy_document" "task_execution" {
  statement {
    sid       = "ECRAuth"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"] # GetAuthorizationToken has no resource-level permissions; AWS-mandated wildcard, not a scoping choice.
  }

  statement {
    sid = "ECRPull"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = [aws_ecr_repository.connectivity_test.arn]
  }

  statement {
    sid = "Logs"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["${aws_cloudwatch_log_group.connectivity_test.arn}:*"]
  }
}

resource "aws_iam_role_policy" "task_execution" {
  name   = "dual-home-cloudwan-test-task-execution"
  role   = aws_iam_role.task_execution.id
  policy = data.aws_iam_policy_document.task_execution.json
}

resource "aws_ecs_task_definition" "connectivity_test" {
  family                   = "dual-home-cloudwan-test-connectivity-test"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "connectivity-test"
      image     = "${aws_ecr_repository.connectivity_test.repository_url}:latest"
      essential = true
      command   = ["listen"]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.connectivity_test.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "connectivity-test"
        }
      }
    }
  ])

  tags = {
    Name = "dual-home-cloudwan-test-connectivity-test"
  }
}
