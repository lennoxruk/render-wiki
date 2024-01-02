#!/bin/bash

set -Euo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

cleanup() {
  trap - SIGINT SIGTERM ERR EXIT
}

joinPaths() {
  basePath=${1}
  subPath=${2}
  fullPath="${basePath:+$basePath/}$subPath"
  printf "${fullPath}"
}

makeMarkdownFromCommand() {
  printf "## $1\n\n"'```plaintext'"\n$($2)\n"'```'"\n"
}

#### start ####

[ -z "${INPUT_WIKI_PATH-}" ] && echo "No wiki path given" && exit 1
[ -z "${INPUT_WIKI_CONFIG-}" ] && echo "No wiki config yaml given" && exit 1
[ ! -f "${INPUT_WIKI_CONFIG-}" ] && echo "No wiki config yaml found" && exit 1

# create wiki folder if it does not exist
mkdir -p "${INPUT_WIKI_PATH}"

#TODO: provide option to optionally clean folder
#rm -rf "${INPUT_WIKI_PATH}"/*

homePageName=$(yq '.wiki.site.home // "Home.md"' ${INPUT_WIKI_CONFIG})
homePagePath=$(joinPaths "${INPUT_WIKI_PATH}" "${homePageName}")

title="$(yq '.wiki.site.title' ${INPUT_WIKI_CONFIG})"
narrative="$(yq '.wiki.site.narrative' ${INPUT_WIKI_CONFIG})"

printf "\n# $title\n\n$narrative\n" | tee ${homePagePath}

readarray pages < <(yq -o=j -I=0 ".wiki.pages[]" ${INPUT_WIKI_CONFIG})

echo "---"

index=0
for page in "${pages[@]}"; do
  title=$(echo "${page}" | yq '.title // "none"' -)

  [[ $title = 'none' ]] && echo 'Cannot render page without title' && continue

  pageName=$(echo "${title}.md" | sed -r 's/(^|-|_| )([a-z])/\U\2/g') | sed -r 's/ //g'
  pagePath=$(joinPaths "${INPUT_WIKI_PATH}" "${pageName}")

  # write heading to new markdown page
  printf "# ${title}\n\n" | tee "${pagePath}"

  # write link to home page
  printf "\n[${title}](${pageName})\n" | tee -a ${homePagePath}

  # get list of markdown renders for page
  readarray renderRaw < <(yq -o=j -I=0 ".wiki.pages[${index}].render" ${INPUT_WIKI_CONFIG})
  renderCSV=$(echo "[$renderRaw]" | tr -d "[]")
  readarray -t -s 1 renderList < <(echo $renderCSV | awk -v FPAT='[^,]*|"[^"]*"' '{for (i=0;i<=NF;i++) print $i}')

  echo "page: $title, ${#renderList[@]} items to render"

  for renderItem in "${renderList[@]}"; do
    if jq -e 'keys[0]' >/dev/null 2>&1 <<<"${renderItem}"; then
      # append content from command output
      itemName=$(echo "${renderItem}" | jq 'keys[0]' | sed -e 's/^"//' -e 's/"$//')
      command=$(echo "${renderItem}" | jq '.[keys_unsorted[0]]' | sed -e 's/^"//' -e 's/"$//')
      makeMarkdownFromCommand "${itemName}" "${command}" | tee -a ${pagePath}
    else
      # append content from literal markdown
      markdown=$(echo "${renderItem}" | sed -e 's/^"//' -e 's/"$//')
      printf "\n${markdown}\n" | tee -a ${pagePath}
    fi
  done

  echo "---"
  ((index++))
done

echo "wikiHomePath=${homePagePath}" >> "$GITHUB_OUTPUT"