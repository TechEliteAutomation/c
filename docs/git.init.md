# Repository Initialization Plan

## 1. Introduction

This document outlines a technically precise, phased implementation plan to establish a professional-grade GitHub repository from your existing project structure. It is designed for an expert user, emphasizing safety, a clean Git history, and robust automation from the first commit.

### Guiding Principles

*   **Safety First:** No files will be moved or deleted until the repository is safely under version control with a proper `.gitignore` file.
*   **Atomic Commits:** Each logical change (e.g., configuration, refactoring, documentation) will be a separate, well-documented commit. This creates a clean, auditable, and revert-friendly history.
*   **Configuration as Code:** All tooling and workflow configurations will be codified within the repository, ensuring reproducibility.
*   **Automation as a Guardrail:** Continuous Integration (CI) will be established to enforce standards automatically on every change.

## 2. Phased Implementation Plan

Execute these phases in sequence. Each phase culminates in one or more atomic commits.

---

### **Phase 1: Environment & Tooling Setup**

**Objective:** Prepare the local environment with the necessary development tools before modifying the project.

*   **Action 1.1: Install Development Dependencies**
    *   **Description:** Add `ruff` for high-performance linting/formatting, `black` for uncompromising formatting, and `pytest` for testing to your project's development dependencies using Poetry.
    *   **Command:**
        ```bash
        poetry add --group dev ruff black pytest
        ```

---

### **Phase 2: Git Initialization & Hygiene**

**Objective:** Establish the repository's ground rules and initialize version control safely. This is the most critical phase.

*   **Action 2.1: Create `.gitignore`**
    *   **Description:** This file is essential for preventing secrets (`config.toml`), temporary files, and OS-specific clutter from ever entering the repository's history.
    *   **Command:**
        ```bash
        touch .gitignore
        ```
    *   **Content:** Populate the file with the complete content from **Appendix A: .gitignore**.

*   **Action 2.2: Create `.editorconfig`**
    *   **Description:** Enforces consistent coding styles (indentation, line endings, etc.) across different editors and IDEs, preventing trivial style conflicts.
    *   **Command:**
        ```bash
        touch .editorconfig
        ```
    *   **Content:** Populate the file with the content from **Appendix B: .editorconfig**.

*   **Action 2.3: Initialize Git & Commit Configuration**
    *   **Description:** With the ignore file in place, it is now safe to initialize the repository. The first commit will contain only the core configuration files, establishing a clean baseline.
    *   **Commands:**
        ```bash
        git init -b main
        git add .gitignore .editorconfig
        git commit -m "chore(project): configure git and editor settings

        - Add .gitignore to exclude local configs, caches, and OS files.
        - Add .editorconfig to enforce consistent coding styles."
        ```

*   **Action 2.4: Add All Project Files to Version Control**
    *   **Description:** Now that the ignore rules are active, add the entire current project state to version control in a single, foundational commit.
    *   **Commands:**
        ```bash
        git add .
        git commit -m "feat: initial commit of project structure

        Adds the complete, unrefactored project structure as the foundational baseline. All subsequent commits will refine this structure."
        ```

---

### **Phase 3: Structural Refactoring**

**Objective:** Reorganize the project's file structure for maximum clarity and logical grouping.

*   **Action 3.1: Create New Directory Structure**
    *   **Description:** Create all necessary target directories for the refactoring.
    *   **Command:**
        ```bash
        mkdir -p .meta/prompts .meta/artifacts docs/notes scripts/browser
        ```

*   **Action 3.2: Relocate Files and Directories using Git**
    *   **Description:** Use `git mv` to move files. This explicitly tells Git about the move, preserving file history.
    *   **Commands:**
        ```bash
        # Move stray text and product files to a meta directory
        git mv 1.txt docs/notes/initial-project-notes.md
        git mv product.txt .meta/product-description.txt

        # Move the userscript to a more specific scripts directory
        git mv assets/yt_wl_remover.user.js scripts/browser/

        # The 'assets' directory is now empty, remove it
        rmdir assets

        # Move the prompt engineering files to the non-source meta directory
        git mv prompts/ .meta/prompts/

        # Move the HTML files from docs, as they appear to be artifacts/notes
        git mv docs/*.html .meta/artifacts/
        ```

*   **Action 3.3: Commit Structural Changes**
    *   **Description:** Commit all file movements as a single, logical change.
    *   **Commands:**
        ```bash
        git add .
        git commit -m "refactor(project): reorganize file and directory structure

        - Establish a .meta/ directory for non-source assets like prompts and artifacts.
        - Create a docs/notes/ directory for miscellaneous documentation.
        - Reorganize scripts into a more logical structure.
        - Consolidate project layout for improved clarity and separation of concerns."
        ```

---

### **Phase 4: Code Quality & Standardization**

**Objective:** Configure and apply automated code quality tools to establish a clean, consistent codebase.

*   **Action 4.1: Configure Tooling in `pyproject.toml`**
    *   **Description:** Add the configurations for `black` and `ruff` to your `pyproject.toml`. The provided `ruff` configuration is comprehensive and correctly configured for your `src` layout.
    *   **Content:** Append the content from **Appendix C: pyproject.toml Configuration** to your `pyproject.toml` file.

*   **Action 4.2: Apply Formatting and Linting**
    *   **Description:** Run the tools across the entire codebase to format all files and automatically fix any linting errors.
    *   **Commands:**
        ```bash
        # Format the entire codebase
        poetry run ruff format .

        # Lint and automatically fix all possible issues
        poetry run ruff check . --fix
        ```

*   **Action 4.3: Commit Code Quality Changes**
    *   **Description:** Commit the tooling configuration and the resulting code style changes.
    *   **Commands:**
        ```bash
        git add pyproject.toml .
        git commit -m "style(python): apply ruff and black formatting

        - Configure Ruff and Black in pyproject.toml for consistent style.
        - Add isort configuration within Ruff to manage imports correctly.
        - Run initial format and lint pass across the entire codebase."
        ```

---

### **Phase 5: Documentation Suite**

**Objective:** Create a comprehensive set of documentation to define the project for users and contributors.

*   **Action 5.1: Create Legal and Community Files**
    *   **Description:** Add the `LICENSE` and a `CODE_OF_CONDUCT.md`.
    *   **Commands:**
        ```bash
        # Create LICENSE file (MIT is a strong default)
        touch LICENSE
        # Create CODE_OF_CONDUCT.md (Contributor Covenant is the standard)
        touch CODE_OF_CONDUCT.md
        ```
    *   **Content:**
        *   For `LICENSE`, populate it with the full text of the MIT License.
        *   For `CODE_OF_CONDUCT.md`, populate it with the Contributor Covenant v2.1, available at [contributor-covenant.org](https://www.contributor-covenant.org/version/2/1/code_of_conduct.md).

*   **Action 5.2: Create Contribution and Project READMEs**
    *   **Description:** Create the core `CONTRIBUTING.md` and enhance all necessary `README.md` files.
    *   **Commands:**
        ```bash
        touch CONTRIBUTING.md
        # Overwrite the root README with a better template
        # Create contextual READMEs
        touch apps/README.md scripts/README.md src/toolkit/README.md web/README.md
        ```
    *   **Content:**
        *   Populate `CONTRIBUTING.md` with the template from **Appendix D: CONTRIBUTING.md**.
        *   Replace the content of the root `README.md` with a comprehensive project overview.
        *   Add brief, single-purpose descriptions to the contextual `README.md` files.

*   **Action 5.3: Commit Documentation**
    *   **Commands:**
        ```bash
        git add .
        git commit -m "docs(project): create initial documentation suite

        - Add MIT LICENSE.
        - Add Contributor Covenant Code of Conduct.
        - Add comprehensive CONTRIBUTING.md guidelines.
        - Create root README and contextual READMEs for key directories."
        ```

---

### **Phase 6: Continuous Integration (CI) Automation**

**Objective:** Implement a GitHub Actions workflow to automate quality checks.

*   **Action 6.1: Create CI Workflow**
    *   **Description:** Create the directory and YAML file for the CI workflow. This version separates linting and testing into distinct jobs for faster feedback and clarity, and includes caching for performance.
    *   **Commands:**
        ```bash
        mkdir -p .github/workflows
        touch .github/workflows/ci.yml
        ```
    *   **Content:** Populate the file with the complete, multi-job workflow from **Appendix E: GitHub Actions CI Workflow**.

*   **Action 6.2: Commit CI Workflow**
    *   **Commands:**
        ```bash
        git add .github/
        git commit -m "ci(github): add CI workflow for linting and testing

        - Implement a GitHub Actions workflow that runs on push/pull_request.
        - Job 1: Lints and checks formatting with Ruff.
        - Job 2: Runs pytest suite across multiple Python versions (3.10, 3.11, 3.12), dependent on the success of Job 1."
        ```

---

### **Phase 7: Finalization**

**Objective:** Push the clean, professional, and well-documented repository to GitHub.

*   **Action 7.1: Push to Remote**
    *   **Description:** Add the remote origin and push your complete, clean history to GitHub.
    *   **Commands:**
        ```bash
        git remote add origin <your-repository-url>
        git push -u origin main
        ```

## 3. Post-Initialization Recommendations

1.  **Branch Protection:** In your GitHub repository settings, configure branch protection rules for `main`. Require status checks (your CI jobs) to pass before merging.
2.  **Image Optimization & LFS:** For the large images in `web/assets/images/`, evaluate using **Git LFS (Large File Storage)**. This tracks large files outside the main repository, keeping it fast. If you choose this path, you would run `git lfs track "web/assets/images/*.jpg"` and ensure `.gitattributes` is committed.
3.  **Issue & PR Templates:** Create issue and pull request templates in the `.github/` directory to guide contributors.

---

## Appendix: File Contents

<details>
<summary><strong>A. .gitignore</strong></summary>

```gitignore
# ===================================================================
# Local Configuration
# ===================================================================
# Never commit local configuration files or secrets.
config.toml

# ===================================================================
# Python
# ===================================================================
# Byte-compiled / optimized / C extensions
__pycache__/
*.py[cod]
*$py.class
*.so

# Distribution / packaging
.Python
/build/
/develop-eggs/
/dist/
/downloads/
/eggs/
/.eggs/
/lib/
/lib64/
/parts/
/sdist/
/var/
/wheels/
/pip-wheel-metadata/
/share/python-wheels/
*.egg-info/
.installed.cfg
*.egg
MANIFEST

# PyInstaller
*.spec

# Installer logs
pip-log.txt
pip-delete-this-directory.txt

# Unit test / coverage reports
/htmlcov/
/.tox/
/.nox/
/.coverage
.coverage.*
/.cache
nosetests.xml
coverage.xml
*.cover
*.py,cover
/.hypothesis/
/.pytest_cache/

# Environments
.env
.venv
/env/
/venv/
/ENV/
/env.bak/
/venv.bak/

# ===================================================================
# General
# ===================================================================
# OS-generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE / Editor specific
.idea/
.vscode/
*.swp
*~
*.bak

# ===================================================================
# Project Specific
# ===================================================================
# Meta-directories for non-source assets
.meta/

# Add any other large, local-only directories here if needed.
# For example:
# /my_large_dataset/
```
</details>

<details>
<summary><strong>B. .editorconfig</strong></summary>

```editorconfig
# EditorConfig is awesome: https://EditorConfig.org

# top-most EditorConfig file
root = true

[*]
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true
indent_style = space
indent_size = 4

[*.{html,css,scss,js,json,yml,yaml}]
indent_size = 2

[*.md]
trim_trailing_whitespace = false

[Makefile]
indent_style = tab
```
</details>

<details>
<summary><strong>C. pyproject.toml Configuration</strong></summary>

```toml
# Append this to the end of your pyproject.toml

[tool.black]
line-length = 88
target-version = ['py310', 'py311', 'py312']
include = '\.pyi?$'
exclude = '''
/(
    \.eggs
  | \.git
  | \.hg
  | \.mypy_cache
  | \.tox
  | \.venv
  | _build
  | buck-out
  | build
  | dist
)/
'''

[tool.ruff]
line-length = 88
target-version = "py310"

[tool.ruff.lint]
# See https://docs.astral.sh/ruff/rules/ for all rules
select = [
    "E",  # pycodestyle errors
    "W",  # pycodestyle warnings
    "F",  # pyflakes
    "I",  # isort
    "C",  # flake8-comprehensions
    "B",  # flake8-bugbear
]
ignore = []

# Allow unused variables when underscore-prefixed.
dummy-variable-rgx = "^(_+|(_+[a-zA-Z0-9_]*[a-zA-Z0-9]+?))$"

[tool.ruff.lint.isort]
# Tell isort that 'toolkit' is a first-party module.
# This is crucial for the src layout.
known-first-party = ["toolkit"]

[tool.ruff.format]
quote-style = "double"
indent-style = "space"
skip-magic-trailing-comma = false
line-ending = "lf"
```</details>

<details>
<summary><strong>D. CONTRIBUTING.md</strong></summary>

```markdown
# Contributing to [Project Name]

We welcome and appreciate all contributions. By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

## Development Setup

This project uses [Poetry](https://python-poetry.org/) for dependency management.

1.  **Fork and Clone:** Fork the repository on GitHub and clone your fork locally.
    ```bash
    git clone https://github.com/<your-username>/[project-name].git
    cd [project-name]
    ```

2.  **Install Dependencies:**
    ```bash
    poetry install
    ```

3.  **Configure Local Settings:**
    ```bash
    cp config.example.toml config.toml
    ```
    Edit `config.toml` with your local settings and API keys. **Do not commit `config.toml`.**

## Making Changes

1.  **Create a Branch:** Create a new branch from `main` for your changes.
    ```bash
    git checkout -b <branch-name>
    # e.g., git checkout -b feat/new-analyzer
    ```

2.  **Implement Changes:** Make your code changes. Add or update tests as necessary.

3.  **Ensure Code Quality:** Before committing, run the quality checks.
    ```bash
    # Format your code
    poetry run ruff format .

    # Lint your code
    poetry run ruff check . --fix
    ```

4.  **Run Tests:** Ensure all tests pass.
    ```bash
    poetry run pytest
    ```

## Submitting a Pull Request

1.  Commit your changes with a descriptive, [conventional commit](https://www.conventionalcommits.org/) message.
2.  Push your branch to your fork.
3.  Open a pull request against the `main` branch of the upstream repository.
4.  Provide a clear description of the changes in the pull request. Link to any relevant issues.
```
</details>

<details>
<summary><strong>E. GitHub Actions CI Workflow (.github/workflows/ci.yml)</strong></summary>

```yaml
name: Python CI

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  lint-and-format:
    name: Lint & Format Check
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'
          cache: 'poetry'

      - name: Install Poetry
        uses: snok/install-poetry@v1

      - name: Install dependencies
        run: poetry install

      - name: Check formatting with Ruff
        run: poetry run ruff format --check .

      - name: Lint with Ruff
        run: poetry run ruff check .

  test:
    name: Run Pytest Suite
    needs: lint-and-format
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        python-version: ["3.10", "3.11", "3.12"]

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Python ${{ matrix.python-version }}
        uses: actions/setup-python@v5
        with:
          python-version: ${{ matrix.python-version }}
          cache: 'poetry'

      - name: Install Poetry
        uses: snok/install-poetry@v1

      - name: Install dependencies
        run: poetry install

      - name: Run tests with pytest
        run: poetry run pytest
```
</details>
