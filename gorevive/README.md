# revive

Bazel rule for Go [revive](https://github.com/mgechev/revive)
linter.

This package provides a single Bazel rule `go_revive_test` which is
intended to be used as a part of your test suite (as opposed to a
regular linting tool).

Since it is just a Bazel test rule it does not modify your working
directory files and can be used in a CI tool to check the code style.

## Setup and usage via Bazel

You can invoke revive via the Bazel rule.

`WORKSPACE` file:
```bzl
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

# revive has to be compiled from sources, hence we need rules_go.
# See https://github.com/bazelbuild/rules_go for the up to date setup instructions.
http_archive(
    name = "io_bazel_rules_go",
)

# go_repository rule is required which is provided by bazel_gazelle.
# See https://github.com/bazelbuild/bazel-gazelle for the up to date setup instructions.
http_archive(
    name = "bazel_gazelle",
)

http_archive(
    name = "com_github_atlassian_bazel_tools",
    strip_prefix = "bazel-tools-<commit hash>",
    urls = ["https://github.com/atlassian/bazel-tools/archive/<commit hash>.zip"],
)

# Load go_revive_dependencies Bazel rule.
load("@com_github_atlassian_bazel_tools//gorevive:deps.bzl", "go_revive_dependencies")

go_revive_dependencies()
```

`BUILD.bazel`:
```bzl
# A simple rule to make the config file available for Bazel rules.
exports_files(["defaults.toml"])

# Go sources needed to be linted.
filegroup(
    name = "go_srcs",
    srcs = glob(["src/*.go"]),
    visibility = ["//visibility:private"],
)

load("@com_github_atlassian_bazel_tools//gorevive:def.bzl", "go_revive_test")

go_revive_test(
    name = "revive_test",
    # Go source files to be linted.
    srcs = [":go_srcs"],
    # Revive .toml config.
    config = "defaults.toml",  # it can also be a regular Bazel label.
    formatter = "stylish",
    # The paths have to be relative to the workspace root.
    paths = ["src/..."],
    # Set debug=True if you need to see the details of the execution of
    # this rule. Default: False.
    debug = True,
)
```

Run as a regular Bazel test:

```bash
bazel run :revive_test
# OR
bazel test :revive_test
```

## Minimal working example

Please, see the `example` directory for a minimal working use-case
example.
