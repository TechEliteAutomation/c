#!/bin/bash

# This script generates the GitHub issue and pull request templates
# as specified in the project implementation plan.
# It is safe to run from the root of your repository.

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting GitHub template generation..."

# 1. Create the necessary directory structure.
# The -p flag ensures it doesn't error if the directory already exists.
echo "--> Creating .github/ISSUE_TEMPLATE directory..."
mkdir -p .github/ISSUE_TEMPLATE

# 2. Create the Bug Report issue template.
echo "--> Generating .github/ISSUE_TEMPLATE/bug_report.md..."
cat << 'EOF' > .github/ISSUE_TEMPLATE/bug_report.md
---
name: Bug Report
about: Create a report to help us improve
title: "[BUG] A brief, descriptive title"
labels: bug, needs-triage
assignees: ''

---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Run command '....'
3. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Environment (please complete the following information):**
- OS: [e.g. Ubuntu 22.04, Windows 11, macOS Sonoma]
- Python Version: [e.g. 3.11]
- Project Version: [e.g. 0.1.0 or commit hash]

**Additional context**
Add any other context about the problem here.
EOF

# 3. Create the Feature Request issue template.
echo "--> Generating .github/ISSUE_TEMPLATE/feature_request.md..."
cat << 'EOF' > .github/ISSUE_TEMPLATE/feature_request.md
---
name: Feature Request
about: Suggest an idea for this project
title: "[FEAT] A brief, descriptive title"
labels: enhancement, needs-triage
assignees: ''

---

**Is your feature request related to a problem? Please describe.**
A clear and concise description of what the problem is. Ex. "I'm always frustrated when..."

**Describe the solution you'd like**
A clear and concise description of what you want to happen.

**Describe alternatives you've considered**
A clear and concise description of any alternative solutions or features you've considered.

**Additional context**
Add any other context or screenshots about the feature request here.
EOF

# 4. Create the Pull Request template.
echo "--> Generating .github/PULL_REQUEST_TEMPLATE.md..."
cat << 'EOF' > .github/PULL_REQUEST_TEMPLATE.md
## Description

Please include a summary of the change and which issue is fixed. Please also include relevant motivation and context. List any dependencies that are required for this change.

Fixes # (issue)

## Type of change

Please delete options that are not relevant.

- [ ] Bug fix (non-breaking change which fixes an issue)
- [ ] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] This change requires a documentation update

## How Has This Been Tested?

Please describe the tests that you ran to verify your changes. Provide instructions so we can reproduce. Please also list any relevant details for your test configuration.

- [ ] Test A
- [ ] Test B

**Test Configuration**:
*   OS:
*   Python Version:
*   ...

## Checklist:

- [ ] My code follows the style guidelines of this project
- [ ] I have performed a self-review of my own code
- [ ] I have commented my code, particularly in hard-to-understand areas
- [ ] I have made corresponding changes to the documentation
- [ ] My changes generate no new warnings
- [ ] I have added tests that prove my fix is effective or that my feature works
- [ ] New and existing unit tests pass locally with my changes
EOF

echo ""
echo "✅ All templates generated successfully."