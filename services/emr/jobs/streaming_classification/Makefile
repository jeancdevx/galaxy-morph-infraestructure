ROOT_DIR   := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
BUILD_DIR  := $(ROOT_DIR)build
JOB_SRC    := $(ROOT_DIR)src
LIBS_SRC   := $(ROOT_DIR)../../libs/src
SCRIPTS    := $(ROOT_DIR)scripts

# S3 destination — the bucket is created by Terraform (module.s3)
CHECKPOINTS_BUCKET  ?= galaxy-morph-checkpoints
ARTIFACT_S3_PREFIX  ?= emr/jobs/streaming_classification/latest

AWS_PROFILE ?= default
AWS_REGION  ?= us-east-2

.PHONY: build upload clean

## Build deps.zip with job modules + shared libs.
## boto3 and pyspark are provided by the EMR Serverless runtime — do NOT package them.
build:
	python3 $(SCRIPTS)/build_artifact.py $(BUILD_DIR) $(JOB_SRC) $(LIBS_SRC)

## Upload main_streaming.py and deps.zip to the Terraform-managed checkpoints bucket.
upload: build
	aws s3 cp $(JOB_SRC)/main_streaming.py \
	  s3://$(CHECKPOINTS_BUCKET)/$(ARTIFACT_S3_PREFIX)/main_streaming.py \
	  --profile $(AWS_PROFILE) --region $(AWS_REGION)
	aws s3 cp $(BUILD_DIR)/deps.zip \
	  s3://$(CHECKPOINTS_BUCKET)/$(ARTIFACT_S3_PREFIX)/deps.zip \
	  --profile $(AWS_PROFILE) --region $(AWS_REGION)
	@echo "Artifact ready at s3://$(CHECKPOINTS_BUCKET)/$(ARTIFACT_S3_PREFIX)/"

clean:
	rm -rf $(BUILD_DIR)

