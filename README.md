# PULP benchmark suite

This repository prepares and exports RTL files of PULP and some external designs with minimalistic synthesis flows and top-level simulation testbenches.


## Get started

Download the prepared benchmark tarball from the release's **Assets** on GitHub's [Releases page](../../releases). Extract it and run the commands below from the `pulp-benchmarks-v<version>/` directory. Automatic source-code archives do not contain the prepared RTL. Generating from source is not necessary for normal use.

<details>
<summary>Generate from source</summary>

Generating from source requires Linux with Bash 4 or newer, Git, and GNU utilities. Automatic Bender installation additionally requires curl, tar with xz support, and a SHA-256 utility. To install the prerequisites for all benchmarks on Ubuntu:

```sh
sudo apt-get install bash build-essential ca-certificates cmake coreutils curl findutils \
  autoconf automake bison flex gawk git libgmp-dev libmpfr-dev libmpc-dev \
  libxml-simple-perl openjdk-17-jre-headless perl python3 \
  python3-venv sed tar xz-utils
```

Generation and test preparation require Java 17, Perl with `XML::Simple`, Make, GCC/G++, cpp, CMake 3.24 or newer, and Python 3.10 or newer with `venv` and pip (Python 3.11 or newer for Snitch). Java is selected through `JAVA`, `JAVA_HOME/bin/java`, or `java` from `PATH`, in that order. Set `PYTHON` to select the Python interpreter; setup creates virtual environments for Python dependencies as needed.

From a Git clone of this repository, generate every benchmark with:

```sh
./setup.sh
```

To collect only one variant, pass its target name:

```sh
./setup.sh ibex.minimal
```

The collected, self-contained RTL package is written to `benchmarks/`. If that directory already exists, `setup.sh` leaves it unchanged and exits with an error code. `setup.sh` initializes only the design submodules in `deps/` needed by the selected benchmarks, checks out locked dependencies, applies the required source patches, and generates relocatable file lists. Hardware patches applied during setup live in this repository's `patches/` directory, including copies of required upstream patches.

A custom dependency management tool, Bender, is used. It is set up locally by `setup.sh`, so no separate Bender installation is required. The Bender recipes and automatic dependency/filelist flow are described in [`bender/README.md`](bender/README.md).

Simulation preparation is enabled by default. For each selected design, root setup runs `testbenches/<design>/setup.sh` to prepare firmware, verification sources, and test data before export. Use `SIMULATION=0 ./setup.sh [design.variant]` to export synthesis sources only. Compiler installers under `testbenches/<design>/tools/` pin the firmware toolchains. They reuse the corresponding versioned compiler on `PATH`, or download/build it when absent. `JOBS` controls build parallelism and defaults to 1. Setup retains build tools and virtual environments unless `KEEP_BUILD_TOOLS=0` is set.


## Repository layout

```text
deps/        upstream design repositories pinned through git submodule
bender/      variant-specific Bender recipes and dependency locks
patches/     source patches applied while preparing benchmarks
support/     shared RTL stubs
flows/       flow files
testbenches/ simulation preparation scripts and support files
```

Prepared RTL, headers, variant-specific file lists, constraints, and flow scripts are written to the `benchmarks/` directory. Change directory to the `benchmarks/` directory to run the flows.

</details>

<!-- BEGIN DISTRIBUTION README -->

## Package layout

```text
<design>/
  main/                         primary upstream source tree
  dependencies/                 dependency source trees
  support/                      RTL stubs
  data/                         shared simulation support and test data
  variants/<variant>/
    *.sv                        benchmark top/wrapper sources
    <technology>/default.sdc    technology-specific constraints
    <technology>/yosys.tcl      technology-specific Yosys synthesis flow
    yosys-slang.args            Slang options shared by Yosys flows (optional)
    filelist.f                  file paths
    data/                       variant-specific simulation support and test data
    verilator/<testbench>/      simulation file list and test settings
targets.mk                      target list
testbenches.mk                  testbench tops for exported simulation tests
tools/install-verilator.sh      optional installer for the design’s pinned simulator
Makefile                        flow entry point
common/
  backup.sh                     timestamped output backups
  elaborate.sh                  Yosys elaboration launcher
  elaborate.tcl                 Yosys elaboration flow
  yosys.sh                      Yosys synthesis launcher
  yosys.tcl                     Yosys synthesis flow helpers
  verilator.sh                  Verilator build and simulation launcher
technologies/<technology>/
  technology/                   user-provided technology collateral
  yosys/setup.tcl               technology-specific Yosys setup
LICENSE                         license and third-party notice
```


## Included designs

Cell counts are approximate estimates. Clock periods are approximate synthesis targets for ASAP7 recorded in the included SDC files, not measured or guaranteed achieved frequencies. The ASAP7 SDC files express time values in picoseconds; the table shows clock periods in nanoseconds. Clock periods marked `TBD` are to be determined, and the corresponding SDC values are provisional.

| Design         | Variant         | Cell count | Clock period | Description                                             |
| -------------- | --------------- | ---------: | -----------: | ------------------------------------------------------- |
| Ara            | `default`       |         1M |       1.0 ns | RISC-V vector accelerator.                              |
| Cheshire       | `default`       |       500k |       1.0 ns | Linux-capable RISC-V SoC built around CVA6.             |
| CV32E40P       | `default`       |        20k |       1.0 ns | Compact 32-bit embedded RISC-V core.                    |
| CVA6           | `default`       |       200k |       1.0 ns | 64-bit application-class RISC-V core.                   |
| CVFPU          | `fp32_fma`      |        10k | (I/O) 1.5 ns | FP32 fused multiply-add datapath (combinational).       |
| CVFPU          | `full`          |       200k |       2.0 ns | Multi-format floating-point unit.                       |
| Ibex           | `minimal`       |        20k |       1.0 ns | Compact 32-bit RISC-V core configuration.               |
| Ibex           | `full`          |       500k |       1.0 ns | Feature-rich 32-bit RISC-V core configuration.          |
| ITA            | `default`       |       500k |       1.0 ns | Integer transformer-attention accelerator.              |
| MemPool        | `minpool`       |         1M |       3.0 ns | Shared-L1 many-core system with 16 RISC-V cores.        |
| MemPool        | `mempool`       |        10M |          TBD | Shared-L1 many-core system with 256 RISC-V cores.       |
| MemPool        | `terapool`      |        50M |          TBD | Shared-L1 many-core system with 1024 RISC-V cores.      |
| NVDLA          | `top`           |         1M |       1.0 ns | NVIDIA deep-learning accelerator (`nv_small_256_full`). |
| O-POPE         | `default`       |       500k |       1.0 ns | Pipelined outer-product GEMM accelerator.               |
| PULP C910      | `default`       |         1M |       1.0 ns | AXI-wrapped 64-bit T-Head C910 RISC-V core.             |
| RedMulE        | `default`       |         5M |       1.5 ns | Reduced-precision matrix-multiplication accelerator.    |
| Serial Link    | `default`       |        10k |       0.5 ns | PULP chip-to-chip serial-link controller.               |
| Snitch Cluster | `minimal`       |         1M |       1.0 ns | Minimal cluster with one compute and one DMA core.      |
| Snitch Cluster | `default`       |         2M |       2.0 ns | Default cluster with eight compute and one DMA core.    |
| Snitch Cluster | `default_latch` |         2M |       2.0 ns | Default cluster using latch-based core register files.  |
| Snitch Cluster | `occamy`        |       100M |          TBD | Occamy-scale aggregate of 48 default clusters.          |
| Spatz          | `default`       |         2M |       2.0 ns | Compact RISC-V vector coprocessor cluster.              |
| SPI Host       | `default`       |        20k |       0.5 ns | PULP-maintained OpenTitan SPI host controller.          |


## Synthesis tools

While Yosys 0.67 and newer include the Slang-based SystemVerilog frontend and do not require a separate plugin, older Yosys versions must be able to find the `slang.so` plugin. The flow detects the Yosys version and loads the plugin only when necessary.

By default the flow executes `yosys`. Set `YOSYS_COMMAND` to select a specific installation or executable path:

```sh
make <flow> YOSYS_COMMAND="/path/to/yosys"
```


## Elaboration check

Run the AST compilation check for every variant with:

```sh
make elaborate AST=1 INTRA_THREADS=8
```

Run the full Yosys elaboration check for a selected variant with `DESIGN`.

```sh
make elaborate DESIGN=ibex.minimal
```

Design variants are listed in `targets.mk`. To list designs with their available technologies and simulation tests, run:

```sh
make list
```

By default, the flow converts the compiled design into Yosys IR, checks its hierarchy, and prints statistics. With `AST=1`, it stops after Slang fully compiles the AST, before conversion to Yosys IR. This avoids full Yosys elaboration, but large variants can still require substantial RAM. With `AST=1 INTRA_THREADS=8`, measured peak RAM was approximately 32 GiB for `mempool.terapool` and 57 GiB for `snitch_cluster.occamy`.

`INTRA_THREADS` sets the number of Slang workers within each process, while GNU Make's `-j` controls how many variants run concurrently.

Internally, `common/elaborate.sh` changes to each variant directory and invokes `common/elaborate.tcl` with the local `filelist.f`. An optional `yosys-slang.args` supplies additional Slang arguments used by both elaboration and synthesis.

Elaboration logs are written to `<design>/variants/<variant>/logs/elaborate.log`. Before each run, an existing log is renamed to `elaborate-<timestamp>.log` in the same directory.


## Synthesis

Synthesis requires technology-specific Liberty files. For `asap7`, place the ASAP7 RVT TT NLDM libraries under `technologies/asap7/technology/LIB/NLDM/`. If an ASAP7 checkout is already available, link it into place:

```sh
ln -s /path/to/asap7 technologies/asap7/technology
```

Alternatively, download the library repository and extract the required files. This requires `7z`:

```sh
technology=technologies/asap7/technology
git clone --depth 1 --filter=blob:none --no-checkout \
  https://github.com/The-OpenROAD-Project/asap7sc7p5t_28.git "$technology"
git -C "$technology" sparse-checkout init --cone
git -C "$technology" sparse-checkout set LIB/NLDM
git -C "$technology" checkout
for archive in "$technology"/LIB/NLDM/asap7sc7p5t_*_RVT_TT_nldm_*.lib.7z; do
  7z e -y -o"$technology/LIB/NLDM" "$archive"
done
```

After installing the technology files and confirming that the design elaborates successfully, run Yosys synthesis with:

```sh
make yosys DESIGN=ibex.minimal TECH=asap7
```

If `TECH` is omitted, the flow runs every technology available for the selected design. If `DESIGN` is also omitted, it runs every listed design and technology. So, `make yosys` would run over all variants and all technologies. With `CHECK=0` (the default), the highest measured peak RAM was approximately 104 GiB for `mempool.terapool`, followed by the second-highest at approximately 36 GiB for `redmule.default`.

For each target, `common/yosys.sh` enters the variant directory and invokes its technology-specific `yosys.tcl`, which uses the shared helpers in `common/yosys.tcl` and any optional `yosys-slang.args`.

The provided synthesis script is minimalistic. It uses `proc -noopt`, then `opt_clean` and `memory_collect` to prepare cells for hierarchy cost estimation, preserves blackbox boundaries, and partially flattens the design using `keep_hierarchy -min_cost 5000` followed by `flatten`. The shared flow then runs `opt -noff -hier`, `check`, `memory_map`, `techmap`, and a follow-up `opt -noff` for every design and synthesis stage. Both optimization passes skip `opt_dff`; register legalization and library mapping still run.

The largest variants use hierarchical synthesis to avoid elaborating and mapping the entire design at once. `mempool.mempool` and `mempool.terapool` synthesize one shared tile implementation, the group interconnect, and the top-level system as separate stages. `snitch_cluster.occamy` similarly synthesizes one implementation shared by all clusters before synthesizing its parent. Each synthesized child becomes a boundary while its parent is processed. With `CHECK=1`, the emitted netlists are reloaded together for the final structural check.

The intermediate `check` calls above report RTL and mapped-design diagnostics without terminating synthesis. Enable the optional final netlist readback check with `make yosys CHECK=1` (default: `CHECK=0`). With this enabled, `check_results` clears the in-memory design, reloads the emitted netlists, and performs strict structural validation. Missing modules, port-width resizing, structural errors, and unmapped cells cause the Make target to fail. Note that enabling this check may substantially increase peak RAM usage compared with synthesis alone.

Synthesis outputs are written under `<design>/variants/<variant>/<technology>/`: netlists in `results/yosys/`, per-stage statistics in `reports/yosys/synthesis.rpt`, and the log in `logs/yosys.log`. With `CHECK=1`, the flow checks hierarchy consistency and writes statistics to `reports/yosys/linked.rpt`. Existing result and report directories and the log are backed up with timestamps before each run.


## Simulation tools

Simulation requires Verilator, a C++ compiler, GNU Make, GNU `timeout`, Z3 (pinned version: 4.13.3), `libelf-dev`, MPFR/GMP development libraries, `pkg-config`, and lowRISC Spike (pinned commit: `aadf648`).

Some designs require a specific version of Verilator to simulate correctly as shown in the table below. For other supported designs, the installer defaults to the prebuilt `verilator==5.48.0` Python package for convenience. Other Verilator versions may also work.

| Designs                            | Verilator pin                    |
| ---------------------------------- | -------------------------------- |
| Ara                                | 06263ec7 (5.047 development)     |
| NVDLA and all MemPool variants     | 746c7ea8 (4.228)                 |
| ITA, Ibex, Serial Link             | ea338be9 (5.052)                 |
| CVFPU, SPI Host                    | 08bbef72 (5.053 development)     |

Expose the Spike installation’s `riscv-riscv`, `riscv-disasm`, and `riscv-fdt` pkg-config files before building:

```sh
export PKG_CONFIG_PATH="/path/to/spike/lib/pkgconfig${PKG_CONFIG_PATH:+:$PKG_CONFIG_PATH}"
```

The optional tool installation scripts are prepared for Linux x86-64. The pinned Verilator version for a design can be installed using the command below. Square brackets indicate optional parts. The installation directory defaults to `tools/install/verilator/`, and `JOBS` defaults to 1. The installer prints the executable path:

```text
[JOBS=<workers>] bash tools/install-verilator.sh ibex.minimal [<installation-directory>]
```

The installer avoids duplicating the same Verilator versions if already installed. Source builds require autoconf, bison, flex (including `libfl-dev` on Ubuntu), help2man, and Git. Python-package installation requires Python (selectable via `PYTHON`) with `venv` and pip. The installed `verilator-cli` can be used without activating the venv. The runner supplies the Python package's required compiler settings automatically.

The pinned Spike build can be installed by the command below. The installer defaults to `tools/install/spike/` and prints the installation directory:

```text
bash tools/install-spike.sh [<installation-directory>]
```


## Simulation

Simulation runs top-level testbenches with RTL designs and upstream behavioral memory models. Set `VERILATOR_COMMAND` explicitly to a Verilator version appropriate for the selected design. This may be a source-installed `verilator` or the Python package’s `verilator-cli`:

```sh
make verilator DESIGN=ibex.minimal TEST=ibex_simple_system_tb VERILATOR_COMMAND=/path/to/verilator
```

A testbench is a simulation harness selected by TEST. Run `make list` to find available testbenches. With neither `DESIGN` nor `TEST` specified, the flow runs all exported tests.

A testbench may have multiple testcases, each with distinct inputs and arguments. For those testbenches with multiple testcases, testcase names are listed in `<design>/data/<testbench>/testcases.txt` or `<design>/variants/<variant>/data/<testbench>/testcases.txt`. By default, all testcases are run for each testbench. TESTCASE can be used to select a specific testcase.

Select an individual testcase:

```sh
make verilator DESIGN=ibex.minimal TEST=ibex_riscv_compliance_tb TESTCASE=rv32i_I-ADD-01 VERILATOR_COMMAND=/path/to/verilator
```

Make's -j shares a worker limit across C++ compilation and testcase execution for all testbenches. Other options are listed below.

| Option  | Meaning                           | Default       |
| ------- | --------------------------------- | ------------- |
| SEED    | Default testcase seed             | 1             |
| TIMEOUT | Build/testcase timeout in seconds | 0 (unlimited) |

Under `<design>/variants/<variant>/`, `build/verilator/<testbench>/` contains generated C++, object files, and the simulation executable. `logs/verilator/<testbench>/` contains `build.log` and a `<testcase>/` subdirectory for each testcase containing `run.log` and generated outputs. Benches without a testcase list write their `run.log` and outputs directly into `logs/verilator/<testbench>/`. Existing build and log directories are backed up with timestamps.


### Testbenches

In the exported package, build and runtime settings live under `<design>/variants/<variant>/verilator/<testbench>/`:

| File                          | Purpose                                                    |
| ----------------------------- | ---------------------------------------------------------- |
| cpp_files.txt                 | C++ source files, relative to the variant directory        |
| cpp_include_dirs.txt          | C++ include directories, relative to the variant directory |
| pkg_config.txt                | Host library package names                                 |
| verilator.args, verilator.vlt | Simulator build arguments and optional configuration       |
| run.args                      | Simulator runtime arguments, one per line                  |

Shared simulation data is under `<design>/data/`. Variant-specific data is under `<design>/variants/<variant>/data/`. Both use the following structure, with files varying by testbench:

```text
data/
  host/                      simulation support sources and headers
  <testbench>/
    README.*                 provenance, toolchain versions, and exclusions
    LICENSE*                 licenses for included software and data
    testcases.txt            testcase names, when provided
    <testcase>/
      run.args               testcase arguments, including firmware paths
      firmware.elf           ELF firmware, when used
      firmware.bin           binary firmware, when used
      firmware.txt           memory initialization image, when used
      ...                    test vectors and expected outputs
    ...                      testbench-wide files
```

#### Ara

The upstream C++ driver and CVA6-based harness run 272 ISA programs and 17 CI applications.

#### Cheshire

The package runs Hello World, 1D/2D DMA, and uncached-SPM execution through JTAG. AXI-RT and CLIC tests are excluded because those features are disabled. The serial-link DMA test is excluded because the testbench lacks a remote device and memory.

#### CV32E40P

The package runs Hello World and interrupt/memory-stall programs. FP and hardware-loop tests are excluded because those features are disabled.

#### CVA6

The package runs 220 programs from four upstream legacy CI lists using the programs’ checks. Spike trace comparison is excluded. The UVM regression is excluded because the tested Verilator versions cannot compile parts of its coverage code.

#### CVFPU

The package runs six available upstream UVM classes for each wrapper, each with 50 seeds and 10 transactions. Coverage is scalar FP32/FP64/FP16, with `fp32_fma` restricted to FP32 arithmetic. Other formats, vector/PACE/dot-product operations, and tests whose sources are missing from the pinned upstream revision are excluded. Vectors involving improperly NaN-boxed operands in DIV/SQRT, infinity inputs in float-to-float conversion, overflow in integer-to-float conversion, or underflow rounding to the smallest normal value in FMA/add/multiply are skipped.

#### Ibex

The package runs Hello World, 84 compliance programs, and Spike co-simulation. The full variant adds PMP and DIT programs. Four upstream-known compliance failures and the [secure dummy-instruction/branch-prediction failure](https://github.com/lowRISC/ibex/issues/1479) are excluded. The upstream UVM testbench is excluded because its clocking declaration is unsupported by the tested Verilator versions.

#### ITA

The package runs seven upstream standalone testcases and the identity testcase. HWPE benches are excluded. An explicit 1 ps delay on latch read outputs works around a race condition caused by Verilator treating nonblocking latch assignments as blocking assignments.

#### MemPool

The package includes Hello World, the upstream CI matrix-multiplication testcase, and 126 RTL ISA programs for each variant. Other baremetal and OpenMP test suites are excluded. TeraPool has not yet been tested with all included testcases.

#### NVDLA

The package runs all 85 upstream traces for `nv_small_256_full`, with CRC checks. The upstream UVM testbench is excluded because its UVMConnect interface is unsupported by the tested Verilator versions.

#### OPOPE

The package runs all 17 upstream CI testcases using FP16 and FP8FP16.

#### PULP C910

The package runs twelve standalone assembly/C programs, including a two-iteration CoreMark functional check. Debug, interrupt, and sleep testcases are excluded because they depend on interfaces or peripherals absent from this integration.

#### RedMulE

The package runs all 92 upstream regression testcases.

#### Serial Link

The package runs all 16 upstream one-channel traffic combinations. Upstream four-channel traffic and calibration tests are excluded.

#### Snitch Cluster

The default and default-latch variants run 154 upstream runtime/ISA and kernel cases, including Python-verified kernels. The minimal variant runs 151 cases, excluding GELU, correlation, and K-means because it lacks floating-point divide/square-root hardware. A shared venv is created automatically for the Python verifiers. An explicit 1 ps delay on latch read outputs works around a race condition caused by Verilator treating nonblocking latch assignments as blocking assignments.

The Occamy variant aggregates 48 default clusters and has no simulation testbench.

#### Spatz

The package runs all 155 programs from the three upstream CTest suites. The illegal-instruction testcase passes when it returns the expected exit code.

#### SPI Host

The package runs eleven dedicated upstream sequences, each with two seeds, against the PULP synthesis wrapper. Tests for passthrough, alerts, and TileLink integrity are excluded because those interfaces are absent from the PULP integration. Functional coverage is disabled.

OpenTitan’s verification environment is adapted to the PULP register bus using `tlul_adapter_reg`, with register and agent configuration for three chip selects. Compatibility patches work around Verilator’s inherited weighted constraints and high-impedance writes through virtual interfaces, using per-lane output enables for the latter.


## Limitations

### Simulation

- The simulation flow does not validate propagation of unknown (`X`) values.
- The provided flows do not verify functional correctness or equivalence after synthesis. For post-synthesis simulation, testbenches that directly access internal signals or memories may need adaptation. Passing structural checks alone does not establish functional correctness.

### Synthesis

- Some target-specific Slang options ignore assertions; Mempool also ignores initial blocks.
- For `asap7`, every variant except `cvfpu.fp32_fma` uses `async2sync` to convert asynchronous-load registers before cell mapping. This is a workaround for the available library mappings; the synthesized netlists do not preserve asynchronous-load behavior exactly.

### Design configurations

- `cva6.default` and `cheshire.default` use fixed boot addresses in CVA6's controller and CSR logic: `0x80000000` for `cva6.default` and `0x02000000` for `cheshire.default`, matching Cheshire's default boot ROM. This makes the asynchronous reset values constant for synthesis. The `boot_addr_i` port in `cva6.default` is retained, but changing it does not change the fixed boot address; a different boot address requires updating the benchmark patches.
- `ibex.full` leaves I-cache scrambling disabled, despite enabling secure mode, lockstep, and memory ECC.
- `cvfpu.full` uses the upstream-default THMULTI divider, which does not support FP8/FP8alt division or square root. Those formats remain enabled for other operations. Its upstream warning is retained for simulation and excluded from synthesis for Yosys-Slang compatibility.

### Physical design

- No physical design flow is provided. Technology-specific SDC files are included with each variant, but the elaboration and Yosys synthesis flows do not read them. Synthesis performs cell mapping and structural validation; it does not establish timing closure.
- SRAM macros are not provided in this package. Simulation uses behavioral memory implementations, whereas synthesis replaces them with black-box stubs. Specifically, the upstream `tc_sram` implementation is replaced with `tc_sram_blackbox`, and NVDLA's simulation RAM models are replaced with corresponding black boxes. Physical design requires SRAM macros with appropriate mappings and views, such as Liberty for physical synthesis and LEF/GDS for backend use.
