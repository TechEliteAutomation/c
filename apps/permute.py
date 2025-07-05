#!/usr/bin/env python3
#
# Generates all unique permutations of a given string.
# Usage: ./permute.py <string>

import sys
from itertools import permutations


def main():
    """Main execution function."""
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <string_to_permute>", file=sys.stderr)
        sys.exit(1)

    input_str = sys.argv[1]

    # The 'permutations' function returns an iterator of tuples.
    # We use a set comprehension to ensure uniqueness (for inputs with repeated chars)
    # and then join the tuples back into strings.
    perms = {"".join(p) for p in permutations(input_str)}

    # Sort the results for a consistent, predictable output order.
    for p in sorted(list(perms)):
        print(p)


if __name__ == "__main__":
    main()
