# Contributing to the 'c' Monorepo

First off, thank you for considering contributing! Your help is appreciated. This project is a combination of a Python toolkit and a static website, and we welcome contributions to all parts of it.

Following these guidelines helps to communicate that you respect the time of the developers managing and developing this open source project. In return, they should reciprocate that respect in addressing your issue, assessing changes, and helping you finalize your pull requests.

## Code of Conduct

This project and everyone participating in it is governed by the [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior.

## How Can I Contribute?

### Reporting Bugs

This is one of the best ways to contribute. Before creating a bug report, please check that the issue hasn't already been reported.

When you are creating a bug report, please use the "Bug Report" template and include as many details as possible. Fill out the required template, the information it asks for helps us resolve issues faster.

### Suggesting Enhancements

If you have an idea for an enhancement, we'd love to hear about it. Please use the "Feature Request" template to submit your idea. Provide as much context and detail as possible.

### Your First Code Contribution

Unsure where to begin contributing? You can start by looking through `good first issue` and `help wanted` issues.

### Pull Requests

The process for submitting a pull request is as follows:

1.  **Fork the repo** and create your branch from `main`.
2.  **Set up your development environment**. This is a Poetry-based Python project.
    ```bash
    # Install project dependencies
    poetry install --with dev
    ```
3.  **Make your changes**. Please ensure your code adheres to the project's style.
4.  **Update the documentation**. If you are adding a new feature or changing behavior, please update the relevant READMEs or docstrings.
5.  **Ensure the test suite passes**.
    ```bash
    # Run tests
    poetry run pytest
    ```
6.  **Check formatting and linting**. We use `ruff` for this.
    ```bash
    # Check for linting errors
    poetry run ruff check .

    # Format the code
    poetry run ruff format .
    ```
7.  **Commit your changes** using a descriptive commit message.
8.  **Push to your fork** and submit a pull request to the `c` repository's `main` branch.
9.  **Fill out the Pull Request template** to the best of your ability.

## Styleguides

### Git Commit Messages

*   Use the present tense ("Add feature" not "Added feature").
*   Use the imperative mood ("Move file to..." not "Moves file to...").
*   Limit the first line to 72 characters or less.
*   Reference issues and pull requests liberally after the first line.

### Python Styleguide

We use `ruff` to enforce code style and quality. Please ensure your code is formatted with `ruff format` before submitting a pull request. The CI pipeline will fail if there are linting or formatting issues.

Thank you!
