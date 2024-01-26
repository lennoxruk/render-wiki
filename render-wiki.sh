#!/bin/bash

set -Euo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
}

joinPaths() {
  local basePath=${1}
  local subPath=${2}
  local fullPath="${basePath:+$basePath/}$subPath"
  printf "${fullPath}"
}

renderMarkdownFromCommand() {
  printf "\n## $1\n\n"'```plaintext'"\n$($2)\n"'```'"\n"
}

renderItem() {
  local item=${1-}
  if jq -e 'keys[0]' >/dev/null 2>&1 <<<"${item}"; then
    local itemName=$(echo "${item}" | jq 'keys[0]' | sed -e 's/^"//' -e 's/"$//')

    case "${itemName-}" in
    index)
      # output page index
      printf "${renderPagesIndex}"
      ;;
    *)
      # output content from command
      local command=$(echo "${item}" | jq '.[keys_unsorted[0]]' | sed -e 's/^"//' -e 's/"$//')
      renderMarkdownFromCommand "${itemName}" "${command}"
      ;;
    esac
  else
    # output literal markdown
    local markdown=$(echo -ne "${item}" | sed -e 's/^"//' -e 's/"$//')
    printf "\n${markdown}\n"
  fi
}

renderItems() {
  local yamlPath="${1-}"
  local outputFilePath="${2-}"

  # get list of markdown renders
  local renderRaw
  readarray renderRaw < <(yq -o=j -I=0 "${yamlPath}" ${INPUT_WIKI_CONFIG})
  local renderCSV=$(echo "[$renderRaw]" | tr -d "[]")
  local renderList
  readarray -t -s 1 renderList < <(echo $renderCSV | awk -v FPAT='[^,]*|"[^"]*"' '{for (i=0;i<=NF;i++) print $i}')

  # render page markdown items
  echo "${#renderList[@]} items to render"
  local item
  for item in "${renderList[@]}"; do
    [ "${item-}" = 'null' ] && continue
    renderItem "${item}" | tee -a ${outputFilePath}
  done
}

#### start ####

[ -z "${INPUT_WIKI_PATH-}" ] && echo "No wiki path given" && exit 1
[ -z "${INPUT_WIKI_CONFIG-}" ] && echo "No wiki config yaml given" && exit 1
[ ! -f "${INPUT_WIKI_CONFIG-}" ] && echo "No wiki config yaml found" && exit 1

# create wiki folder if it does not exist
mkdir -p "${INPUT_WIKI_PATH}"

# optionally wipe folder
[ $INPUT_WIPE_WIKI = 'true' ] && rm -rf "${INPUT_WIKI_PATH}"/*

homePagePath='null'
if [ ! $INPUT_PAGES_ONLY = 'true' ]; then
  homePageName=$(yq '.wiki.home.name // "Home.md"' ${INPUT_WIKI_CONFIG})
  homePagePath=$(joinPaths "${INPUT_WIKI_PATH}" "${homePageName}")

  title="$(yq '.wiki.home.title' ${INPUT_WIKI_CONFIG})"
  printf "# ${title-}\n" | tee ${homePagePath}
fi

readarray pages < <(yq -o=j -I=0 ".wiki.pages[]" ${INPUT_WIKI_CONFIG})

echo "---"

renderPagesIndex=''
pageCounter=0

for page in "${pages[@]}"; do
  title=$(echo "${page}" | yq '.title // "null"' -)

  [ $title = 'null' ] && echo 'Cannot render page without title' && continue
  echo "rendering page: ${title}"

  pageName=$(echo "${title}.md" | sed -r 's/(^|-|_| )([a-zA-Z0-9])/\U\2/g')
  pagePath=$(joinPaths "${INPUT_WIKI_PATH}" "${pageName}")

  # write heading to new markdown page
  printf "# ${title}\n" | tee "${pagePath}"

  # render home page pages index/list
  renderPagesIndex="${renderPagesIndex}"'\n'$(printf "[${title}](${pageName})")'\n'

  # write page renders
  renderItems ".wiki.pages[${pageCounter}].render" "${pagePath}"

  echo "---"
  ((pageCounter++))
done

[ ! $INPUT_PAGES_ONLY = 'true' ] && renderItems '.wiki.home.render' "${homePagePath}"

echo "wikiHomePath=${homePagePath}" >>"$GITHUB_OUTPUT"
