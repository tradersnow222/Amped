#!/bin/bash

# Script to copy Amped-Info.plist contents into the generated Info.plist
# This is a more direct approach to ensure all required keys are present

# Exit on any error
set -e

# Get the path to the generated Info.plist
INFO_PLIST_PATH="${BUILT_PRODUCTS_DIR}/${INFOPLIST_PATH}"
SOURCE_PLIST="${SRCROOT}/Amped/Amped-Info.plist"

echo "===== Info.plist Copy Script ====="
echo "BUILT_PRODUCTS_DIR: ${BUILT_PRODUCTS_DIR}"
echo "INFOPLIST_PATH: ${INFOPLIST_PATH}"
echo "Target Info.plist: ${INFO_PLIST_PATH}"
echo "Source Info.plist: ${SOURCE_PLIST}"

# Check if source Amped-Info.plist exists
if [ ! -f "$SOURCE_PLIST" ]; then
    echo "Error: Source Amped-Info.plist not found at: $SOURCE_PLIST"
    exit 1
fi

# Check if generated Info.plist exists
if [ ! -f "$INFO_PLIST_PATH" ]; then
    echo "Error: Generated Info.plist not found at: $INFO_PLIST_PATH"
    
    # List files in BUILT_PRODUCTS_DIR to help debug
    echo "Files in ${BUILT_PRODUCTS_DIR}:"
    ls -la "${BUILT_PRODUCTS_DIR}" || echo "Cannot list files in ${BUILT_PRODUCTS_DIR}"
    
    # Try to find any plist files
    echo "Looking for plist files:"
    find "${BUILT_PRODUCTS_DIR}" -name "*.plist" || echo "No plist files found"
    
    exit 1
fi

echo "Found source Amped-Info.plist and target Info.plist"

# Create a backup of the generated Info.plist
cp "$INFO_PLIST_PATH" "${INFO_PLIST_PATH}.bak"
echo "Created backup at ${INFO_PLIST_PATH}.bak"

# Get all keys from Amped-Info.plist
KEYS=$(/usr/libexec/PlistBuddy -c "Print" "$SOURCE_PLIST" | grep "^    " | sed 's/^    \([^ ]*\) =.*/\1/')

# Copy each key from source to destination
for KEY in $KEYS; do
    echo "Processing key: $KEY"
    
    # Check if the key already exists in the destination
    if /usr/libexec/PlistBuddy -c "Print :$KEY" "$INFO_PLIST_PATH" &>/dev/null; then
        echo "Key $KEY already exists in destination, removing it first"
        /usr/libexec/PlistBuddy -c "Delete :$KEY" "$INFO_PLIST_PATH"
    fi
    
    # Get the type of the key from the source
    TYPE=$(/usr/libexec/PlistBuddy -c "Print :$KEY" "$SOURCE_PLIST" | head -1 | sed 's/^.*= \(.*\)$/\1/')
    echo "Key type: $TYPE"
    
    if [[ "$TYPE" == "Array" ]]; then
        echo "Adding array key: $KEY"
        /usr/libexec/PlistBuddy -c "Add :$KEY array" "$INFO_PLIST_PATH"
        
        # Get the array items
        ITEMS=$(/usr/libexec/PlistBuddy -c "Print :$KEY" "$SOURCE_PLIST" | grep -v "^Array" | grep -v "^$" | sed 's/^    \([0-9]*\) = \(.*\)$/\1|\2/')
        
        # Add each item to the array
        for ITEM in $ITEMS; do
            INDEX=$(echo "$ITEM" | cut -d'|' -f1)
            VALUE=$(echo "$ITEM" | cut -d'|' -f2)
            echo "Adding array item $INDEX: $VALUE"
            /usr/libexec/PlistBuddy -c "Add :$KEY:$INDEX string '$VALUE'" "$INFO_PLIST_PATH"
        done
    elif [[ "$TYPE" == "Dictionary" ]]; then
        echo "Adding dictionary key: $KEY"
        /usr/libexec/PlistBuddy -c "Add :$KEY dict" "$INFO_PLIST_PATH"
        
        # This is a simple implementation - more complex dictionaries would need recursion
        SUB_KEYS=$(/usr/libexec/PlistBuddy -c "Print :$KEY" "$SOURCE_PLIST" | grep "^        " | sed 's/^        \([^ ]*\) =.*/\1/')
        
        for SUB_KEY in $SUB_KEYS; do
            SUB_VALUE=$(/usr/libexec/PlistBuddy -c "Print :$KEY:$SUB_KEY" "$SOURCE_PLIST")
            echo "Adding dictionary item $SUB_KEY: $SUB_VALUE"
            /usr/libexec/PlistBuddy -c "Add :$KEY:$SUB_KEY string '$SUB_VALUE'" "$INFO_PLIST_PATH"
        done
    else
        # Get the value as a string
        VALUE=$(/usr/libexec/PlistBuddy -c "Print :$KEY" "$SOURCE_PLIST")
        echo "Adding string key: $KEY with value: $VALUE"
        /usr/libexec/PlistBuddy -c "Add :$KEY string '$VALUE'" "$INFO_PLIST_PATH"
    fi
done

echo "All keys copied from source to destination"

# Verify keys were copied correctly
echo "Verifying copied keys:"
for KEY in $KEYS; do
    echo -n "Key $KEY: "
    /usr/libexec/PlistBuddy -c "Print :$KEY" "$INFO_PLIST_PATH" || echo "NOT FOUND!"
done

echo "Info.plist update completed successfully" 