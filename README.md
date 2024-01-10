# Render Wiki Action

![version](./version.svg)

Simple action to allow rendering of wiki contents in a workflow. Markdown can be generated from an executable, script, repository, build artifacts or added literally in the wiki config yaml.

Useful if there are several items in a repository which provide usage comments and documentation when executed. By configuring the wiki config yaml, any usage comments or examples can be self documented in the wiki.

This action currently overwrites the contents of a wiki folder, it does not clean the folder first.

## How to use

Create a wiki-config.yaml

### Hello world example

This creates a simple hello world wiki in wiki folder and posts to Gitea wiki for its repository.

For a Gitea repository, create __release.yaml__ in .gitea/workflows folder. For use on a Github repository, put __release.yaml__ in .github/workflows folder and replace the post wiki action with one that will post the wiki folder contents to a Github wiki.

```yaml
name: Create Hello World wiki
on:
  push:
    branches:
      - main

jobs:
  renderTest:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout action code
        uses: actions/checkout@v4

      - name: Invoke render-wiki action
        id: renderWiki
        uses: lennoxruk/render-wiki@v1.0

      - name: Invoke post-wiki action
        id: postWiki
        uses: lennoxruk/post-wiki@v1

      - name: Show wiki url
        run: echo '🍏 Wiki URL is ${{ steps.postWiki.outputs.wikiUrl }}'
```

Create __wiki-config.yaml__ in repository root.

```yaml
wiki:
  home:
    title: Hello World wiki
    narrative: |
      This is about the world

  pages:
    - title: Hello World
      render: |
        ## Hello

        > World

        ```json
        { hello: "world" }
        ```
```

## Inputs

- __`wikiPath`:__ Path of the folder in which to create the wiki, default _wiki_

- __`wikiConfig`:__ Wiki config yaml path, default _wiki-config.yaml_

## Outputs

- __`wikiHomePath`:__ Path to home markdown

## Wiki config yaml

Define home page details and then add the pages. A link to each page is appended to the home page.

### home

key | desc
--- | ---
name | Home filename, default Home.md
title | Title text
narrative | Narrative text

### pages

key | desc
--- | ---
title | Page title
render | Content to render

Page render examples

Simple hello page

```yaml
- title: Hello
  render: |
  ## Hello
```

Compound page with content from executables

```yaml
- title: ls ps and text
  render:
    - ls: ls --help
    - |
      ### Execute ps
      ps info result
    - "ps": ps
    - >
      #### footer
```
