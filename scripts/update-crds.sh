#!/bin/bash
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
  local curl_exit_code
  echo "Downloading $download_url..."
  while [ $retries -lt $MAX_RETRIES ]; do
    tmp_content=$(curl -sL --fail "$download_url")
    curl_exit_code=$?

    if [ $curl_exit_code -eq 0 ] && [ ! -z "$tmp_content" ]; then
      break # Success
    fi

    retries=$((retries + 1))
    if [ $retries -lt $MAX_RETRIES ]; then
      echo "WARN: Fail to download (Code: $curl_exit_code). Wait $DELAY_SECONDS seconds before retry..."
      sleep $DELAY_SECONDS
    fi
  done

  if [ $retries -eq $MAX_RETRIES ]; then
    if [ $curl_exit_code -ne 0 ] || [ -z "$tmp_content" ]; then
      echo "ERROR: Could not download file after $MAX_RETRIES attempts (Last Code: $curl_exit_code)."
      return 1
    fi
  fi

  # Update file
  echo "$header_lines" > "$file"
  echo "$tmp_content" >> "$file"

  echo "The file $file as been updated."
  return 0
}

# ---

if [ "$#" -eq 0 ]; then
  echo "No files specified."
  exit 0
fi

GLOBAL_ERROR=0
for FILE in "$@"; do
  if ! update_file "$FILE"; then
    GLOBAL_ERROR=1
  fi
done

# shellcheck disable=SC2086
if [ $GLOBAL_ERROR -ne 0 ]; then
    echo "--- The process threw an error on at least one file. Exiting with status 1. ---"
    exit 1
else
    echo "--- All files have been updated or ignored. Exiting with status 0. ---"
    exit 0
fi
