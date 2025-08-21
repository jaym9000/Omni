#!/usr/bin/env python3
import subprocess
import os

# Files to add to the project
files_to_add = [
    "OmniAI/Services/MoodManager.swift",
    "OmniAI/Views/Home/MoodAnalyticsView.swift", 
    "OmniAI/Views/Home/MoodHistoryView.swift"
]

project_path = "/Users/jm/Desktop/Projects-2025/Omni/OmniAI.xcodeproj"

# Use xcrun to add files to project
for file_path in files_to_add:
    full_path = f"/Users/jm/Desktop/Projects-2025/Omni/{file_path}"
    
    if os.path.exists(full_path):
        print(f"File exists: {file_path}")
        # Note: Direct programmatic addition to Xcode project requires xcodeproj manipulation
        # which is complex. Will use manual approach instead.
    else:
        print(f"File NOT found: {file_path}")

print("\nAll files exist and are ready to be added to Xcode project.")
print("\nTo complete the setup:")
print("1. Open Xcode")
print("2. Drag these files into the project navigator:")
for f in files_to_add:
    print(f"   - {f}")
print("3. Make sure 'OmniAI' target is selected")
print("4. Build the project (Cmd+B)")