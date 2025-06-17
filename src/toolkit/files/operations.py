# src/toolkit/files/operations.py

import glob
import os
from pathlib import Path


def find_latest_file(pattern: str, search_path: str = ".") -> Path | None:
    """
    Finds the most recently modified file matching a glob pattern.

    Args:
        pattern: The glob pattern to search for (e.g., "report_*.txt").
        search_path: The directory to search in.

    Returns:
        A Path object to the latest file, or None if no files match.
    """
    try:
        glob_pattern = str(Path(search_path) / pattern)
        list_of_files = glob.glob(glob_pattern)
        if not list_of_files:
            return None
        latest_file = max(list_of_files, key=os.path.getctime)
        print(f"Found latest file: {latest_file}")
        return Path(latest_file)
    except Exception as e:
        print(f"Error finding latest file with pattern '{pattern}': {e}")
        return None


def read_file(filepath: Path | str) -> str:
    """
    Reads the entire content of a file.

    Args:
        filepath: The path to the file.

    Returns:
        The content of the file as a string.
    """
    try:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
        print(f"Read content from: {filepath}")
        return content
    except FileNotFoundError:
        print(f"Error: File not found at {filepath}")
        raise
    except Exception as e:
        print(f"Error reading file {filepath}: {e}")
        raise


def save_file(content: str, filepath: Path | str):
    """
    Saves content to a file, creating parent directories if they don't exist.

    Args:
        content: The string content to save.
        filepath: The destination path for the file.
    """
    try:
        path_obj = Path(filepath)
        path_obj.parent.mkdir(parents=True, exist_ok=True)
        with open(path_obj, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Content saved to: {filepath}")
    except Exception as e:
        print(f"Error saving file to {filepath}: {e}")
        raise
