#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'OmniAI.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'OmniAI' }
main_group = project.main_group

# Find the OmniAI group
omni_group = main_group['OmniAI']
if omni_group.nil?
  puts "Error: Could not find OmniAI group"
  exit 1
end

# Files to add with their respective groups
files_to_add = {
  'Views/Onboarding' => [
    'SimpleWelcomeView.swift',
    'QuickSetupView.swift',
    'AIPreviewView.swift'
  ],
  'Views/Authentication' => [
    'PostTrialSignInView.swift'
  ],
  'Services' => [
    'AnalyticsManager.swift'
  ]
}

added_count = 0
skipped_count = 0

files_to_add.each do |group_path, files|
  # Navigate to the correct group
  path_components = group_path.split('/')
  current_group = omni_group
  
  path_components.each do |component|
    found_group = current_group[component]
    if found_group.nil?
      found_group = current_group.new_group(component)
      puts "Created group: #{component}"
    end
    current_group = found_group
  end
  
  # Add files to the group
  files.each do |filename|
    # Check if file already exists in the group
    existing = current_group.files.find { |f| f.name == filename || f.path&.include?(filename) }
    if existing
      puts "Skipped: #{filename} (already in project)"
      skipped_count += 1
      next
    end
    
    # Build the file path relative to project root
    file_path = "OmniAI/#{group_path}/#{filename}"
    full_path = File.join(Dir.pwd, file_path)
    
    if File.exist?(full_path)
      # Create file reference
      file_ref = current_group.new_reference(file_path)
      file_ref.name = filename
      
      # Add to target's compile sources build phase
      target.add_file_references([file_ref])
      
      puts "Added: #{filename} to #{group_path}"
      added_count += 1
    else
      puts "Warning: File not found at #{full_path}"
    end
  end
end

# Save the project
project.save

puts "\n✅ Project updated successfully!"
puts "   Added: #{added_count} files"
puts "   Skipped: #{skipped_count} files (already in project)"
puts "\nNext steps:"
puts "1. Build the project to verify"
puts "2. Re-enable the new flow in ContentView.swift"