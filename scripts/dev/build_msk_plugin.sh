#!/bin/bash
set -e

# Define directories
# base dir should be the root of the project where the build directory is located
BASE_DIR="$(dirname "$(dirname "$(realpath "$0")")")"
BUILD_DIR="${BASE_DIR}/build"
TEMP_DIR="${BUILD_DIR}/plugin_tmp"
PLUGIN_FILE="sqs-source-plugin.zip"

echo "🧹 Cleaning up old build directory..."
rm -rf "${TEMP_DIR}"
mkdir -p "${TEMP_DIR}"

echo "⬇️ Downloading Apache Camel AWS2 SQS Connector..."
cd "${TEMP_DIR}"
curl -sL -O https://repo1.maven.org/maven2/org/apache/camel/kafkaconnector/camel-aws2-sqs-kafka-connector/0.11.5/camel-aws2-sqs-kafka-connector-0.11.5-package.tar.gz

echo "📦 Extracting connector..."
tar -xzf camel-aws2-sqs-kafka-connector-0.11.5-package.tar.gz

echo "🗜️ Zipping for MSK Connect..."
# MSK Connect requires a single root directory in the zip containing all the jars
# The extracted folder is already named 'camel-aws2-sqs-kafka-connector'
# We use 'jar' because 'zip' might not be installed
jar cMf "${BUILD_DIR}/${PLUGIN_FILE}" -C . camel-aws2-sqs-kafka-connector/

echo "🧹 Cleaning up temporary build files..."
rm -rf "${TEMP_DIR}"

echo "✅ Plugin built successfully at: ${BUILD_DIR}/${PLUGIN_FILE}"
