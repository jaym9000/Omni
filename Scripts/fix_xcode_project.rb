#!/usr/bin/env ruby

require 'xcodeproj'
require 'pathname'

project_path = 'OmniAI.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Files to add
files_to_add = {
  'OmniAI/Views/Onboarding' => [
    'SimpleWelcomeView.swift',
    'QuickSetupView.swift',
    'AIPreviewView.swift'
  ],
  'OmniAI/Views/Authentication' => [
    'PostTrialSignInView.swift'
  ],
  'OmniAI/Services' => [
    'AnalyticsManager.swift'
  ]
}

# Remove any files with doubled paths
project.files.select { |f| 
  f.path && (f.path.include?('Views/Views') || f.path.include?('Services/Services') || f.path.include?('OmniAI/OmniAI'))
}.each do |file|
  puts "Removing incorrect file: #{file.path}"
  file.remove_from_project
end

# Get main target
target = project.targets.find { |t| t.name == 'OmniAI' }
main_group = project.main_group

# Find or create OmniAI group
omni_group = main_group['OmniAI'] || main_group.new_group('OmniAI')

files_to_add.each do |group_path, files|
  # Navigate to the correct group
  path_components = group_path.split('/')[1..-1] # Skip 'OmniAI' as we already have it
  current_group = omni_group
  
  path_components.each do |component|
    current_group = current_group[component] || current_group.new_group(component)
  end
  
  # Add files to the group
  files.each do |filename|
    # Check if file already exists in the group
    existing = current_group.files.find { |f| f.name == filename }
    if existing
      puts "File #{filename} already exists in #{group_path}"
      next
    end
    
    # Create file reference with relative path from project root
    file_path = "#{group_path}/#{filename}"
    full_path = File.join(Dir.pwd, file_path)
    
    if File.exist?(full_path)
      file_ref = current_group.new_reference(file_path)
      file_ref.name = filename
      
      # Add to target's build phase
      target.add_file_references([file_ref])
      puts "Added #{filename} to #{group_path}"
    else
      puts "Warning: File not found: #{full_path}"
    end
  end
end

# Save the project
project.save
puts "Project fixed and saved!"