"""
Simple script module that replaces a string by another in a given file
"""
import sys
import re


def file_replace(filepath, old, new):
    """
    Replace a string by another
    """
    with open(filepath, 'r') as fin:
        content = fin.read()
    content = re.sub(old, new, content)
    with open(filepath, 'w') as fout:
        fout.write(content)

if __name__ == '__main__':
    file_replace(*sys.argv[1:])
