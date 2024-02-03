cache_filepath() {
  local -r info_dir="$(git rev-parse --git-dir)/info"
  mkdir -p "${info_dir}"
  local -r cache_file="${info_dir}/gcmpb.cache"
  touch "${cache_file}"
  printf '%s' "${cache_file}"
}

cache_file() {
  cat "$(cache_filepath)"
}
