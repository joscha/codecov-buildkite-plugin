#!/bin/bash
set -euo pipefail

get_os() {
  local OS=`uname -s`

  if [ "${OS}" = "Linux" ] ; then
    if [ -f /etc/alpine-release ] ; then
      echo "alpine"
      return
    fi
    echo "linux"
    return

  elif [ "${OS}" == "Darwin" ]; then
    echo "macos"
    return
  fi

  echo $(uname -a)
}

OS=$(get_os)
CODECOV_VERSION="${BUILDKITE_PLUGIN_CODECOV_UPLOADER_VERSION:-latest}"
TMP_DIR="${BUILDKITE_PLUGIN_CODECOV_TMP_DIR:-/tmp}/codecov-buildkite-plugin/${OS}/${CODECOV_VERSION}"

# Reads a list from plugin config into a global result array
# Returns success if values were read
plugin_read_list_into_result() {
  result=()

  for prefix in "$@" ; do
    local i=0
    local parameter="${prefix}_${i}"

    if [[ -n "${!prefix:-}" ]] ; then
      echo "🚨 Plugin received a string for $prefix, expected an array" >&2
      exit 1
    fi

    while [[ -n "${!parameter:-}" ]]; do
      result+=("${!parameter}")
      i=$((i+1))
      parameter="${prefix}_${i}"
    done
  done

  [[ ${#result[@]} -gt 0 ]] || return 1
}

get_codecov_uploader() {
  if [ "${OS}" = "alpine" ] || [ "${OS}" = "linux" ] || [ "${OS}" = "macos" ]; then
    if [ "${OS}" = "alpine" ]; then
      apk add gnupg
    fi
    curl https://keybase.io/codecovsecurity/pgp_keys.asc | gpg --no-default-keyring --keyring trustedkeys.gpg --import # One-time step
    for file in codecov codecov.SHA256SUM codecov.SHA256SUM.sig
    do
      if [[ ! -e "${TMP_DIR}/${file}" ]]; then
        echo "${TMP_DIR}/${file}"
        echo "https://uploader.codecov.io/${CODECOV_VERSION}/${OS}/${file}"
        curl -s --create-dirs -o "${TMP_DIR}/${file}" "https://uploader.codecov.io/${CODECOV_VERSION}/${OS}/${file}"
      fi
    done

    (
      cd "${TMP_DIR}"
      gpgv codecov.SHA256SUM.sig codecov.SHA256SUM
      if [ "${OS}" = "macos" ]; then
        shasum -a 256 -c codecov.SHA256SUM
      else
        sha256sum -c codecov.SHA256SUM
      fi
      chmod +x codecov
    )
    return
  fi

  # Support for other OS such as windows will have to be implemented if needed
  echo "Your platform (${OS}) is not supported."
  exit 1
}
