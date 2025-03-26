#!/bin/bash

# Script to update Info.plist with required values
# This script is intended to be run as a Build Phase script in Xcode

# Exit on any error
set -e

# Get the path to the generated Info.plist
INFO_PLIST_PATH="${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}"

echo "===== Info.plist Update Script ====="
echo "BUILT_PRODUCTS_DIR: ${BUILT_PRODUCTS_DIR}"
echo "INFOPLIST_PATH: ${INFOPLIST_PATH}"
echo "Target Info.plist: ${INFO_PLIST_PATH}"

# Check if source Amped-Info.plist exists
SOURCE_PLIST="${SRCROOT}/Amped/Amped-Info.plist"
if [ -f "$SOURCE_PLIST" ]; then
    echo "Source Amped-Info.plist found at: $SOURCE_PLIST"
else
    echo "Warning: Source Amped-Info.plist not found at: $SOURCE_PLIST"
fi

# Add HealthKit usage descriptions if not already present
if [ -f "$INFO_PLIST_PATH" ]; then
    echo "Found generated Info.plist at: $INFO_PLIST_PATH"
    
    # Check if NSHealthShareUsageDescription is already set
    if /usr/libexec/PlistBuddy -c "Print :NSHealthShareUsageDescription" "$INFO_PLIST_PATH" &>/dev/null; then
        echo "NSHealthShareUsageDescription already exists, updating value"
        /usr/libexec/PlistBuddy -c "Set :NSHealthShareUsageDescription 'Amped uses your health data to calculate personalized life impact metrics. All data is processed on your device and never shared.'" "$INFO_PLIST_PATH"
    else
        echo "Adding NSHealthShareUsageDescription"
        /usr/libexec/PlistBuddy -c "Add :NSHealthShareUsageDescription string 'Amped uses your health data to calculate personalized life impact metrics. All data is processed on your device and never shared.'" "$INFO_PLIST_PATH"
    fi
    
    # Check if NSHealthUpdateUsageDescription is already set
    if /usr/libexec/PlistBuddy -c "Print :NSHealthUpdateUsageDescription" "$INFO_PLIST_PATH" &>/dev/null; then
        echo "NSHealthUpdateUsageDescription already exists, updating value"
        /usr/libexec/PlistBuddy -c "Set :NSHealthUpdateUsageDescription 'Amped does not modify your health data, but requires this permission to access your health information.'" "$INFO_PLIST_PATH"
    else
        echo "Adding NSHealthUpdateUsageDescription"
        /usr/libexec/PlistBuddy -c "Add :NSHealthUpdateUsageDescription string 'Amped does not modify your health data, but requires this permission to access your health information.'" "$INFO_PLIST_PATH"
    fi
    
    # Display the current values in the updated Info.plist
    echo "Current NSHealthShareUsageDescription:"
    /usr/libexec/PlistBuddy -c "Print :NSHealthShareUsageDescription" "$INFO_PLIST_PATH" || echo "Not found after update!"
    
    echo "Current NSHealthUpdateUsageDescription:"
    /usr/libexec/PlistBuddy -c "Print :NSHealthUpdateUsageDescription" "$INFO_PLIST_PATH" || echo "Not found after update!"
    
    # Also set UIBackgroundModes if needed for HealthKit background delivery
    if ! /usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" "$INFO_PLIST_PATH" &>/dev/null; then
        echo "Adding UIBackgroundModes with fetch"
        /usr/libexec/PlistBuddy -c "Add :UIBackgroundModes array" "$INFO_PLIST_PATH"
        /usr/libexec/PlistBuddy -c "Add :UIBackgroundModes:0 string 'fetch'" "$INFO_PLIST_PATH"
    else
        # Check if fetch is already in UIBackgroundModes
        if ! /usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" "$INFO_PLIST_PATH" | grep -q "fetch"; then
            # Count existing items
            COUNT=$(/usr/libexec/PlistBuddy -c "Print :UIBackgroundModes" "$INFO_PLIST_PATH" | grep -c "^    ")
            echo "Adding fetch to UIBackgroundModes at index $COUNT"
            /usr/libexec/PlistBuddy -c "Add :UIBackgroundModes:$COUNT string 'fetch'" "$INFO_PLIST_PATH"
        else
            echo "UIBackgroundModes already includes fetch"
        fi
    fi
    
    echo "Info.plist updated successfully"
else
    echo "Error: Info.plist not found at $INFO_PLIST_PATH"
    
    # List files in BUILT_PRODUCTS_DIR to help debug
    echo "Files in ${BUILT_PRODUCTS_DIR}:"
    ls -la "${BUILT_PRODUCTS_DIR}" || echo "Cannot list files in ${BUILT_PRODUCTS_DIR}"
    
    # Try to find any plist files
    echo "Looking for plist files:"
    find "${BUILT_PRODUCTS_DIR}" -name "*.plist" || echo "No plist files found"
    
    exit 1
fi 