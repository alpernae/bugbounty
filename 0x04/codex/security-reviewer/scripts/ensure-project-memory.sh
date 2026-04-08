#!/usr/bin/env bash
set -euo pipefail

memory_file="${1:-memory.md}"
if [[ "$memory_file" != *.md ]]; then
  echo "ERROR: memory filename must end with .md" >&2
  exit 1
fi

start_path="$PWD"
current="$start_path"
project_root=""

while true; do
  if [[ -d "$current/.git" || -f "$current/package.json" || -f "$current/pyproject.toml" || -f "$current/go.mod" || -f "$current/Cargo.toml" || -f "$current/pom.xml" ]]; then
    project_root="$current"
    break
  fi

  parent="$(dirname "$current")"
  if [[ "$parent" == "$current" ]]; then
    project_root="$start_path"
    break
  fi
  current="$parent"
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
template_path="$script_dir/../references/memory-template.md"
github_dir="$project_root/.github"
memory_path="$github_dir/$memory_file"

if [[ ! -f "$template_path" ]]; then
  echo "ERROR: template not found: $template_path" >&2
  exit 1
fi

mkdir -p "$github_dir"

if [[ -f "$memory_path" ]]; then
  echo "MEMORY_EXISTS=$memory_path"
  exit 0
fi

cp "$template_path" "$memory_path"
echo "MEMORY_CREATED=$memory_path"
