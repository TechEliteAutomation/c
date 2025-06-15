# C – Core Infrastructure

This repository consolidates core software components into a single, manageable codebase, designed for high-velocity development and robust automation.

### Core Principles

*   **Integrated Environment:** A single `pyproject.toml` manages all Python dependencies, ensuring a consistent development and testing environment across all components.
*   **Cohesive Versioning:** Cross-cutting changes to the library and applications are captured in a single commit, eliminating dependency conflicts and ensuring the entire system is always in a deployable state.
*   **Automated Workflow:** On every push to `main`, the CI/CD pipeline automatically lints, tests, and deploys updated components, including the static site to GitHub Pages.

### Getting Started

1.  **Clone the repository:**
    ```bash
    git clone git@github.com:TechEliteAutomation/c.git
    cd c
    ```

2.  **Install dependencies:**
    This project uses [Poetry](https://python-poetry.org/) for dependency management.
    ```bash
    poetry install
    ```

3.  **Configure your environment:**
    Copy the example configuration file and edit it with your local paths and API keys.
    ```bash
    cp config.example.toml config.toml
    nano config.toml
    ```

### Directory Structure

| Path          | Description                                                  |
| ------------- | ------------------------------------------------------------ |
| `.github/`    | CI/CD workflows for testing and deployment via GitHub Actions. |
| `apps/`       | Standalone Python applications and entry points.             |
| `assets/`     | Shared static assets, such as userscripts and media files.   |
| `docs/`       | Project documentation and technical notes.                   |
| `prompts/`    | AI prompt engineering templates and configurations.          |
| `scripts/`    | Shell scripts for system and repository automation.          |
| `src/toolkit/`| The core Python library with shared, importable modules.     |
| `tests/`      | Unit and integration tests for the toolkit.                  |
| `web/`        | Source files for the static website.                         |
