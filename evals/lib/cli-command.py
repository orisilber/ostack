#!/usr/bin/env python3
"""Tokenize a documented command without consuming flags from its pipeline."""
import shlex
import sys


def arguments(line):
    lexer = shlex.shlex(line, posix=True, punctuation_chars="|&;<>")
    lexer.whitespace_split = True
    result = []
    for token in lexer:
        if token and all(character in "|&;<>" for character in token):
            break
        result.append(token)
    return result


if __name__ == "__main__":
    print(shlex.join(arguments(sys.stdin.read())))
