# Docker Codecov Buildkite Plugin

An [Buildkite plugin](https://buildkite.com/docs/agent/v3/plugins) for running [Codecov](https://docs.codecov.io/docs/testing-with-docker).

It contains a [post-command hook](hooks/command), and [tests](tests/command.bats) using [plugin-tester](https://github.com/buildkite-plugins/plugin-tester).

## Example

```yml
steps:
  - plugins:
      - joscha/codecov#v3.0.0: ~
```

The shell option can be used to forward parameters to the codecov invocation.
```yml
steps:
  - plugins:
      - joscha/codecov#v3.0.0:
          args:
            - '-v'
            - '-F my_flag'
```

In case you do not want to upload coverage results after a failed `command` step:

```yml
steps:
  - plugins:
      - joscha/codecov#v3.0.0:
          skip_on_fail: true
```

## Tests

To run the tests of this plugin, run
```sh
docker-compose run --rm tests
```

## License

MIT (see [LICENSE](LICENSE))
