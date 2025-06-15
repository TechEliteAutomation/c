# c – Core Infrastructure

This repository consolidates core software components into a single, manageable codebase, designed for high-velocity development and robust automation.

### Core Principles

*   **Integrated Environment:** A single `pyproject.toml` manages all Python dependencies, ensuring a consistent development and testing environment across all components.
*   **Cohesive Versioning:** Cross-cutting changes to the library and applications are captured in a single commit, eliminating dependency conflicts and ensuring the entire system is always in a deployable state.
*   **Automated Workflow:** On every push to `main`, the CI/CD pipeline automatically lints, tests, and deploys updated components, including the static site to GitHub Pages.

### Directory Structure

| Path          | Description                                         |
| ------------- | --------------------------------------------------- |
| `.github/`    | CI/CD workflows for testing and deployment.         |
| `apps/`       | Standalone Python applications and entry points.    |
| `docs/`       | Project documentation and technical notes.          |
| `scripts/`    | Shell scripts for system and repository automation. |
| `src/toolkit/`| The core Python library with shared modules.        |
| `tests/`      | Unit and integration tests for the toolkit.         |
| `web/`        | Source files for the static website.                |
