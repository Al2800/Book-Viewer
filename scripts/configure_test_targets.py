#!/usr/bin/env python3
"""
Configure Xcode project with test targets.
Adds BookQuotesTests target and populates both test targets with source files.
"""

import os
import re
import hashlib
from pathlib import Path

PROJECT_DIR = Path(__file__).parent.parent
PBXPROJ_PATH = PROJECT_DIR / "BookQuotes.xcodeproj" / "project.pbxproj"

def generate_uuid(seed: str) -> str:
    """Generate a deterministic 24-character UUID from a seed string."""
    hash_val = hashlib.md5(seed.encode()).hexdigest().upper()
    return hash_val[:24]

def get_test_files(directory: str) -> list[tuple[str, str]]:
    """Get all Swift files in a directory with relative paths."""
    files = []
    base_path = PROJECT_DIR / directory
    for swift_file in base_path.rglob("*.swift"):
        rel_path = swift_file.relative_to(PROJECT_DIR)
        files.append((str(rel_path), swift_file.name))
    return sorted(files)

def generate_file_ref(path: str, name: str, prefix: str) -> tuple[str, str]:
    """Generate PBXFileReference entry with proper path."""
    uuid = generate_uuid(f"{prefix}_{path}")
    # Use the full path from project root
    entry = f'\t\t{uuid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{path}"; sourceTree = SOURCE_ROOT; }};'
    return uuid, entry

def generate_build_file(file_ref_uuid: str, name: str, prefix: str) -> tuple[str, str]:
    """Generate PBXBuildFile entry."""
    uuid = generate_uuid(f"BF_{prefix}_{name}")
    entry = f'\t\t{uuid} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {name} */; }};'
    return uuid, entry

def main():
    # Read existing project file
    with open(PBXPROJ_PATH, 'r') as f:
        content = f.read()

    # Get test files
    unit_test_files = get_test_files("BookQuotesTests")
    ui_test_files = get_test_files("BookQuotesUITests")

    print(f"Found {len(unit_test_files)} unit test files")
    print(f"Found {len(ui_test_files)} UI test files")

    # Generate entries
    unit_file_refs = []
    unit_build_files = []
    ui_file_refs = []
    ui_build_files = []

    for path, name in unit_test_files:
        ref_uuid, ref_entry = generate_file_ref(path, name, "UNIT")
        build_uuid, build_entry = generate_build_file(ref_uuid, name, "UNIT")
        unit_file_refs.append((ref_uuid, ref_entry, name))
        unit_build_files.append((build_uuid, build_entry, name))

    for path, name in ui_test_files:
        ref_uuid, ref_entry = generate_file_ref(path, name, "UI")
        build_uuid, build_entry = generate_build_file(ref_uuid, name, "UI")
        ui_file_refs.append((ref_uuid, ref_entry, name))
        ui_build_files.append((build_uuid, build_entry, name))

    # Generate UUIDs for targets and build phases
    UNIT_TARGET_UUID = generate_uuid("BookQuotesTests_TARGET")
    UNIT_SOURCES_UUID = generate_uuid("BookQuotesTests_SOURCES")
    UNIT_FRAMEWORKS_UUID = generate_uuid("BookQuotesTests_FRAMEWORKS")
    UNIT_RESOURCES_UUID = generate_uuid("BookQuotesTests_RESOURCES")
    UNIT_PRODUCT_UUID = generate_uuid("BookQuotesTests_PRODUCT")
    UNIT_CONFIG_LIST_UUID = generate_uuid("BookQuotesTests_CONFIG_LIST")
    UNIT_DEBUG_CONFIG_UUID = generate_uuid("BookQuotesTests_DEBUG")
    UNIT_RELEASE_CONFIG_UUID = generate_uuid("BookQuotesTests_RELEASE")
    UNIT_DEPENDENCY_UUID = generate_uuid("BookQuotesTests_DEPENDENCY")
    UNIT_PROXY_UUID = generate_uuid("BookQuotesTests_PROXY")
    UNIT_GROUP_UUID = generate_uuid("BookQuotesTests_GROUP")

    # Build file entries for insertion
    all_build_file_entries = []
    for _, entry, _ in unit_build_files:
        all_build_file_entries.append(entry)
    for _, entry, _ in ui_build_files:
        all_build_file_entries.append(entry)

    # File reference entries for insertion
    all_file_ref_entries = []
    for _, entry, _ in unit_file_refs:
        all_file_ref_entries.append(entry)
    for _, entry, _ in ui_file_refs:
        all_file_ref_entries.append(entry)

    # Insert build file entries before "/* End PBXBuildFile section */"
    build_files_insert = "\n".join(all_build_file_entries)
    content = content.replace(
        "/* End PBXBuildFile section */",
        build_files_insert + "\n/* End PBXBuildFile section */"
    )

    # Insert file reference entries before "/* End PBXFileReference section */"
    file_refs_insert = "\n".join(all_file_ref_entries)
    content = content.replace(
        "/* End PBXFileReference section */",
        file_refs_insert + "\n/* End PBXFileReference section */"
    )

    # Add product reference for BookQuotesTests.xctest
    product_ref = f'\t\t{UNIT_PRODUCT_UUID} /* BookQuotesTests.xctest */ = {{isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = BookQuotesTests.xctest; sourceTree = BUILT_PRODUCTS_DIR; }};'
    content = content.replace(
        "/* End PBXFileReference section */",
        product_ref + "\n/* End PBXFileReference section */"
    )

    # Add container item proxy for unit tests
    proxy_entry = f'''
\t\t{UNIT_PROXY_UUID} /* PBXContainerItemProxy */ = {{
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = 0A1B2C3D4E5F6A7B8C9D0E1F /* Project object */;
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = 4B4C4D4E4F50515253545556;
\t\t\tremoteInfo = BookQuotes;
\t\t}};'''
    content = content.replace(
        "/* End PBXContainerItemProxy section */",
        proxy_entry + "\n/* End PBXContainerItemProxy section */"
    )

    # Create unit test sources build phase content
    unit_source_files = ",\n".join([f"\t\t\t\t{uuid} /* {name} in Sources */" for uuid, _, name in unit_build_files])

    # Create UI test sources build phase content
    ui_source_files = ",\n".join([f"\t\t\t\t{uuid} /* {name} in Sources */" for uuid, _, name in ui_build_files])

    # Replace empty UI test sources with actual files
    content = re.sub(
        r'(UITSTSRC1A2B3C4D5E6F7A8BC /\* Sources \*/ = \{[^}]*files = \()[^)]*(\);)',
        f'\\1\n{ui_source_files}\n\t\t\t\\2',
        content
    )

    # Add BookQuotesTests native target
    unit_target = f'''
\t\t{UNIT_TARGET_UUID} /* BookQuotesTests */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {UNIT_CONFIG_LIST_UUID} /* Build configuration list for PBXNativeTarget "BookQuotesTests" */;
\t\t\tbuildPhases = (
\t\t\t\t{UNIT_SOURCES_UUID} /* Sources */,
\t\t\t\t{UNIT_FRAMEWORKS_UUID} /* Frameworks */,
\t\t\t\t{UNIT_RESOURCES_UUID} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t\t{UNIT_DEPENDENCY_UUID} /* PBXTargetDependency */,
\t\t\t);
\t\t\tname = BookQuotesTests;
\t\t\tproductName = BookQuotesTests;
\t\t\tproductReference = {UNIT_PRODUCT_UUID} /* BookQuotesTests.xctest */;
\t\t\tproductType = "com.apple.product-type.bundle.unit-test";
\t\t}};'''
    content = content.replace(
        "/* End PBXNativeTarget section */",
        unit_target + "\n/* End PBXNativeTarget section */"
    )

    # Add to project targets list
    content = re.sub(
        r'(targets = \([^)]*UITSTTGT1A2B3C4D5E6F7A8BC /\* BookQuotesUITests \*/,)',
        f'\\1\n\t\t\t\t{UNIT_TARGET_UUID} /* BookQuotesTests */,',
        content
    )

    # Add sources build phase for unit tests
    unit_sources_phase = f'''
\t\t{UNIT_SOURCES_UUID} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{unit_source_files}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};'''
    content = content.replace(
        "/* End PBXSourcesBuildPhase section */",
        unit_sources_phase + "\n/* End PBXSourcesBuildPhase section */"
    )

    # Add frameworks build phase for unit tests
    unit_frameworks_phase = f'''
\t\t{UNIT_FRAMEWORKS_UUID} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};'''
    content = content.replace(
        "/* End PBXFrameworksBuildPhase section */",
        unit_frameworks_phase + "\n/* End PBXFrameworksBuildPhase section */"
    )

    # Add resources build phase for unit tests
    unit_resources_phase = f'''
\t\t{UNIT_RESOURCES_UUID} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};'''
    content = content.replace(
        "/* End PBXResourcesBuildPhase section */",
        unit_resources_phase + "\n/* End PBXResourcesBuildPhase section */"
    )

    # Add target dependency
    dependency_entry = f'''
\t\t{UNIT_DEPENDENCY_UUID} /* PBXTargetDependency */ = {{
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = 4B4C4D4E4F50515253545556 /* BookQuotes */;
\t\t\ttargetProxy = {UNIT_PROXY_UUID} /* PBXContainerItemProxy */;
\t\t}};'''
    content = content.replace(
        "/* End PBXTargetDependency section */",
        dependency_entry + "\n/* End PBXTargetDependency section */"
    )

    # Add build configurations for unit test target
    unit_debug_config = f'''
\t\t{UNIT_DEBUG_CONFIG_UUID} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = BookQuotesTests;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.bookquotes.BookQuotesTests;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/BookQuotes.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/BookQuotes";
\t\t\t}};
\t\t\tname = Debug;
\t\t}};'''

    unit_release_config = f'''
\t\t{UNIT_RELEASE_CONFIG_UUID} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tBUNDLE_LOADER = "$(TEST_HOST)";
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = YES;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = BookQuotesTests;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.bookquotes.BookQuotesTests;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = NO;
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t\tTEST_HOST = "$(BUILT_PRODUCTS_DIR)/BookQuotes.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/BookQuotes";
\t\t\t}};
\t\t\tname = Release;
\t\t}};'''

    content = content.replace(
        "/* End XCBuildConfiguration section */",
        unit_debug_config + unit_release_config + "\n/* End XCBuildConfiguration section */"
    )

    # Add config list for unit tests
    config_list = f'''
\t\t{UNIT_CONFIG_LIST_UUID} /* Build configuration list for PBXNativeTarget "BookQuotesTests" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{UNIT_DEBUG_CONFIG_UUID} /* Debug */,
\t\t\t\t{UNIT_RELEASE_CONFIG_UUID} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};'''
    content = content.replace(
        "/* End XCConfigurationList section */",
        config_list + "\n/* End XCConfigurationList section */"
    )

    # Add product to Products group
    # Find the Products group and add the new product
    content = re.sub(
        r'(2A3B4C5D6E7F8A9B0C1D2E3F /\* Products \*/ = \{[^}]*children = \([^)]*)(UITSTPROD1A2B3C4D5E6F7A8B)',
        f'\\1{UNIT_PRODUCT_UUID} /* BookQuotesTests.xctest */,\n\t\t\t\t\\2',
        content
    )

    # Write back
    with open(PBXPROJ_PATH, 'w') as f:
        f.write(content)

    print("Project file updated successfully!")
    print(f"Added {len(unit_test_files)} unit test files to BookQuotesTests target")
    print(f"Added {len(ui_test_files)} UI test files to BookQuotesUITests target")

if __name__ == "__main__":
    main()
