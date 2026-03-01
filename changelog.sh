#!/bin/bash

VERSION="6.4.61"

DATA=$(gh release view "v$VERSION" --json name,url,body --repo praat/praat.github.io 2>/dev/null)

# Name has format "version 6.4.61, February 28, 2026"
# Extracts everything after the first comma: "February 28, 2026"
RAW_DATE=$(echo "$DATA" | jq -r '.name' | sed 's/^[^,]*, //')
# Convert to YYYY-MM-DD
FORMATTED_DATE=$(date -d "$RAW_DATE" "+%Y-%m-%d")

echo "$DATA" | jq -r --arg ver "$VERSION" --arg date "$FORMATTED_DATE" '
    # Function to strip Markdown links [Text](URL) -> Text
    # AppStream doesn`t support links, so we just keep the text part.
    def strip_links: gsub("\\[(?<txt>[^\\]]+)\\]\\([^\\)]+\\)"; "\(.txt)");

    # Clean the body: remove \r, escape XML characters, and wrap lines in <li>
    def clean_body: .body 
        | gsub("\r"; "") 
        | gsub("&"; "&amp;") 
        | gsub("<"; "&lt;") 
        | gsub(">"; "&gt;")
        | strip_links
        | split("\n") 
        | map(select(length > 0) | "          <li>" + sub("^ *[-*•] "; "") + "</li>") 
        | join("\n");

    "    <release version=\"" + $ver + "\" date=\"" + $date + "\">
      <url type=\"details\">" + .url + "</url>
      <description>
        <ul>
" + clean_body + "
        </ul>
      </description>
    </release>"
'
