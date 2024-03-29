<!-- omit from toc -->
# Render Wiki Action

![version](./version.svg)

Simple action to allow rendering of wiki contents in a workflow. Markdown can be generated from an executable, script, repository, build artifacts and/or added literally using the wiki config yaml.

- [How to use](#how-to-use)
- [Action reference](#action-reference)
- [Wiki configuration yaml](#wiki-configuration-yaml)

This is useful if there are several executable items available in a repository or workflow which provide usage comments and documentation when executed. By configuring the wiki config yaml, any usage comments or examples can be self documented in the wiki automatically.

Can optionally wipe the wiki folder contents before rendering or add new rendered pages to existing content without wiping.

Developed for use in a Gitea action workflow, the rendering should also work the same way in a Github action workflow but has not been tested on Github.

After the content is rendered, it requires posting to either a Gitea or Github repository wiki. Posting the wiki is out of scope here but an example of using my Gitea post-wiki action to post the rendered content folder to a Gitea repository is shown in the example workflow below.

## How to use

Create a workflow and create the config file, wiki-config.yaml is the default name but a different name can be used. When invoking the action specify the config file name.

<!-- omit from toc -->
### Workflow example

This example creates the wiki defined in wiki-config.yaml in the wiki folder and posts it to a wiki's repository managed by Gitea.

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
        uses: lennoxruk/render-wiki@v1.3

      - name: Invoke post-wiki action
        id: postWiki
        uses: lennoxruk/post-wiki@v1.5

      - name: Show wiki url
        run: echo '🍏 Wiki URL is ${{ steps.postWiki.outputs.wikiUrl }}'
```

> For use on a Github repository, place __release.yaml__ in .github/workflows folder and replace the post wiki action with one that will post the contents of the wiki folder to a Github wiki. __Not tested with Github Actions__

<!-- omit from toc -->
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
      - badge: Hello-World

  pages:
    - title: Hello World
      render: |
        ## Hello

        > World

        ```json
        { hello: "world" }
        ```
```

<!-- omit from toc -->
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
      - badge: Generated_with-RenderWiki-pink

  pages:
    - title: Folder Contents
      render:
        - "Executed ls to get folder contents"
        - "Folder contents": "ls -al"

    - title: Some info
      render: This is some really detailed information

    - title: yq and jq help
      columns: 30
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

    - title: google link
      render: |
          ## Google link
          \u005BGoogle\u005D(https://google.com)

    - title: About Wiki 
      render:
        - Created date/time obtained from date command
        - "Created on" : date
```

## Action reference
<!-- action-docs-inputs -->
<!-- omit from toc -->
### Inputs

| parameter  | description                                    | required | default          |
|------------|------------------------------------------------|----------|------------------|
| wikiPath   | Path of the folder in which to create the wiki | `false`  | wiki             |
| wikiConfig | Wiki config yaml path                          | `false`  | wiki-config.yaml |
| wipeWiki   | Remove existing content before render          | `false`  | false            |
| pagesOnly  | Only render pages and omit home page           | `false`  | false            |
<!-- action-docs-inputs -->
<!-- action-docs-outputs -->
<!-- omit from toc -->
### Outputs

| parameter    | description           |
|--------------|-----------------------|
| wikiHomePath | Path to home markdown |
<!-- action-docs-outputs -->
<!-- omit from toc -->
### Runs

This action requires `linux`.

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
      - badge: Generated_with-RenderWiki-red

  pages:
    - title: Hello World
      render: |
        ## Hello

        World
      - |
        \u005BGoogle\u005D(https://google.com)
```

> Yaml special characters like square brackets, cannot be placed literally in yaml strings. This makes rendering some markdown, like image links, a bit tricky. The unicode character equivalent can be used to specify special characters as shown in the example.

<!-- omit from toc -->
### wiki.home dictionary

Home dictionary consists of an optional name, title and list of content to render.

| key     | description                                                                     |
|---------|---------------------------------------------------------------------------------|
| name    | Home filename, default is Home.md                                               |
| title   | Home page title which appears as the main page heading.                         |
| render  | List of content to render. See [rendered list content](#rendered-list-content). |
| columns | Terminal column character width. Default: 150                                   |

To position a page index within the home page, use special render key/value, ```index: page index```. This can be placed anywhere within the home render list; see examples.

<!-- omit from toc -->
### wiki.pages dictionary

Pages dictionary consists of a list of pairs of titles and list of content to render.

| key     | description                                                                                                                  |
|---------|------------------------------------------------------------------------------------------------------------------------------|
| title   | Page title which appears as the main page heading. Used to form the filename of the page so value must be unique.            |
| render  | List of content to render. See [rendered list content](#rendered-list-content). If not present then no page will be created. |
| columns | Terminal column character width. Default: 150                                                                                |

<!-- omit from toc -->
### rendered list content

Non key/value pair list items are rendered as literal markdown.

Special key/values from the following table are rendered as specified. If key is not in the table below then the value will be executed as a shell command.

| key   | value         | description                                                                                                    |
|-------|---------------|----------------------------------------------------------------------------------------------------------------|
| index | n/a           | List of sub pages/index on Home page. Cannot use on subpages, only for home page.                              |
| badge | badge content | Static badge using [Shields IO](https://shields.io/badges). Format: prefix-suffix-colour, default colour: blue |

Content from key/command is rendered as a _plaintext_ code block. The command is executed and the output captured. The key will appear as the command output title above the rendered content. If the key is an empty string the command output title will not be rendered.
