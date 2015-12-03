# python-lama-lint package

## What

A simple python Linter using pylama to provide mccabe, pep8, pyflakes and pep257 with Atom's [linting API](https://github.com/atom-community/linter).

Adds an `E: # W: # I: #` (Error Warnings and Information) indicator to the status bar.


## Why

The Linter package does not differentiate between errors warning and information.
Modern linters can be rather pendantic or excessively informative. The amount of pedantry and information the one may want to pay attention to varies radically with each project.

 * I always want to know if there are errors immediately.
 * In some situations warnings need to be ignored (or dealt with later).
 * I want to know that there are infos but be able to ignore them on minor edits.

The solution is to have a separate indicator for each type of issue.

Ideally I should mod the community Linter package itself, but this felt like a better first Atom package project.

## Status

 * Only lints on save.
 * No configuration options.
 * Requires Pylama to be in path, simply executes pylama on the file in the file's directory.
 * Currently only classifies lint messages starting with `E` or `W` as erros and warnings, everything else is information.  

Todo:
 * Properly differentiate between the types of lint messages that do not start with E or W.
 * Correctly label position of issues on the line (currently defaults to first character on the line).
 * Click to locate erros, warnings or infos.
 * Publish

Done:
 * Learn CoffeeScript (enough anyways) 
 * Write dummy package
 * Test lint message
 * Run pylama
 * Pass pylama messages to linter
 * Status bar E W I indicator
