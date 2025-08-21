#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = '/Users/jm/Desktop/Projects-2025/Omni/OmniAI.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Get the main group
main_group = project.main_group['OmniAI']

# Files to add
files_to_add = {
  'Services' => ['MoodManager.swift'],
  'Views/Home' => ['MoodAnalyticsView.swift', 'MoodHistoryView.swift']
}

# Add files to project
files_to_add.each do |group_path, files|
  # Navigate to the correct group
  group = main_group
  group_path.split('/').each do |part|
    group = group[part] || group.new_group(part)
  end
  
  files.each do |filename|
    file_path = "OmniAI/#{group_path}/#{filename}"
    full_path = "/Users/jm/Desktop/Projects-2025/Omni/#{file_path}"
    
    if File.exist?(full_path)
      # Check if file already exists in project
      existing = group.files.find { |f| f.path&.end_with?(filename) }
      
      unless existing
        # Add file reference
        file_ref = group.new_file(full_path)
        
        # Add to target
        target.add_file_references([file_ref])
        
        puts "Added: #{file_path}"
      else
        puts "Already exists: #{file_path}"
      end
    else
      puts "File not found: #{full_path}"
    end
  end
end

# Save the project
project.save
puts "\nProject updated successfully!"