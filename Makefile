PROJECT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))

project_name := rabbit-mem-used-monitor

PROJECT := meetup
STAGE ?= qa
COMPONENT ?= $(project_name)

ACCOUNT_ID ?= $(shell aws iam get-user --query 'User.[Arn]' --output text | cut -d: -f5)
REGION ?= $(shell aws configure get region)
SECURITY_GROUP_IDS := \
	$(shell aws cloudformation describe-stacks \
		--stack-name $(PROJECT)-$(STAGE)-sg \
		--query "Stacks[].Outputs[?OutputKey==\`ChapstickSecurityGroups\`].OutputValue" \
		--output text)
SUBNET_IDS := \
	$(shell aws cloudformation describe-stacks  \
		--stack-name $(PROJECT)-$(STAGE)-vpc \
		--query "Stacks[].Outputs[?OutputKey==\`PrivateAppSubnets\`].OutputValue" \
		--output text)
AWS_KMS_KEYID := \
	$(shell aws cloudformation describe-stacks \
		--stack-name $(PROJECT)-$(STAGE)-kms-credstash \
		--query "Stacks[].Outputs[?OutputKey==\`KeyArn\`].OutputValue" \
		--output text)
TOPIC_ARN ?= arn:aws:sns:$(REGION):$(ACCOUNT_ID):$(PROJECT)-$(STAGE)-$(COMPONENT)

export \
	PROJECT \
	STAGE \
	COMPONENT \
	ACCOUNT_ID \
	REGION \
	SECURITY_GROUP_IDS \
	SUBNET_IDS \
	TOPIC_ARN \
	AWS_KMS_KEYID

help:
		@echo Public targets:
		@grep -E '^[^_][^_][a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
		@echo "Private targets: (use at own risk)"
		@grep -E '^__[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[35m%-20s\033[0m %s\n", $$1, $$2}'

__package_modules: ## install python modules to vendored/
	@pip2 install -t vendored/ -r requirements.txt

create_topic: ## create an SNS topic the alarm publishes to
	@aws sns create-topic --name $(PROJECT)-$(STAGE)-$(COMPONENT)

deploy: __package_modules  ## deploy lambda to aws by running: serverless deploy
	@envtpl < serverless.yml.j2 > serverless.yml
	@serverless deploy

undeploy:  ## undeploy by running: serverless remove
	@envtpl < serverless.yml.j2 > serverless.yml
	@serverless remove
