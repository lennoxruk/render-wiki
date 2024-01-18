# Render Wiki Action

![version](./version.svg)

Simple action to allow rendering of wiki contents in a workflow. Markdown can be generated from an executable, script, repository, build artifacts or added literally in the wiki config yaml.

Useful if there are several items in a repository which provide usage comments and documentation when executed. By configuring the wiki config yaml, any usage comments or examples can be self documented in the wiki.

This action currently overwrites the contents of a wiki folder, it does not clean the folder first.

Developed for use with Gitea actions.

## How to use

Create a wiki-config.yaml and include in workflow.

### Hello world example

This creates a simple hello world wiki in the wiki folder and posts it to a wiki's repository managed by a Gitea.

Create the below workflow in file __release.yaml__ within the .gitea/workflows folder.

For use on a Github repository, put __release.yaml__ in .github/workflows folder and replace the post wiki action with one that will post the contents of the wiki folder to a Github wiki. __Not tested with Github__

```yaml
name: Create Hello World wiki
on:
  push:
    branches:
      - main

jobs:
  renderHelloWiki:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout action code
        uses: actions/checkout@v4

      - name: Invoke render-wiki action
        id: renderWiki
        uses: lennoxruk/render-wiki@v0.2

      - name: Invoke post-wiki action
        id: postWiki
        uses: lennoxruk/post-wiki@v1.4

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
name | Home filename, default is Home.md
title | Title text of page
narrative | Narrative markdown

### pages

key | desc
--- | ---
title | Page title
render | Content to render, can be markdown or key value pair, key is the title and value is the command that will create some markdown or text

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
