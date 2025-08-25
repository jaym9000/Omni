#!/usr/bin/env python3
"""
Script to integrate Security files into Xcode project
This will add all security Swift files to the project structure
"""

import re
import uuid
import os
from pathlib import Path

def generate_uuid():
    """Generate a 24-character hex UUID for Xcode"""
    return uuid.uuid4().hex[:24].upper()

def add_security_files_to_project(project_path):
    """Add security files to the Xcode project"""
    
    # Read the project file
    with open(project_path, 'r') as f:
        content = f.read()
    
    # Security files to add
    security_files = [
        'CertificatePinner.swift',
        'NetworkSecurityManager.swift',
        'BiometricAuthManager.swift',
        'SecureStorageMigrator.swift',
        'AuditLogger.swift'
    ]
    
    # Generate UUIDs for each file
    file_refs = {}
    build_refs = {}
    for file in security_files:
        file_refs[file] = generate_uuid()
        build_refs[file] = generate_uuid()
    
    # Group UUID for Security folder
    security_group_uuid = generate_uuid()
    
    # 1. Add PBXFileReference entries
    file_ref_section = "/* End PBXFileReference section */"
    file_ref_entries = ""
    for file in security_files:
        file_ref_entries += f"\t\t{file_refs[file]} /* {file} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {file}; sourceTree = \"<group>\"; }};\n"
    
    content = content.replace(file_ref_section, file_ref_entries + file_ref_section)
    
    # 2. Add Security group
    group_section = "/* End PBXGroup section */"
    security_group = f"""
\t\t{security_group_uuid} /* Security */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
"""
    for file in security_files:
        security_group += f"\t\t\t\t{file_refs[file]} /* {file} */,\n"
    
    security_group += """\t\t\t);
\t\t\tpath = Security;
\t\t\tsourceTree = "<group>";
\t\t};
"""
    
    content = content.replace(group_section, security_group + group_section)
    
    # 3. Add Security group to OmniAI group (find the main group)
    # Look for the OmniAI group and add Security to its children
    omniai_pattern = r'(1D1A1A282C8F123400123456 /\* OmniAI \*/ = \{[^}]*children = \([^)]*)'
    def add_to_omniai_group(match):
        return match.group(1) + f"\t\t\t\t{security_group_uuid} /* Security */,\n\t\t\t"
    
    content = re.sub(omniai_pattern, add_to_omniai_group, content)
    
    # 4. Add PBXBuildFile entries
    build_file_section = "/* End PBXBuildFile section */"
    build_file_entries = ""
    for file in security_files:
        build_file_entries += f"\t\t{build_refs[file]} /* {file} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[file]} /* {file} */; }};\n"
    
    content = content.replace(build_file_section, build_file_entries + build_file_section)
    
    # 5. Add to PBXSourcesBuildPhase
    sources_pattern = r'(1D1A1A222C8F123400123456 /\* Sources \*/ = \{[^}]*files = \([^)]*)'
    def add_to_sources(match):
        additions = ""
        for file in security_files:
            additions += f"\t\t\t\t{build_refs[file]} /* {file} in Sources */,\n"
        return match.group(1) + additions + "\t\t\t"
    
    content = re.sub(sources_pattern, add_to_sources, content)
    
    # 6. Add LocalAuthentication framework
    # Check if it's not already there
    if "LocalAuthentication.framework" not in content:
        # Generate UUIDs for framework
        framework_ref = generate_uuid()
        framework_build = generate_uuid()
        
        # Add framework reference
        framework_ref_entry = f"\t\t{framework_ref} /* LocalAuthentication.framework */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = LocalAuthentication.framework; path = System/Library/Frameworks/LocalAuthentication.framework; sourceTree = SDKROOT; }};\n"
        content = content.replace(file_ref_section, framework_ref_entry + file_ref_section)
        
        # Add to build file
        framework_build_entry = f"\t\t{framework_build} /* LocalAuthentication.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {framework_ref} /* LocalAuthentication.framework */; }};\n"
        content = content.replace(build_file_section, framework_build_entry + build_file_section)
        
        # Add to frameworks build phase
        frameworks_pattern = r'(1D1A1A232C8F123400123456 /\* Frameworks \*/ = \{[^}]*files = \([^)]*)'
        def add_to_frameworks(match):
            return match.group(1) + f"\t\t\t\t{framework_build} /* LocalAuthentication.framework in Frameworks */,\n\t\t\t"
        
        content = re.sub(frameworks_pattern, add_to_frameworks, content)
    
    # 7. Add FirebaseAppCheck if not present
    if "FirebaseAppCheck" not in content:
        # Find the Firebase package dependency section
        firebase_deps_pattern = r'(888E270B2E553E3E00609191 /\* FirebaseStorage \*/ = \{[^}]*\};)'
        
        # Generate UUID for App Check
        appcheck_uuid = generate_uuid()
        
        # Add App Check dependency
        appcheck_dep = f"""
\t\t{appcheck_uuid} /* FirebaseAppCheck */ = {{
\t\t\tisa = XCSwiftPackageProductDependency;
\t\t\tpackage = 888E26FE2E553E3E00609191 /* XCRemoteSwiftPackageReference "firebase-ios-sdk" */;
\t\t\tproductName = FirebaseAppCheck;
\t\t}};"""
        
        content = re.sub(firebase_deps_pattern, r'\1' + appcheck_dep, content)
        
        # Add to target dependencies
        target_deps_pattern = r'(packageProductDependencies = \([^)]*)'
        def add_appcheck_to_target(match):
            return match.group(1) + f"\t\t\t\t{appcheck_uuid} /* FirebaseAppCheck */,\n\t\t\t"
        
        content = re.sub(target_deps_pattern, add_appcheck_to_target, content)
    
    # Write the modified content back
    with open(project_path, 'w') as f:
        f.write(content)
    
    print("✅ Successfully integrated Security files into Xcode project")
    print("📝 Added files:")
    for file in security_files:
        print(f"   - {file}")
    print("✅ Added LocalAuthentication.framework")
    print("✅ Added FirebaseAppCheck dependency")
    
    return True

if __name__ == "__main__":
    project_path = "/Users/jm/Desktop/Projects-2025/Omni/OmniAI.xcodeproj/project.pbxproj"
    
    if os.path.exists(project_path):
        # Backup the original
        backup_path = project_path + ".backup"
        with open(project_path, 'r') as original:
            with open(backup_path, 'w') as backup:
                backup.write(original.read())
        print(f"📋 Created backup at: {backup_path}")
        
        # Integrate security files
        add_security_files_to_project(project_path)
    else:
        print(f"❌ Project file not found: {project_path}")