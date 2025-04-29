# Docker Codecov Buildkite Plugin

An [Buildkite plugin](https://buildkite.com/docs/agent/v3/plugins) for running [Codecov](https://docs.codecov.io/docs/testing-with-docker).

It contains a [post-command hook](hooks/command), and [tests](tests/command.bats) using [plugin-tester](https://github.com/buildkite-plugins/plugin-tester).

## Example

```yml
steps:
  - plugins:
      - joscha/codecov#v4.0.2: ~
```

The shell option can be used to forward parameters to the codecov invocation.

```yml
steps:
  - plugins:
      - joscha/codecov#v4.0.2:
          args:
            - "-v"
            - "-F my_flag"
```

In case you do not want to upload coverage results after a failed `command` step:

```yml
steps:
  - plugins:
      - joscha/codecov#v4.0.2:
          skip_on_fail: true
```

By default it will use the bundled PGP key to verify the downloaded binary, but you can override the URL via:

```yml
steps:
  - plugins:
      - joscha/codecov#v4.0.2:
          pgp_public_key_url: https://keybase.io/codecovsecurity/pgp_keys.asc
```

Here's a complete example:

```yml
steps:
  - plugins:
    joscha/codecov#v4.0.2:
      skip_on_fail: true
      args:
        - "--auto-load-params-from=Buildkite"
        - "--verbose"
        - "upload-process"
        - "-F $$BUILDKITE_JOB_ID" # $$ if you have parallel steps (to get the runtime value) otherwise $
        - "-r $BUILDKITE_ORGANIZATION_SLUG/$BUILDKITE_PIPELINE_NAME"
        - "--git-service=$BUILDKITE_PIPELINE_PROVIDER"
      docker_image: "public.ecr.aws/docker/library/buildpack-deps:noble-scm"
      cli_version: v0.7.5
```

## Tests

To run the tests of this plugin, run

```sh
docker compose run --rm tests
```

## License

MIT (see [LICENSE](LICENSE))
