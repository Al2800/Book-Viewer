#!/usr/bin/env python3
"""
Fix Xcode project by adding missing source files and removing stale references.
"""

import hashlib
from pathlib import Path

PROJECT_DIR = Path(__file__).parent.parent
PBXPROJ_PATH = PROJECT_DIR / "BookQuotes.xcodeproj" / "project.pbxproj"

# Missing source files that need to be added to main target
MISSING_FILES = [
    "BookQuotes/Features/Capture/ImageReviewView.swift",
    "BookQuotes/Features/Capture/QuoteCaptureView.swift",
    "BookQuotes/Features/Auth/SignInView.swift",
    "BookQuotes/Features/BookRegistration/CoverCaptureView.swift",
    "BookQuotes/Features/Subscription/PaywallView.swift",
    "BookQuotes/Features/Subscription/SubscriptionStatusView.swift",
    "BookQuotes/Features/Subscription/PremiumFeatureList.swift",
    "BookQuotes/Features/Subscription/SubscriptionOptionCard.swift",
    # "BookQuotes/Models/BookMetadata.swift",  # Duplicate - defined in ISBNLookupService.swift
    "BookQuotes/Models/SearchResults.swift",
    "BookQuotes/Models/User.swift",
    "BookQuotes/Utilities/UITestConfiguration.swift",
    "BookQuotes/Utilities/AccessibilityIdentifiers.swift",
    "BookQuotes/Utilities/MockCameraImages.swift",
    "BookQuotes/Components/SkeletonView.swift",
    "BookQuotes/Components/CaptureButton.swift",
    "BookQuotes/Components/CameraPreviewView.swift",
    "BookQuotes/Components/CameraPreview.swift",
    "BookQuotes/Components/HeartBurstButton.swift",
    "BookQuotes/Components/MilestoneCelebration.swift",
    "BookQuotes/Services/UITestDataSeeder.swift",
    "BookQuotes/Services/QuoteExtractionResult.swift",
    "BookQuotes/Services/SubscriptionService.swift",
    "BookQuotes/Services/BatchProcessingService.swift",
    "BookQuotes/Services/GeminiService.swift",
    "BookQuotes/Services/CaptureQueueManager.swift",
    "BookQuotes/Services/QuoteExtractionPromptBuilder.swift",
    "BookQuotes/Services/AuthService.swift",
]

# Stale references to remove (UUIDs for non-existent SearchError.swift and SearchResults.swift in Services)
STALE_UUIDS = [
    "A8B9C0D1E2F3A4B5C6D7E8F9",  # SearchError.swift build file
    "A9B0C1D2E3F4A5B6C7D8E9F0",  # SearchResults.swift build file
    "B8C9D0E1F2A3B4C5D6E7F8A9",  # SearchError.swift file ref
    "B9C0D1E2F3A4B5C6D7E8F9A0",  # SearchResults.swift file ref
]

def generate_uuid(seed: str) -> str:
    """Generate a deterministic 24-character UUID from a seed string."""
    hash_val = hashlib.md5(seed.encode()).hexdigest().upper()
    return hash_val[:24]

def main():
    with open(PBXPROJ_PATH, 'r') as f:
        content = f.read()

    # Remove stale references
    for uuid in STALE_UUIDS:
        lines = content.split('\n')
        content = '\n'.join(line for line in lines if uuid not in line)
    print(f"Removed {len(STALE_UUIDS)} stale references")

    # Generate entries for missing files
    file_refs = []
    build_files = []
    build_file_entries = []

    for path in MISSING_FILES:
        name = Path(path).name
        file_ref_uuid = generate_uuid(f"ADDFILE_{path}")
        build_file_uuid = generate_uuid(f"ADDBUILD_{path}")

        # File reference entry
        file_ref = f'\t\t{file_ref_uuid} /* {name} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{path}"; sourceTree = SOURCE_ROOT; }};'
        file_refs.append(file_ref)

        # Build file entry
        build_file = f'\t\t{build_file_uuid} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {name} */; }};'
        build_files.append(build_file)

        # For sources build phase
        build_file_entries.append(f'\t\t\t\t{build_file_uuid} /* {name} in Sources */,')

    # Insert file references
    file_refs_text = '\n'.join(file_refs)
    content = content.replace(
        "/* End PBXFileReference section */",
        file_refs_text + "\n/* End PBXFileReference section */"
    )

    # Insert build files
    build_files_text = '\n'.join(build_files)
    content = content.replace(
        "/* End PBXBuildFile section */",
        build_files_text + "\n/* End PBXBuildFile section */"
    )

    # Add to main target's Sources build phase
    # Find the BookQuotes target's Sources section (1B1C1D1E1F20212223242526)
    import re

    # Find and update the main target's sources build phase
    sources_pattern = r'(1B1C1D1E1F20212223242526 /\* Sources \*/ = \{[^}]*files = \()([^)]*?)(\);)'

    def add_files_to_sources(match):
        prefix = match.group(1)
        existing = match.group(2)
        suffix = match.group(3)
        new_entries = '\n'.join(build_file_entries)
        return f'{prefix}{existing}\n{new_entries}\n\t\t\t{suffix}'

    content = re.sub(sources_pattern, add_files_to_sources, content, flags=re.DOTALL)

    # Write back
    with open(PBXPROJ_PATH, 'w') as f:
        f.write(content)

    print(f"Added {len(MISSING_FILES)} missing source files to project")
    print("Project file updated successfully!")

if __name__ == "__main__":
    main()
