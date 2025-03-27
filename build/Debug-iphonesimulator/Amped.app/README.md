# Amped Build Scripts

This directory contains scripts used in the build process for the Amped app.

## Info.plist Management

Amped uses an auto-generated Info.plist approach rather than maintaining a physical Info.plist file. This provides several advantages:

1. Better integration with build settings - changes to bundle identifier, version, etc. are automatically reflected
2. Reduced merge conflicts in source control
3. Less duplication of configuration between project settings and plist file
4. Simpler management of different configurations (Debug/Release)

### How It Works

1. The project is configured with `GENERATE_INFOPLIST_FILE = YES` in build settings
2. Common UI settings are set in the build settings with `INFOPLIST_KEY_*` properties
3. The `update_infoplist.sh` script runs as a build phase to add HealthKit usage descriptions
4. `InfoPlistManager.swift` documents all the key settings (this file is for documentation only)

### Adding New Keys

When you need to add new keys to Info.plist:

1. For simple keys, add them to Xcode build settings with the `INFOPLIST_KEY_` prefix
2. For complex keys, update the `update_infoplist.sh` script
3. Document the new keys in `InfoPlistManager.swift`

### Troubleshooting

If you encounter issues with Info.plist:

1. Check Build Phases to ensure the `update_infoplist.sh` script is running
2. Verify the script has execute permissions (`chmod +x Scripts/update_infoplist.sh`)
3. Clean the build folder and rebuild

### HealthKit Permissions

HealthKit permissions are particularly important for Amped. The app requires:

- NSHealthShareUsageDescription
- NSHealthUpdateUsageDescription

These are added by the `update_infoplist.sh` script to ensure they're always present. 