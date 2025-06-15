# apps/amazon_generator.py

import argparse
from pathlib import Path

# This is the corrected part.
# The import must be from "toolkit" to match the directory name.
from toolkit.ai.client import configure_gemini
from toolkit.amazon import generate_description_from_text

def main():
    """Main function to run the Amazon description generator CLI."""
    try:
        configure_gemini()
    except ValueError as e:
        print(e)
        return

    parser = argparse.ArgumentParser(
        description="Generate an Amazon product description from a text file of features."
    )
    parser.add_argument(
        "input_file",
        type=Path,
        help="Path to the text file containing product features.",
    )
    args = parser.parse_args()

    input_path: Path = args.input_file
    if not input_path.is_file():
        print(f"❌ Error: Input file not found at '{input_path}'")
        return

    print(f"📄 Reading product features from: {input_path}")
    product_features = input_path.read_text()

    print("🤖 Generating description with Gemini... (This may take a moment)")
    description = generate_description_from_text(product_features)

    if description:
        output_path = input_path.parent / f"generated_description_{input_path.stem}.txt"
        output_path.write_text(description)
        print(f"\n✅ Success! Description saved to: {output_path}")
        print("\n--- Generated Description ---")
        print(description)
        print("---------------------------")


if __name__ == "__main__":
    main()
