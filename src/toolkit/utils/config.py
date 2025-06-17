# src/my_toolkit/utils/config.py

import tomllib  # Use the standard library TOML parser
from pathlib import Path

# This variable will cache the loaded configuration to avoid re-reading the file.
_config = None


def get_project_root() -> Path:
    """Finds the project's root directory by looking for pyproject.toml."""
    # Start from the current file's directory and go up
    current_path = Path(__file__).parent
    while current_path != current_path.parent:
        if (current_path / "pyproject.toml").exists():
            return current_path
        current_path = current_path.parent
    raise FileNotFoundError(
        "Could not find the project root (containing pyproject.toml)."
    )


def load_config() -> dict:
    """
    Loads the configuration from config.toml in the project root.

    Caches the result after the first load for efficiency.

    Returns:
        A dictionary containing all the configuration settings.

    Raises:
        FileNotFoundError: If config.toml does not exist.
        tomllib.TOMLDecodeError: If the config file has a syntax error.
    """
    global _config
    if _config is not None:
        # Return the cached config if it's already loaded
        return _config

    try:
        project_root = get_project_root()
        config_path = project_root / "config.toml"

        with open(config_path, "rb") as f:
            _config = tomllib.load(f)
        return _config

    except FileNotFoundError:
        print("❌ Configuration Error: 'config.toml' not found in the project root.")
        print(
            "Please copy 'config.example.toml' to 'config.toml' and add your API key."
        )
        raise

    except tomllib.TOMLDecodeError as e:
        print(f"❌ Configuration Error: Could not parse 'config.toml'. Error: {e}")
        raise
