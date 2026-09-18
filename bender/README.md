# Bender setup

[Bender](https://github.com/pulp-platform/bender) is a dependency manager and source-list generator for hardware projects. It reads `Bender.yml` manifests to find SystemVerilog sources and their dependencies. A `Bender.lock` file records the exact dependency revisions so repeated setup runs use the same source code.

You do not need to install Bender before running this repository's setup. `setup.sh` calls `bender/install_local.sh` and uses the executable path it prints. This helper owns executable selection and version checking. Without a `BENDER` override, it downloads the pinned Bender release when needed, verifies its checksum, and installs it locally as `bender/bin/bender`. Later runs reuse that executable only if its reported version matches the requested release; otherwise, it is downloaded and installed again. The default release is `0.32.1`; set `BENDER_VERSION` to request a different release. The Bender setup script can also be run directly. The executable is ignored by Git and is not included in the exported benchmark package.

For each selected benchmark, `setup.sh` automatically uses Bender to:

- Check out the dependencies pinned by the design's `Bender.lock`, where present.
- Select sources using the variant's `Bender.yml` and `Bender.args`.
- Trim unreachable source files with `script flist-plus --top`, using the top
  from `flows/targets.mk`.
- Generate the variant-specific SystemVerilog include paths, defines, and source
  file list.
- Copy the referenced sources and HDL/header files from include directories into
  `benchmarks/`, and rewrite the file list to use paths within that export.
  Include directories may contribute files that the selected design does not use.

Some designs have a `bender/<design>/Bender.lock` that pins their shared dependency checkout. Each design's `variants/<variant>/Bender.yml` and `Bender.args` define the sources and Bender arguments used to produce that variant's `filelist.f`.

Wrapper recipes declare `include_dirs` for headers they use from transitive dependencies. `--keep-excluded-incdirs` makes filtered dependencies' headers available to Slang during trimming.

A variant's `filelist.keep` lists source paths relative to its recipe directory. Setup adds these files after trimming if they are not already present. Missing files cause setup to fail.

A variant may also contain `filelist.exclude`. After Bender generates the source list, `setup.sh` removes the dependency-relative paths listed in this file.

The Bender checkout is an intermediate source area. Users of the generated `benchmarks/` directory do not need Bender because each variant contains an independent `filelist.f` referencing only files copied into that directory tree.

Set `BENDER` to use an existing executable instead of the local installation:

```sh
BENDER=/path/to/bender ./setup.sh
```

Setup warns if this executable's version differs from the requested release (`BENDER_VERSION`, default `0.32.1`) or cannot be determined. It continues using the selected executable without replacing it.
