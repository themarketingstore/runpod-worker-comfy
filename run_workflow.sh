#!/bin/bash

# Check if the workflow file argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <workflow_file>"
    exit 1
fi

WORKFLOW_FILE=$1

# Check if the workflow file exists
if [ ! -f "$WORKFLOW_FILE" ]; then
    echo "Error: Workflow file '$WORKFLOW_FILE' not found."
    exit 1
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "Error: .env file not found."
    exit 1
fi

# Source the .env file
source .env

# Check if required variables are set
if [ -z "$ACCOUNT_ID" ] || [ -z "$API_KEY" ]; then
    echo "Error: ACCOUNT_ID and API_KEY must be set in the .env file."
    exit 1
fi

# Create the output directory if it doesn't exist
mkdir -p output

BASENAME=$(basename "$WORKFLOW_FILE" .json)
OUTPUT_FILENAME="output/${BASENAME}.png"

counter=1
while [ -f "$OUTPUT_FILENAME" ]; do
    OUTPUT_FILENAME="output/${BASENAME}_${counter}.png"
    ((counter++))
done

# Read the workflow file content
WORKFLOW_CONTENT=$(cat "$WORKFLOW_FILE")

# Construct the JSON payload
JSON_PAYLOAD=$(cat <<EOF
{
  "input": {
    "workflow": $WORKFLOW_CONTENT
  }
}
EOF
)

# Construct the URL
URL="https://api.runpod.ai/v2/${ACCOUNT_ID}/runsync"

# Send the curl request
RESPONSE=$(curl -X POST "$URL" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer ${API_KEY}" \
     -d "$JSON_PAYLOAD")

# Extract the outer status
OUTER_STATUS=$(echo "$RESPONSE" | jq -r '.status')

# Check if the outer status is COMPLETED
if [ "$OUTER_STATUS" != "COMPLETED" ]; then
    echo "Error: Outer status is not COMPLETED. Status: $OUTER_STATUS"
    echo "Response: $RESPONSE"
    exit 1
fi

# Extract the inner status
INNER_STATUS=$(echo "$RESPONSE" | jq -r '.output.status')

# Check if the inner status is success
if [ "$INNER_STATUS" != "success" ]; then
    echo "Error: Inner status is not success. Status: $INNER_STATUS"
    echo "Response: $RESPONSE"
    exit 1
fi

# Extract the base64 encoded image from the response
BASE64_IMAGE=$(echo "$RESPONSE" | jq -r '.output.message')

# Check if the extraction was successful
if [ "$BASE64_IMAGE" == "null" ] || [ -z "$BASE64_IMAGE" ]; then
    echo "Error: Failed to extract base64 encoded image from the response."
    echo "Response: $RESPONSE"
    exit 1
fi

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")


# Decode the base64 image and save it to a file
echo "$BASE64_IMAGE" | base64 --decode > "$OUTPUT_FILENAME"

echo "Image successfully saved as $OUTPUT_FILENAME"