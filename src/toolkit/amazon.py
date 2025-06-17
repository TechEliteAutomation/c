# src/toolkit/amazon.py

import google.generativeai as genai

# The core logic for generating an Amazon product description.
# This is now a reusable function, completely separate from the UI.


def generate_description_from_text(
    product_info: str, model_name: str = "gemini-1.5-flash"
) -> str:
    """
    Generates an Amazon product description using the Gemini API.

    Args:
        product_info: A string containing the raw features and details of the product.
        model_name: The specific Gemini model to use for the generation.

    Returns:
        The generated product description as a string.
    """
    model = genai.GenerativeModel(model_name)

    prompt = f"""
    Based on the following product features and details, write a compelling and
    professional Amazon product description.
    The description should be engaging, easy to read, and highlight the key
    benefits for the customer.
    Use clear headings and bullet points where appropriate.

    Product Details:
    ---
    {product_info}
    ---
    """

    try:
        response = model.generate_content(prompt)
        return response.text
    except Exception as e:
        # Catch potential API errors, like content filtering.
        print(f"❌ An error occurred during API call: {e}")
        # Return an empty string or re-raise to let the caller handle it.
        return ""
