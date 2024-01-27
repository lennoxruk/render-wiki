# Render Wiki Action

![version](./version.svg)

Simple action to allow rendering of wiki contents in a workflow. Markdown can be generated from an executable, script, repository, build artifacts or added literally in the wiki config yaml.

Useful if there are several items in a repository which provide usage comments and documentation when executed. By configuring the wiki config yaml, any usage comments or examples can be self documented in the wiki automatically.

Can optionally wipe the wiki folder contents before rendering or add new rendered pages to existing content without wiping.

Developed for use in a Gitea action workflow, the rendering should also work the same way in a Github action workflow.

After the content is rendered, it requires posting to either a Gitea or Github repository wiki. Posting the wiki is out of scope here but an example of using my post-wiki action to post the rendered content folder to a gitea repository is shown in the example workflow below.

## How to use

Create a workflow and create the config file, wiki-config.yaml is the default name but a different name can be used. When invoking the action specify the config file name.

### Workflow example

This example creates the  wiki defined in wiki-config.yaml in the wiki folder and posts it to a wiki's repository managed by Gitea.

First create a workflow file __release.yaml__ within the .gitea/workflows folder.

```yaml
name: Create wiki
on:
  push:
    branches:
      - main

jobs:
  renderAndPost:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout action code
        uses: actions/checkout@v4

      - name: Invoke render-wiki action
        id: renderWiki
        uses: lennoxruk/render-wiki@v1.0

      - name: Invoke post-wiki action
        id: postWiki
        uses: lennoxruk/post-wiki@v1.4

      - name: Show wiki url
        run: echo '🍏 Wiki URL is ${{ steps.postWiki.outputs.wikiUrl }}'
```

> For use on a Github repository, place __release.yaml__ in .github/workflows folder and replace the post wiki action with one that will post the contents of the wiki folder to a Github wiki. __Not tested with Github Actions__

### Example Hello World wiki

This configuration creates a simple hello world wiki in the wiki folder specified by the workflow.
Use the workflow above then create the following yaml in __wiki-config.yaml__ in repository root.

```yaml
wiki:
  home:
    title: Hello World wiki
    render:
      - This is about the world
      - index: page index
      - cool

  pages:
    - title: Hello World
      render: |
        ## Hello

        > World

        ```json
        { hello: "world" }
        ```
```

### Example wiki with content rendered from executables

This configuration creates a wiki rendering various items in the wiki folder specified by the workflow.
Use the workflow above then create the following yaml in __wiki-config.yaml__ in repository root.

```yaml
wiki:
  home:
    name: Home.md
    title: The Example Wiki
    render:
      - Example compound wiki created by executing commands mixed with literal markdown
      - index: page index goes here
      - "Example created at" : date
      - |
        !\u005BMade with RenderWiki\u005D(https://img.shields.io/badge/Made_with-RenderWiki-blue)

  pages:
    - title: Folder Contents
      render:
        - "Executed ls to get folder contents"
        - "Folder contents": "ls -al"

    - title: Some info
      render: This is some really detailed information

    - title: yq and jq help
      render:
        - Rendered content from yq and jq help
        - yq: yq --help
        - jq: jq --help

    - title: ls ps and text
      render:
        - ls: ls --help
        - |
          ### Execute ps
          ps info result
        - "": ps
        - >
          #### footer

    - title: About Wiki 
      render:
        - Created date/time obtained from date command
        - "Created on" : date
```

## Action reference

### Inputs

- __`wikiPath`:__ Path of the folder in which to create the wiki, default: _wiki_

- __`wikiConfig`:__ Wiki config yaml path, default: _wiki-config.yaml_

- __`wipeWiki`:__ Remove existing content before render, default: _'false'_

- __`pagesOnly`:__ Only render pages and omit home page, default: _'false'_

### Outputs

- __`wikiHomePath`:__ Path to home markdown

## Wiki configuration yaml

The configuration yaml should contain a wiki dictionary consisting of a home dictionary with one page definition and a pages dictionary containing any number of page definitions.

Page definitions consist of a title and a list of items to render on that page. The page file name is automatically created from the title.

To render a wiki with a home page and other pages, create wiki a dictionary, add the home dictionary and then define the pages dictionary. A link to each page can be placed in the home page as an index. This is a simple example:

```yaml
wiki:
  home:
    name: Home.md
    title: Example wiki
    render:
      - This is an example home page
      - index: page index
      - |
        !\u005BMade with RenderWiki\u005D(https://img.shields.io/badge/Made_with-RenderWiki-blue)

  pages:
    - title: Hello World
      render: |
        ## Hello

        World
```

> Yaml special characters like square brackets, cannot be placed literally in yaml strings. This makes rendering some markdown, like image links, a bit tricky. The unicode character equivalent can be used to specify special characters as shown in the example.

### wiki.home dictionary

Home dictionary consists of an optional name, title and list of content to render.

key | desc
--- | ---
name | Home filename, default is Home.md
title | Home page title. Appears at top of page.
render | List of content to render. Each entry can be either literal markdown or key/command pair.

Content from key/command is rendered as a _plaintext_ code block. The key will appear as the command output title above the rendered content. If the key is an empty string the command output title will not be rendered.

To position a page index within the home page, use special render key/command ignored, ```index: page index```. This can be placed anywhere within the home render list; see examples.

### wiki.pages dictionary

Pages dictionary consists of a list of pairs of titles and list of content to render.

key | desc
--- | ---
title | Page title. Appears at top of page.
render | List of content to render. Each entry can be either literal markdown or key/command pair.

Content from key/command is rendered as a _plaintext_ code block. The key will appear as the command output title above the rendered content. If the key is an empty string the command output title will not be rendered.
