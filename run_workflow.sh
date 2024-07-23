#!/bin/bash

# Initialize an empty array to store image data
declare -a IMAGE_DATA

# Function to process image arguments
process_image_arg() {
    local arg=$1
    local img_var=${arg%%:*}
    local img_file=${arg#*:}
    
    if [ ! -f "$img_file" ]; then
        echo "Error: Image file '$img_file' not found."
        exit 1
    fi
    
    local base64_image=$(base64 -i "$img_file")
    IMAGE_DATA+=("{\"name\":\"$img_var\",\"image\":\"$base64_image\"}")
}

# Parse command line arguments

while getopts "i:" opt; do
    case $opt in
        i)
            process_image_arg "$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# Get the workflow file (last argument)
WORKFLOW_FILE="${@: -1}"

# Check if the workflow file argument is provided
if [ -z "$WORKFLOW_FILE" ]; then
    echo "Usage: $0 [-i img_var:img_file ...] <workflow_file>"
    exit 1
fi

# Check if the workflow file exists
if [ ! -f "$WORKFLOW_FILE" ]; then
    echo "Error: Workflow file '$WORKFLOW_FILE' not found."
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

# Extract the base filename from WORKFLOW_FILE without the extension
BASENAME=$(basename "$WORKFLOW_FILE" .json)

# Initialize the output filename
OUTPUT_FILENAME="output/${BASENAME}.png"

# Check if the file already exists and increment if necessary
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
    "workflow": $WORKFLOW_CONTENT,
    "images": [
      $(IFS=,; echo "${IMAGE_DATA[*]}")
    ]
  }
}
EOF
)

echo "JSON Payload size: $(echo "$JSON_PAYLOAD" | wc -c) bytes"

# Construct the URL
URL="https://api.runpod.ai/v2/${ACCOUNT_ID}/runsync"

# Write the JSON payload to a temporary file
TEMP_JSON=$(mktemp)
echo "$JSON_PAYLOAD" > "$TEMP_JSON"

# Send the curl request using the temporary file
RESPONSE=$(curl -X POST "$URL" \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer ${API_KEY}" \
     -d @"$TEMP_JSON")

# Remove the temporary file
rm "$TEMP_JSON"

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

# Decode the base64 image and save it to a file


echo "Image successfully saved as $OUTPUT_FILENAME"
