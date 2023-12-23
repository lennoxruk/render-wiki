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

homeMD=$(joinPaths "${INPUT_WIKI_PATH}" "$(yq '.wiki.site.home' ${INPUT_WIKI_CONFIG})")

title="$(yq '.wiki.site.title' ${INPUT_WIKI_CONFIG})"
desc="$(yq '.wiki.site.description' ${INPUT_WIKI_CONFIG})"

printf "\n# $title\n\n$desc\n" | tee ${homeMD}

readarray pages < <(yq -o=j -I=0 ".wiki.pages[]" ${INPUT_WIKI_CONFIG})

echo "---"

index=0
for page in "${pages[@]}"; do
  name=$(echo "$page" | yq '.name' -)
  nameMD=$(echo "${name}.md" | sed -r 's/(^|-|_| )([a-z])/\U\2/g')
  pathMD=$(joinPaths "${INPUT_WIKI_PATH}" "${nameMD}")

  # write heading to new markdown page
  printf "# ${name}\n\n" | tee "${pathMD}"

  # write link to home page
  printf "\n[${name}](${nameMD})\n" | tee -a ${homeMD}

  # get list of markdown renders for page
  readarray renderRaw < <(yq -o=j -I=0 ".wiki.pages[${index}].render" ${INPUT_WIKI_CONFIG})
  renderCSV=$(echo "[$renderRaw]" | tr -d "[]")
  readarray -t -s 1 renderList < <(echo $renderCSV | awk -v FPAT='[^,]*|"[^"]*"' '{for (i=0;i<=NF;i++) print $i}')

  echo "page: $name, ${#renderList[@]} items to render"

  for renderItem in "${renderList[@]}"; do
    if jq -e 'keys[0]' >/dev/null 2>&1 <<<"${renderItem}"; then
      # append content from command output
      item=$(echo "${renderItem}" | jq 'keys[0]' | sed -e 's/^"//' -e 's/"$//')
      command=$(echo "${renderItem}" | jq '.[keys_unsorted[0]]' | sed -e 's/^"//' -e 's/"$//')
      makeMarkdownFromCommand "${item}" "${command}" | tee -a ${pathMD}
    else
      # append content from literal markdown
      markdown=$(echo "${renderItem}" | sed -e 's/^"//' -e 's/"$//')
      printf "\n${markdown}\n" | tee -a ${pathMD}
    fi
  done

  echo "---"
  ((index++))
done

echo "wikiHomePath=${homeMD}" >> "$GITHUB_OUTPUT"