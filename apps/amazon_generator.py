# apps/amazon_generator.py

import argparse
from pathlib import Path

# We now rely on Poetry to handle the path.
# All imports are clean and at the top.
from toolkit.ai import client as ai_client
from toolkit.amazon import generate_description_from_text
from toolkit.files import operations as file_ops
from toolkit.utils import config


def main():
    """
    CLI tool to generate an Amazon product description from a text file.
    """
    parser = argparse.ArgumentParser(
        description=(
            "Generate an Amazon product description from a text file of features."
        )
    )
    parser.add_argument(
        "input_file", type=str, help="Path to the text file with product features."
    )
    parser.add_argument(
        "output_file",
        type=str,
        nargs="?",
        default="product_description.txt",
        # This 'help' string is now broken into multiple lines to fix E501
        help=(
            "Path to save the generated description "
            "(default: product_description.txt)."
        ),
    )
    args = parser.parse_args()

    try:
        # Load environment variables for API keys
        config.load_dotenv()
        ai_client.configure_gemini()

        print(f"Reading product features from: {args.input_file}")
        features = file_ops.read_text_from_file(Path(args.input_file))

        print("Generating product description with AI...")
        description = generate_description_from_text(features)

        if description:
            print(f"Saving generated description to: {args.output_file}")
            file_ops.save_text_to_file(description, Path(args.output_file))
            print("\n✅ Description generated successfully!")
        else:
            print("\n❌ Failed to generate a description. Check for API errors above.")

    except FileNotFoundError:
        print(f"❌ Error: Input file not found at '{args.input_file}'")
    except Exception as e:
        print(f"\n❌ An unexpected error occurred: {e}")


if __name__ == "__main__":
    main()
