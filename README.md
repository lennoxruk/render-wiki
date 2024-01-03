# Render Wiki Action

![version](./version.svg)

Simple action to allow rendering of wiki contents in a workflow. Markdown is created in a config file or generated from executable repository or build artifacts.

Useful if there are several executables in a repository which provide usage comments and documentation when executed. By defining these in the wiki config yaml, any usage comments can be self documented in the wiki.

This action currently overwrites the contents of a wiki, it does not clean the folder first.

> TODO:
>
> finish this readme
>
> provide option to clean folder
