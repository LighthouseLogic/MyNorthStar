#!/bin/bash
# Fails the build if a real Anthropic/Claude API key appears to be hardcoded
# anywhere in source. The app is bring-your-own-key: a key must only ever be
# typed into Settings by the person running the app and stored in Keychain.
# It must never live in source, plists, or xcconfig files that ship in the repo.
set -u

SEARCH_ROOT="${SRCROOT:-.}/MyNorthStar"
FOUND=0

echo "note: scanning ${SEARCH_ROOT} for hardcoded API keys..."

# 1) An actual Anthropic key prefix is an unambiguous secret.
if grep -rnE "sk-ant-[A-Za-z0-9_-]{10,}" "$SEARCH_ROOT" \
    --include="*.swift" --include="*.plist" --include="*.xcconfig" --include="*.json"
then
  FOUND=1
fi

# 2) A literal string assigned to anything that looks like an api-key variable.
if grep -rnEi '(api[_]?key|anthropic[_]?key)[[:space:]]*[:=][[:space:]]*"[A-Za-z0-9_-]{15,}"' \
    "$SEARCH_ROOT" --include="*.swift"
then
  FOUND=1
fi

if [ "$FOUND" -ne 0 ]; then
  echo "error: Found what looks like a hardcoded Claude/Anthropic API key in source."
  echo "error: Remove it. Keys must only be entered by the user into Settings/Keychain at runtime -- never committed."
  exit 1
fi

echo "note: no hardcoded API keys found."
exit 0
