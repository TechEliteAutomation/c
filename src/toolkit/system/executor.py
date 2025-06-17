# src/toolkit/system/executor.py

import subprocess
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
        A subprocess.CompletedProcess object containing the results (stdout, stderr, etc.).

    Raises:
        FileNotFoundError: If the script does not exist at the given path.
        subprocess.CalledProcessError: If the script returns a non-zero exit code.
    """
    script_path_obj = Path(script_path)
    if not script_path_obj.is_file():
        raise FileNotFoundError(f"Script not found at: {script_path_obj}")

    print(f"Executing script: {script_path_obj}...")

    try:
        # The 'check=True' argument will raise CalledProcessError on non-zero exit codes.
        process = subprocess.run(
            ["bash", str(script_path_obj)],
            capture_output=True,
            text=True,
            check=True,
            cwd=str(cwd)
        )

        print(f"Script '{script_path_obj.name}' executed successfully.")
        if process.stdout:
            print(f"--- STDOUT: ---\n{process.stdout.strip()}")
        if process.stderr:
            # Stderr is not always an error; it can be used for progress or info.
            print(f"--- STDERR: ---\n{process.stderr.strip()}")

        return process

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
