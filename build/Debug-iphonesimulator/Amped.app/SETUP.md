# Setup Instructions

## Adding Info.plist Script to Build Phases

To ensure that the required HealthKit permission entries are added to your Info.plist, you need to add the `update_infoplist.sh` script to your Xcode build phases:

1. Open the Amped.xcodeproj in Xcode
2. Select the Amped project in the Project Navigator
3. Select the Amped target
4. Go to the "Build Phases" tab
5. Click the "+" button in the top-left of the build phases section
6. Select "New Run Script Phase"
7. Drag the new run script phase to be positioned after "Copy Bundle Resources"
8. Set the script content to:

```bash
# Run the Info.plist update script
"${SRCROOT}/Amped/Scripts/update_infoplist.sh"
```

9. (Optional) Rename the build phase to "Update Info.plist"
10. Build the project to verify the script runs correctly

## Verifying the Setup

After adding the script to your build phases, you can verify it's working correctly:

1. Clean the build folder (Product > Clean Build Folder)
2. Build the project
3. Right-click on the built app in the Products folder and select "Show in Finder"
4. Right-click on the .app file and select "Show Package Contents"
5. Open the Info.plist file and verify that it contains:
   - NSHealthShareUsageDescription
   - NSHealthUpdateUsageDescription

## Troubleshooting

If the script is not executing:

1. Verify the script has executable permissions:
   ```bash
   chmod +x "${SRCROOT}/Amped/Scripts/update_infoplist.sh"
   ```

2. Check the build log for any script errors

3. Ensure the path to the script is correct in the build phase 