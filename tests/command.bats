#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

tmp_dir=$(mktemp -d -t codecov-checkout.XXXXXXXXXX)
post_command_hook="$PWD/hooks/post-command"
pre_exit_hook="$PWD/hooks/pre-exit"

function cleanup {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT

setup() {
  export BUILDKITE_BUILD_CHECKOUT_PATH=$tmp_dir
  export BUILDKITE_JOB_ID=0
}

@test "Post-command succeeds" {
  cd "$BUILDKITE_BUILD_CHECKOUT_PATH"

  stub docker \
    "run -e CODECOV_ENV -e CODECOV_TOKEN -e CODECOV_URL -e CODECOV_SLUG -e VCS_COMMIT_ID -e VCS_BRANCH_NAME -e VCS_PULL_REQUEST -e VCS_SLUG -e VCS_TAG -e CI_BUILD_URL -e CI_BUILD_ID -e CI_JOB_ID --label com.buildkite.job-id=${BUILDKITE_JOB_ID} --workdir=/workdir --volume=${BUILDKITE_BUILD_CHECKOUT_PATH}:/workdir -it --rm buildpack-deps:jessie-scm bash -c 'bash <(curl -s https://codecov.io/bash)' : echo Ran Codecov in docker"

  run "$post_command_hook"

  assert_success
  assert_output --partial "Ran Codecov in docker"
}

@test "Pre-exit succeeds" {
  cd "$BUILDKITE_BUILD_CHECKOUT_PATH"

  stub docker \
    "ps -a -q --filter label=com.buildkite.job-id=${BUILDKITE_JOB_ID} : echo my-container" \
    "stop my-container : echo my-container stopped"

  run "$pre_exit_hook"

  assert_success
  assert_output --partial "~~~ Cleaning up left-over container my-container"
  assert_output --partial "my-container stopped"
}
