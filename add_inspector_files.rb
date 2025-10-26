#!/usr/bin/env ruby
require 'securerandom'
require 'fileutils'

# This script adds the inspector files to the Xcode project
# It uses a safe, minimal approach to modify project.pbxproj

PROJECT_FILE = 'Scrib.xcodeproj/project.pbxproj'

# Read the project file
content = File.read(PROJECT_FILE)

# Backup the original file
FileUtils.cp(PROJECT_FILE, "#{PROJECT_FILE}.backup")
puts "✅ Created backup: #{PROJECT_FILE}.backup"

# Define files to add with their groups
files_to_add = [
  {
    path: 'Scrib/ViewModels/InspectorViewModel.swift',
    name: 'InspectorViewModel.swift',
    group: 'ViewModels'
  },
  {
    path: 'Scrib/Views/Components/CollapsibleSection.swift',
    name: 'CollapsibleSection.swift',
    group: 'Components'
  },
  {
    path: 'Scrib/Views/Components/ResearchItemCard.swift',
    name: 'ResearchItemCard.swift',
    group: 'Components'
  },
  {
    path: 'Scrib/Views/Inspector/InspectorView.swift',
    name: 'InspectorView.swift',
    group: 'Inspector',
    create_group: true
  },
  {
    path: 'Scrib/Views/Inspector/BookOutlineSection.swift',
    name: 'BookOutlineSection.swift',
    group: 'Inspector'
  },
  {
    path: 'Scrib/Views/Inspector/ChapterMetadataSection.swift',
    name: 'ChapterMetadataSection.swift',
    group: 'Inspector'
  },
  {
    path: 'Scrib/Views/Inspector/CharactersAndScenesSection.swift',
    name: 'CharactersAndScenesSection.swift',
    group: 'Inspector'
  },
  {
    path: 'Scrib/Views/Inspector/ResearchItemsSection.swift',
    name: 'ResearchItemsSection.swift',
    group: 'Inspector'
  }
]

# Generate UUIDs (24 hex chars in Xcode format)
def generate_uuid
  SecureRandom.hex(12).upcase
end

# Find the PBXBuildFile section
build_file_section_match = content.match(/\/\* Begin PBXBuildFile section \*\/(.+?)\/\* End PBXBuildFile section \*\//m)
unless build_file_section_match
  puts "❌ ERROR: Could not find PBXBuildFile section"
  exit 1
end

# Find the PBXFileReference section
file_ref_section_match = content.match(/\/\* Begin PBXFileReference section \*\/(.+?)\/\* End PBXFileReference section \*\//m)
unless file_ref_section_match
  puts "❌ ERROR: Could not find PBXFileReference section"
  exit 1
end

# Find the PBXGroup section
group_section_match = content.match(/\/\* Begin PBXGroup section \*\/(.+?)\/\* End PBXGroup section \*\//m)
unless group_section_match
  puts "❌ ERROR: Could not find PBXGroup section"
  exit 1
end

# Find the PBXSourcesBuildPhase section
sources_phase_match = content.match(/\/\* Begin PBXSourcesBuildPhase section \*\/(.+?)\/\* End PBXSourcesBuildPhase section \*\//m)
unless sources_phase_match
  puts "❌ ERROR: Could not find PBXSourcesBuildPhase section"
  exit 1
end

# Extract existing sections
build_file_section = build_file_section_match[1]
file_ref_section = file_ref_section_match[1]
group_section = group_section_match[1]
sources_phase_section = sources_phase_match[1]

# Storage for new entries
new_build_files = []
new_file_refs = []
new_group_entries = {}
new_sources_files = []
inspector_group_id = nil

# Process each file
files_to_add.each do |file_info|
  file_ref_id = generate_uuid
  build_file_id = generate_uuid

  # Create PBXFileReference entry
  file_ref_entry = "\t\t#{file_ref_id} /* #{file_info[:name]} */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = #{file_info[:name]}; sourceTree = \"<group>\"; };"
  new_file_refs << file_ref_entry

  # Create PBXBuildFile entry
  build_file_entry = "\t\t#{build_file_id} /* #{file_info[:name]} in Sources */ = {isa = PBXBuildFile; fileRef = #{file_ref_id} /* #{file_info[:name]} */; };"
  new_build_files << build_file_entry

  # Add to sources build phase
  sources_entry = "\t\t\t\t#{build_file_id} /* #{file_info[:name]} in Sources */,"
  new_sources_files << sources_entry

  # Track for group addition
  new_group_entries[file_info[:group]] ||= []
  new_group_entries[file_info[:group]] << {
    id: file_ref_id,
    name: file_info[:name],
    create_group: file_info[:create_group]
  }

  # Store Inspector group ID if we're creating it
  if file_info[:create_group] && file_info[:group] == 'Inspector'
    inspector_group_id = generate_uuid
  end

  puts "  📄 Prepared: #{file_info[:name]}"
end

# Insert new PBXBuildFile entries
content.sub!(/\/\* End PBXBuildFile section \*\//, "#{new_build_files.join("\n")}\n/* End PBXBuildFile section */")

# Insert new PBXFileReference entries
content.sub!(/\/\* End PBXFileReference section \*\//, "#{new_file_refs.join("\n")}\n/* End PBXFileReference section */")

# Add files to PBXSourcesBuildPhase
# Find the files = ( section within PBXSourcesBuildPhase
sources_files_match = sources_phase_section.match(/files = \((.+?)\);/m)
if sources_files_match
  existing_files = sources_files_match[1]
  new_files_section = existing_files + "\n" + new_sources_files.join("\n")
  content.sub!(/\/\* Begin PBXSourcesBuildPhase section \*\/(.+?)files = \((.+?)\);/m) do |match|
    match.sub(/files = \((.+?)\);/m, "files = (#{new_files_section}\n\t\t\t);")
  end
end

# Create Inspector group if needed
if inspector_group_id
  inspector_group_children = new_group_entries['Inspector'].map { |entry| "#{entry[:id]} /* #{entry[:name]} */," }.join("\n\t\t\t\t")

  inspector_group_entry = <<~GROUP
  		#{inspector_group_id} /* Inspector */ = {
  			isa = PBXGroup;
  			children = (
  				#{inspector_group_children}
  			);
  			path = Inspector;
  			sourceTree = "<group>";
  		};
  GROUP

  # Add Inspector group definition
  content.sub!(/\/\* End PBXGroup section \*\//, "#{inspector_group_entry}/* End PBXGroup section */")

  # Add Inspector group to Views group
  views_group_match = content.match(/([A-F0-9]+) \/\* Views \*\/ = \{[^}]*children = \((.+?)\);/m)
  if views_group_match
    views_group_id = views_group_match[1]
    views_children = views_group_match[2]
    new_views_children = views_children.rstrip + "\n\t\t\t\t#{inspector_group_id} /* Inspector */,"
    content.sub!(/#{views_group_id} \/\* Views \*\/ = \{[^}]*children = \((.+?)\);/m) do |match|
      match.sub(/children = \((.+?)\);/m, "children = (#{new_views_children}\n\t\t\t);")
    end
  end
end

# Add files to their respective existing groups (ViewModels and Components)
['ViewModels', 'Components'].each do |group_name|
  next unless new_group_entries[group_name]

  group_match = content.match(/([A-F0-9]+) \/\* #{group_name} \*\/ = \{[^}]*children = \((.+?)\);/m)
  next unless group_match

  group_id = group_match[1]
  group_children = group_match[2]

  new_children_entries = new_group_entries[group_name].map { |entry| "#{entry[:id]} /* #{entry[:name]} */," }.join("\n\t\t\t\t")
  new_group_children = group_children.rstrip + "\n\t\t\t\t" + new_children_entries

  content.sub!(/#{group_id} \/\* #{group_name} \*\/ = \{[^}]*children = \((.+?)\);/m) do |match|
    match.sub(/children = \((.+?)\);/m, "children = (#{new_group_children}\n\t\t\t);")
  end
end

# Write the modified content
File.write(PROJECT_FILE, content)

puts "✅ Successfully added #{files_to_add.length} files to Xcode project"
puts "✅ Created Inspector group in Views"
puts "✅ Added files to Sources build phase"
puts ""
puts "Next steps:"
puts "  1. Open Scrib.xcodeproj in Xcode"
puts "  2. Clean build folder (Cmd+Shift+K)"
puts "  3. Build project (Cmd+B)"
puts ""
puts "If there are any issues, restore the backup:"
puts "  cp #{PROJECT_FILE}.backup #{PROJECT_FILE}"
