load("@bazel_skylib//lib:shell.bzl", "shell")
load("@bazel_skylib//lib:paths.bzl", "paths")
load("@io_bazel_rules_go//go:def.bzl", "GoSDK")

def _golangcilint_impl(ctx):
    args = []
    if ctx.attr.config:
        args.append("--config={}".format(ctx.file.config.short_path))
    else:
        args.append("--no-config")
    args.extend(ctx.files.paths)
    sdk = ctx.attr._go_sdk[GoSDK]
    substitutions = {
        "@@GOLANGCILINT_SHORT_PATH@@": shell.quote(ctx.executable._golangcilint.short_path),
        "@@ARGS@@": shell.array_literal(args),
        "@@PREFIX_DIR_PATH@@": shell.quote(paths.dirname(ctx.attr.prefix)),
        "@@PREFIX_BASE_NAME@@": shell.quote(paths.basename(ctx.attr.prefix)),
        "@@NEW_GOROOT@@": shell.quote(sdk.root_file.dirname),
    }
    ctx.actions.expand_template(
        template = ctx.file._runner,
        output = ctx.outputs.executable,
        substitutions = substitutions,
        is_executable = True,
    )
    transitive_depsets = [
        depset(sdk.srcs),
        depset(sdk.tools),
        depset(sdk.libs),
        depset(sdk.headers),
        depset([sdk.go]),
    ]
    default_runfiles = ctx.attr._golangcilint[DefaultInfo].default_runfiles
    if default_runfiles != None:
        transitive_depsets.append(default_runfiles.files)

    runfiles = ctx.runfiles(
        files = ctx.files.paths,
        transitive_files = depset(transitive = transitive_depsets),
    )
    return [DefaultInfo(runfiles = runfiles,)]

golangcilint_test = rule(
    implementation = _golangcilint_impl,
    attrs = {
        "config": attr.label(
            allow_single_file = True,
            doc = "Configuration file to use",
        ),
        "paths": attr.label_list(
            doc = "Files to lint.",
            allow_files = [".go"],
        ),
        "prefix": attr.string(
            mandatory = True,
            doc = "Go import path of this project i.e. where in GOPATH you would put it. E.g. github.com/atlassian/bazel-tools",
        ),
        "deps": attr.label_list(
            mandatory = False,
            doc = "Other Bazel targets this target depends upon.",
        ),
        "_golangcilint": attr.label(
            default = "@com_github_atlassian_bazel_tools_golangcilint//:linter",
            cfg = "host",
            executable = True,
        ),
        "_runner": attr.label(
            default = "@com_github_atlassian_bazel_tools//golangcilint:runner.bash.template",
            allow_single_file = True,
        ),
        "_go_sdk": attr.label(
            providers = [GoSDK],
            default = "@go_sdk//:go_sdk",
        ),
    },
    test = True,
)
