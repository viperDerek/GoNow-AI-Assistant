#!/bin/bash

echo "🚀 Launching GoNow Complete Ecosystem..."
echo "========================================"

# 1. Launch macOS GoNow app
echo "📱 Launching macOS GoNow app..."
if [ -f ~/Desktop/GoNow.command ]; then
    ~/Desktop/GoNow.command &
    echo "✅ macOS GoNow app launched"
else
    echo "❌ macOS GoNow.command not found"
fi

# 2. Open iOS Simulator with iPhone 16 Pro
echo "📱 Opening iPhone Simulator..."
xcrun simctl boot "iPhone 16 Pro" 2>/dev/null
open -a Simulator
echo "✅ iPhone 16 Pro Simulator opened"

# 3. Open Apple Watch Simulator
echo "⌚ Opening Apple Watch Simulator..."
xcrun simctl boot "Apple Watch Ultra 2 (49mm)" 2>/dev/null
echo "✅ Apple Watch Ultra 2 Simulator opened"

# 4. Install and launch Watch app
echo "⌚ Launching MeetingAlarmWatch app..."
xcrun simctl install "Apple Watch Ultra 2 (49mm)" "/Users/I314306/Library/Developer/Xcode/DerivedData/MeetingAlarmWatch-acruuicvhndcvobranelbpetterq/Build/Intermediates.noindex/ArchiveIntermediates/MeetingAlarmWatch Watch App/IntermediateBuildFilesPath/UninstalledProducts/watchsimulator/MeetingAlarmWatch Watch App.app"
xcrun simctl launch "Apple Watch Ultra 2 (49mm)" com.meetingalarm.watch
echo "✅ MeetingAlarmWatch app launched on Apple Watch"

# 5. Open System Preferences for calendar permission
echo "🔐 Opening System Preferences for calendar permission..."
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars"
echo "✅ System Preferences opened - Please grant calendar access to Terminal"

echo ""
echo "🎉 GoNow Ecosystem Launch Complete!"
echo "=================================="
echo ""
echo "📋 What's Running:"
echo "• macOS: GoNow app (needs calendar permission)"
echo "• iPhone: Simulator ready for GoNow app"
echo "• Apple Watch: MeetingAlarmWatch app running"
echo ""
echo "🎯 Next Steps:"
echo "1. Grant calendar permission to Terminal in System Preferences"
echo "2. Add 'GoNow' tag to calendar events with locations"
echo "3. Watch for departure notifications on your Apple Watch!"
echo ""
echo "Never be late for meetings again! 🎉"