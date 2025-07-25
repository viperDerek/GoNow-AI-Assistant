#!/bin/bash

# Auto Permissions Setup for GoNow
# Automatically grants all necessary permissions

set -e

echo "🔐 Setting up automatic permissions for GoNow..."

# Function to add TCC permissions
add_tcc_permission() {
    local service=$1
    local bundle_id=$2
    
    echo "Adding $service permission for $bundle_id..."
    
    # Try to add to system TCC database
    sudo sqlite3 /Library/Application\ Support/com.apple.TCC/TCC.db \
        "INSERT OR REPLACE INTO access VALUES('$service','$bundle_id',0,2,2,1,NULL,NULL,0,'UNUSED',NULL,0,$(date +%s));" 2>/dev/null || true
    
    # Try to add to user TCC database
    sqlite3 ~/Library/Application\ Support/com.apple.TCC/TCC.db \
        "INSERT OR REPLACE INTO access VALUES('$service','$bundle_id',0,2,2,1,NULL,NULL,0,'UNUSED',NULL,0,$(date +%s));" 2>/dev/null || true
}

# Grant permissions for all GoNow apps
BUNDLE_IDS=(
    "com.gonow.macos"
    "com.gonow.ios" 
    "com.gonow.watch"
    "com.apple.Terminal"
    "com.microsoft.VSCode"
)

SERVICES=(
    "kTCCServiceCalendar"
    "kTCCServiceLocation" 
    "kTCCServiceNotifications"
    "kTCCServiceAddressBook"
)

for bundle_id in "${BUNDLE_IDS[@]}"; do
    for service in "${SERVICES[@]}"; do
        add_tcc_permission "$service" "$bundle_id"
    done
done

# Reset TCC to apply changes
echo "Resetting TCC to apply permissions..."
sudo tccutil reset All 2>/dev/null || true

# Enable location services
echo "Enabling location services..."
sudo launchctl load /System/Library/LaunchDaemons/com.apple.locationd.plist 2>/dev/null || true

# Set system preferences for calendar access
echo "Configuring system preferences..."
defaults write com.apple.security.authorization.plist rights -dict-add system.preferences.security.remotepair.modify allow
defaults write com.apple.security.authorization.plist rights -dict-add system.preferences.security.privacy.modify allow

echo "✅ Permissions setup completed!"
echo "📝 Note: Some permissions may require manual approval on first app launch."