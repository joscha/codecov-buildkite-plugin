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
  export BUILDKITE_COMMAND=my-command
  export codecov_command="/tmp/codecov-buildkite-plugin/alpine/latest/codecov"
}

@test "Post-command succeeds" {
  stub docker \
    "run -e CODECOV_ENV -e CODECOV_TOKEN -e CODECOV_URL -e CODECOV_SLUG -e VCS_COMMIT_ID -e VCS_BRANCH_NAME -e VCS_PULL_REQUEST -e VCS_SLUG -e VCS_TAG -e CI_BUILD_URL -e CI_BUILD_ID -e CI_JOB_ID --label com.buildkite.job-id=${BUILDKITE_JOB_ID} --workdir=/workdir --volume=${BUILDKITE_BUILD_CHECKOUT_PATH}:/workdir --volume=/tmp:/tmp -it --rm buildpack-deps:jessie-scm bash -c '${codecov_command} ' : echo Ran Codecov in docker"

  run "$post_command_hook"

  assert_success
  assert_output --partial "Ran Codecov in docker"
}

@test "Post-command succeeds with arguments" {
  export BUILDKITE_PLUGIN_CODECOV_ARGS_0="-v"
  export BUILDKITE_PLUGIN_CODECOV_ARGS_1="-F my_flag"

  stub docker \
    "run -e CODECOV_ENV -e CODECOV_TOKEN -e CODECOV_URL -e CODECOV_SLUG -e VCS_COMMIT_ID -e VCS_BRANCH_NAME -e VCS_PULL_REQUEST -e VCS_SLUG -e VCS_TAG -e CI_BUILD_URL -e CI_BUILD_ID -e CI_JOB_ID --label com.buildkite.job-id=${BUILDKITE_JOB_ID} --workdir=/workdir --volume=${BUILDKITE_BUILD_CHECKOUT_PATH}:/workdir --volume=/tmp:/tmp -it --rm buildpack-deps:jessie-scm bash -c '${codecov_command} -v -F my_flag' : echo Ran Codecov in docker"

  run "$post_command_hook"

  assert_success
  assert_output --partial "Ran Codecov in docker"
}

@test "Post-command succeeds with -Z" {
  export BUILDKITE_PLUGIN_CODECOV_ARGS_0="-Z"

  stub docker \
    "run -e CODECOV_ENV -e CODECOV_TOKEN -e CODECOV_URL -e CODECOV_SLUG -e VCS_COMMIT_ID -e VCS_BRANCH_NAME -e VCS_PULL_REQUEST -e VCS_SLUG -e VCS_TAG -e CI_BUILD_URL -e CI_BUILD_ID -e CI_JOB_ID --label com.buildkite.job-id=${BUILDKITE_JOB_ID} --workdir=/workdir --volume=${BUILDKITE_BUILD_CHECKOUT_PATH}:/workdir --volume=/tmp:/tmp -it --rm buildpack-deps:jessie-scm bash -c '${codecov_command} -Z' : echo Ran Codecov in docker"

  run "$post_command_hook"

  assert_success
  assert_output --partial "Ran Codecov in docker"
}

@test "Post-command is skipped if command failed and skip_on_fail=true" {
  export BUILDKITE_PLUGIN_CODECOV_SKIP_ON_FAIL=true
  export BUILDKITE_COMMAND_EXIT_STATUS=123

  run "$post_command_hook"

  assert_success
  assert_output "Codecov upload is skipped because step failed with status ${BUILDKITE_COMMAND_EXIT_STATUS}"
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
