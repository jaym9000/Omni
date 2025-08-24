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

# Files to fix with their correct paths
files_to_fix = [
  {
    name: 'SimpleWelcomeView.swift',
    group_path: 'Views/Onboarding',
    file_path: 'OmniAI/Views/Onboarding/SimpleWelcomeView.swift'
  },
  {
    name: 'QuickSetupView.swift',
    group_path: 'Views/Onboarding',
    file_path: 'OmniAI/Views/Onboarding/QuickSetupView.swift'
  },
  {
    name: 'AIPreviewView.swift',
    group_path: 'Views/Onboarding',
    file_path: 'OmniAI/Views/Onboarding/AIPreviewView.swift'
  },
  {
    name: 'PostTrialSignInView.swift',
    group_path: 'Views/Authentication',
    file_path: 'OmniAI/Views/Authentication/PostTrialSignInView.swift'
  },
  {
    name: 'AnalyticsManager.swift',
    group_path: 'Services',
    file_path: 'OmniAI/Services/AnalyticsManager.swift'
  }
]

puts "Starting file reference fix..."
puts "================================"

# First, remove any existing references to these files
files_to_fix.each do |file_info|
  filename = file_info[:name]
  
  # Find and remove from all groups
  project.main_group.recursive_children.each do |child|
    if child.isa == 'PBXFileReference' && (child.name == filename || child.path&.include?(filename))
      puts "Removing existing reference: #{child.path || child.name}"
      
      # Remove from build phases
      target.source_build_phase.files.each do |build_file|
        if build_file.file_ref == child
          target.source_build_phase.remove_file_reference(build_file.file_ref)
        end
      end
      
      # Remove from parent group
      if child.parent
        child.parent.children.delete(child)
      end
      
      # Remove the reference itself
      child.remove_from_project
    end
  end
end

puts "\nAdding files with correct references..."
puts "========================================"

# Now add files with correct references
files_to_fix.each do |file_info|
  filename = file_info[:name]
  group_path = file_info[:group_path]
  file_path = file_info[:file_path]
  
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
  
  # Check if file exists on disk
  full_path = File.join(Dir.pwd, file_path)
  unless File.exist?(full_path)
    puts "Warning: File not found at #{full_path}"
    next
  end
  
  # Create file reference with relative path from project root
  file_ref = current_group.new_reference(file_path)
  file_ref.name = filename
  
  # Add to target's compile sources
  target.add_file_references([file_ref])
  
  puts "✅ Added: #{filename}"
  puts "   Path: #{file_path}"
  puts "   Group: #{group_path}"
end

# Save the project
project.save

puts "\n✅ Project file references fixed!"
puts "\nNext steps:"
puts "1. Open Xcode and verify files appear correctly"
puts "2. Build the project (Cmd+B)"
puts "3. Run the app to test the new flow"