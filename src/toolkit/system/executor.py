# src/toolkit/system/executor.py
import os
import subprocess
import sys
from pathlib import Path


def execute_script(
    script_path: Path | str, cwd: Path | str = "."
) -> subprocess.CompletedProcess:
    """
    Executes a shell script and captures its output, raising an error on failure.

    Args:
        script_path: The path to the shell script to execute.
        cwd: The working directory from which to run the script. Defaults to the
             current directory.

    Returns:
        A subprocess.CompletedProcess object containing the results (stdout, stderr,
        etc.).

    Raises:
        FileNotFoundError: If the script does not exist at the given path.
        subprocess.CalledProcessError: If the script returns a non-zero exit code.
    """
    script_path_obj = Path(script_path)
    if not script_path_obj.is_file():
        raise FileNotFoundError(f"Script not found at: {script_path_obj}")

    print(f"Executing script: {script_path_obj}...")

    try:
        # The 'check=True' argument will raise CalledProcessError on non-zero exit
        # codes.
        process = subprocess.run(
            ["bash", str(script_path_obj)],
            capture_output=True,
            text=True,
            check=True,
            cwd=str(cwd),
        )

        print(f"Script '{script_path_obj.name}' executed successfully.")
        if process.stdout:
            print(f"--- STDOUT: ---\n{process.stdout.strip()}")
        if process.stderr:
            # Stderr is not always an error; it can be used for progress or info.
            print(f"--- STDERR: ---\n{process.stderr.strip()}")

        return process

    except FileNotFoundError as e:
        print("\nERROR: A required file or script was not found.")
        print(f"Details: {e}")
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        print(
            f"ERROR: Script '{script_path_obj.name}' failed with exit code "
            f"{e.returncode}."
        )
        print(f"--- FAILED STDOUT: ---\n{e.stdout.strip()}")
        print(f"--- FAILED STDERR: ---\n{e.stderr.strip()}")
        # Re-raise the exception so the calling application can handle the failure.
        raise
    except Exception as e:
        print(
            f"An unexpected error occurred while executing "
            f"'{script_path_obj.name}': {e}"
        )
        raise

# Add these file system utility functions.
# Ensure they have proper error handling for production use.

def create_file(path: str, content: str):
    """Creates a file at the given path with the specified content."""
    try:
        # Only create directories if path contains a directory component
        dir_path = os.path.dirname(path)
        if dir_path:
            os.makedirs(dir_path, exist_ok=True)
        
        with open(path, "w") as f:
            f.write(content)
        print(f"File created: {path}")
        return True
    except Exception as e:
        print(f"Error creating file {path}: {e}")
        return False

def read_file(path: str) -> str:
    """Reads the content of a file."""
    try:
        with open(path, "r") as f:
            return f.read()
    except Exception as e:
        print(f"Error reading file {path}: {e}")
        return ""

def update_file(path: str, content: str):
    """Appends content to an existing file."""
    try:
        with open(path, "a") as f:
            f.write(content)
        print(f"File updated: {path}")
        return True
    except Exception as e:
        print(f"Error updating file {path}: {e}")
        return False

def create_directory(path: str):
    """Creates a directory if it doesn't exist."""
    try:
        os.makedirs(path, exist_ok=True)
        print(f"Directory created: {path}")
        return True
    except Exception as e:
        print(f"Error creating directory {path}: {e}")
        return False
