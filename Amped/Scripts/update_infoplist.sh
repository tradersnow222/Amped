#!/bin/bash

# Script to update Info.plist with required values
# This script is intended to be run as a Build Phase script in Xcode

# Exit on any error
set -e

# Get the path to the generated Info.plist
INFO_PLIST_PATH="${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}"

echo "Updating Info.plist at: $INFO_PLIST_PATH"

# Add HealthKit usage descriptions if not already present
if [ -f "$INFO_PLIST_PATH" ]; then
    # Check if NSHealthShareUsageDescription is already set
    if ! /usr/libexec/PlistBuddy -c "Print :NSHealthShareUsageDescription" "$INFO_PLIST_PATH" &>/dev/null; then
        echo "Adding NSHealthShareUsageDescription"
        /usr/libexec/PlistBuddy -c "Add :NSHealthShareUsageDescription string 'Amped needs access to your health data to calculate personalized life impact metrics.'" "$INFO_PLIST_PATH"
    fi
    
    # Check if NSHealthUpdateUsageDescription is already set
    if ! /usr/libexec/PlistBuddy -c "Print :NSHealthUpdateUsageDescription" "$INFO_PLIST_PATH" &>/dev/null; then
        echo "Adding NSHealthUpdateUsageDescription"
        /usr/libexec/PlistBuddy -c "Add :NSHealthUpdateUsageDescription string 'Amped needs permission to access your health data to provide accurate lifespan projections.'" "$INFO_PLIST_PATH"
    fi
    
    echo "Info.plist updated successfully"
else
    echo "Error: Info.plist not found at $INFO_PLIST_PATH"
    exit 1
fi 