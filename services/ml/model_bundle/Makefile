AWS_PROFILE ?= default

BUCKET  := galaxy-morph-models
S3_KEY  := sagemaker/galaxy-classifier/efficientnet_b3/v1/model.tar.gz
S3_URI  := s3://$(BUCKET)/$(S3_KEY)

.PHONY: check bundle upload clean

# Verify the model checkpoint is present before packaging
check:
	@test -f best.pth || { \
		echo ""; \
		echo "  ERROR: best.pth not found."; \
		echo "  Copy your trained model checkpoint to this directory:"; \
		echo "    cp /path/to/best.pth services/ml/model_bundle/best.pth"; \
		echo ""; \
		exit 1; \
	}

# Package model weights + serving code into model.tar.gz
# Structure expected by the PyTorch AWS DLC:
#   model.tar.gz
#   ├── best.pth
#   └── code/
#       ├── inference.py
#       └── requirements.txt
bundle: check
	tar -czf model.tar.gz best.pth code/
	@echo "Bundle created: model.tar.gz"

# Upload bundle to S3 (runs bundle first)
upload: bundle
	aws s3 cp model.tar.gz $(S3_URI) --profile $(AWS_PROFILE)
	@echo "Uploaded: $(S3_URI)"

# Remove local bundle artifact
clean:
	rm -f model.tar.gz
