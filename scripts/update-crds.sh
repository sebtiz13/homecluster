#!/bin/bash
set -euo pipefail

MAX_RETRIES=5
DELAY_SECONDS=3
SOURCE_URL_PREFIX="# sourceUrl="

update_file() {
  local file="$1"
  echo "--- Process file: $file ---"

  # Extract header and source url
  local header_lines
  local url_line
  header_lines=$(sed -n '1,/^---$/p' "$file")
  if [ -z "$header_lines" ]; then
    echo "WARN: Invalid header (missing '---'). Ignore."
    return 0
  fi
  url_line=$(echo "$header_lines" | grep "^$SOURCE_URL_PREFIX")
  if [ -z "$url_line" ]; then
    echo "WARN: The header doesn't contain \"$SOURCE_URL_PREFIX\". Ignore."
    return 0
  fi

  # Download file
  local download_url=${url_line#"$SOURCE_URL_PREFIX"}
  local retries=0
  local tmp_content=""
  local curl_exit_code=0
  echo "Downloading $download_url..."
  until tmp_content=$(curl -sL --fail "$download_url") && [ -n "$tmp_content" ]; do
    curl_exit_code=$?
    retries=$((retries + 1))

    if [ "$retries" -ge "$MAX_RETRIES" ]; then
      echo "ERROR: Could not download file after $MAX_RETRIES attempts (Last Code: $curl_exit_code)."
      return 1
    fi

    echo "WARN: Retry $retries/$MAX_RETRIES in ${DELAY_SECONDS}s..."
    sleep "$DELAY_SECONDS"
  done

  # Update file
  printf '%s\n%s\n' "$header_lines" "$tmp_content" > "$file"

  echo "The file $file has been updated."
  return 0
}

# ---

if [ "$#" -eq 0 ]; then
  echo "No files specified."
  exit 0
fi

GLOBAL_ERROR=0
for FILE in "$@"; do
  update_file "$FILE" || GLOBAL_ERROR=1
done

if [ $GLOBAL_ERROR -ne 0 ]; then
  echo "--- The process threw an error on at least one file. Exiting with status 1. ---"
  exit 1
else
  echo "--- All files have been updated or ignored. Exiting with status 0. ---"
fi
