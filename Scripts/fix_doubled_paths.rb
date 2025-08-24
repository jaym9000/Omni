#!/usr/bin/env ruby

require 'xcodeproj'

# Open the project
project_path = 'OmniAI.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.find { |t| t.name == 'OmniAI' }

puts "Fixing doubled paths in project file..."
puts "=" * 50

# Files that need fixing
files_to_fix = [
  'SimpleWelcomeView.swift',
  'QuickSetupView.swift', 
  'AIPreviewView.swift',
  'PostTrialSignInView.swift',
  'AnalyticsManager.swift'
]

fixed_count = 0

# Iterate through all file references
project.files.each do |file_ref|
  next unless file_ref.path
  
  # Check if this is one of our problem files
  if files_to_fix.any? { |f| file_ref.path.include?(f) }
    old_path = file_ref.path
    
    # Fix doubled paths like "OmniAI/Views/OmniAI/Views/..."
    if old_path.include?('OmniAI/Services/OmniAI/Services/')
      new_path = old_path.gsub('OmniAI/Services/OmniAI/Services/', 'OmniAI/Services/')
      file_ref.path = new_path
      puts "Fixed: #{old_path}"
      puts "   To: #{new_path}"
      fixed_count += 1
    elsif old_path.include?('OmniAI/Views/OmniAI/Views/')
      new_path = old_path.gsub('OmniAI/Views/OmniAI/Views/', 'OmniAI/Views/')
      file_ref.path = new_path
      puts "Fixed: #{old_path}"
      puts "   To: #{new_path}"
      fixed_count += 1
    end
  end
end

# Also check build files
target.source_build_phase.files.each do |build_file|
  file_ref = build_file.file_ref
  next unless file_ref && file_ref.path
  
  if files_to_fix.any? { |f| file_ref.path.include?(f) }
    old_path = file_ref.path
    
    if old_path.include?('OmniAI/Services/OmniAI/Services/')
      new_path = old_path.gsub('OmniAI/Services/OmniAI/Services/', 'OmniAI/Services/')
      file_ref.path = new_path
      puts "Fixed build file: #{old_path}"
      puts "              To: #{new_path}"
      fixed_count += 1
    elsif old_path.include?('OmniAI/Views/OmniAI/Views/')
      new_path = old_path.gsub('OmniAI/Views/OmniAI/Views/', 'OmniAI/Views/')
      file_ref.path = new_path
      puts "Fixed build file: #{old_path}"
      puts "              To: #{new_path}"
      fixed_count += 1
    end
  end
end

# Save the project
project.save

puts "\n✅ Fixed #{fixed_count} path references!"
puts "\nNext steps:"
puts "1. Build the project (Cmd+B)"
puts "2. Run the app to test"