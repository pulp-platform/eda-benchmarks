# PULP benchmark suite

This repository prepares and exports RTL files of the selected PULP designs with minimalistic synthesis flow files.


## Get started

Download the prepared benchmark tarball from the release's **Assets** on GitHub's [Releases page](../../releases). Extract it and run the commands below from the `pulp-benchmarks-v<version>/` directory. Automatic source-code archives do not contain the prepared RTL. Generating from source is not necessary for normal use.

<details>
<summary>Generate from source</summary>

Generating from source requires Linux with Bash 4 or newer, Git, and GNU utilities. Automatic Bender installation additionally requires curl, tar with xz support, and a SHA-256 utility. To install the prerequisites for all benchmarks on Ubuntu:

```sh
sudo apt-get install bash build-essential ca-certificates coreutils curl findutils \
  gawk git libxml-simple-perl openjdk-17-jre-headless perl python3 \
  python3-venv sed tar xz-utils
```

NVDLA generation additionally requires Java 17, Perl with `XML::Simple`, Make, GCC/G++, and cpp. Java is looked up in the following order: `JAVA`, `JAVA_HOME/bin/java`, and `java` from `PATH`. Make is also used to launch the exported synthesis and elaboration flows.

Python is required for NVDLA and Snitch Cluster. Snitch Cluster requires Python 3.10 or newer with `venv` and pip for its pinned generator dependencies. Specify `PYTHON` to select the base Python interpreter if needed.

From a Git clone of this repository, generate every benchmark with:

```sh
./setup.sh
```

To collect only one variant, pass its target name:

```sh
./setup.sh cvfpu.fp32_fma
```

The collected, self-contained RTL package is written to `benchmarks/`. If that directory already exists, `setup.sh` leaves it unchanged and exits with an error code. `setup.sh` initializes only the design submodules in `deps/` needed by the selected benchmarks, checks out locked dependencies, applies the required source patches, and generates relocatable file lists.

A custom dependency management tool, Bender, is used. It is set up locally by `setup.sh`, so no separate Bender installation is required. The Bender recipes and automatic dependency/filelist flow are described in [`bender/README.md`](bender/README.md).

When a Snitch variant is selected, `setup.sh` creates a Git-ignored `.venv` and fetches the pinned Python packages used by its configuration generator.


## Repository layout

```text
deps/       upstream design repositories pinned through git submodule
bender/     variant-specific Bender recipes and dependency locks
patches/    source patches applied while preparing benchmarks
support/    shared RTL stubs
flows/      flow files
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
  variants/<variant>/
    *.sv                        benchmark top/wrapper sources
    <technology>/default.sdc    technology-specific constraints
    <technology>/yosys.tcl      technology-specific Yosys synthesis flow
    yosys-slang.args            Slang options shared by Yosys flows (optional)
    filelist.f                  file paths
targets.mk                      target list
Makefile                        flow entry point
common/
  backup.sh                     timestamped output backups
  elaborate.sh                  Yosys elaboration launcher
  elaborate.tcl                 Yosys elaboration flow
  yosys.sh                      Yosys synthesis launcher
  yosys.tcl                     Yosys synthesis flow helpers
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


## Yosys-Slang

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
make elaborate DESIGN=cvfpu.full
```

Design variants are listed in `targets.mk`, or list the accepted values with:

```sh
make list
```

By default, the flow converts the compiled design into Yosys IR, checks its hierarchy, and prints statistics. With `AST=1`, it stops after Slang fully compiles the AST, before conversion to Yosys IR. This avoids full Yosys elaboration, but large variants can still require substantial RAM. With `AST=1 INTRA_THREADS=8`, measured peak RAM was approximately 32 GiB for `mempool.terapool` and 57 GiB for `snitch_cluster.occamy`.

`INTRA_THREADS` sets the number of Slang workers within each process, while GNU Make's `-j` controls how many variants run concurrently.

Internally, `common/elaborate.sh` changes to each variant directory and invokes `common/elaborate.tcl` with the local `filelist.f`. An optional `yosys-slang.args` supplies additional Slang arguments used by both elaboration and synthesis.


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
make yosys DESIGN=cvfpu.full TECH=asap7
```

If `TECH` is omitted, the flow runs every technology available for the selected design. If `DESIGN` is also omitted, it runs every listed design and technology. So, `make yosys` would run over all variants and all technologies. With `CHECK=0` (the default), the highest measured peak RAM was approximately 104 GiB for `mempool.terapool`, followed by the second-highest at approximately 36 GiB for `redmule.default`.

For each target, `common/yosys.sh` enters the variant directory and invokes its technology-specific `yosys.tcl`, which uses the shared helpers in `common/yosys.tcl` and any optional `yosys-slang.args`.

The provided synthesis script is minimalistic. It uses `proc -noopt`, then `opt_clean` and `memory_collect` to prepare cells for hierarchy cost estimation, preserves blackbox boundaries, and partially flattens the design using `keep_hierarchy -min_cost 5000` followed by `flatten`. The shared flow then runs `opt -noff -hier`, `check`, `memory_map`, `techmap`, and a follow-up `opt -noff` for every design and synthesis stage. Both optimization passes skip `opt_dff`; register legalization and library mapping still run.

The largest variants use hierarchical synthesis to avoid elaborating and mapping the entire design at once. `mempool.mempool` and `mempool.terapool` synthesize one shared tile implementation, the group interconnect, and the top-level system as separate stages. `snitch_cluster.occamy` similarly synthesizes one implementation shared by all clusters before synthesizing its parent. Each synthesized child becomes a boundary while its parent is processed. With `CHECK=1`, the emitted netlists are reloaded together for the final structural check.

The intermediate `check` calls above report RTL and mapped-design diagnostics without terminating synthesis. Enable the optional final netlist readback check with `make yosys CHECK=1` (default: `CHECK=0`). With this enabled, `check_results` clears the in-memory design, reloads the emitted netlists, and performs strict structural validation. Missing modules, port-width resizing, structural errors, and unmapped cells cause the Make target to fail. Note that enabling this check may substantially increase peak RAM usage compared with synthesis alone.


## Results and logs

Elaboration logs are written to `<design>/variants/<variant>/logs/elaborate.log`. Before each run, an existing log is renamed to `elaborate-<timestamp>.log` in the same directory.

Synthesis logs, netlists, and reports are written under `<design>/variants/<variant>/<technology>/`. For hierarchical flows, `logs/yosys.log` covers every synthesis stage, while `reports/yosys/synthesis.rpt` records statistics for each stage. With `CHECK=1`, `reports/yosys/linked.rpt` records statistics for the complete reloaded hierarchy, including every instance of the shared synthesized children.

Before synthesis, the flow preserves existing `results/yosys/` and `reports/yosys/` directories as `results/yosys-<timestamp>/` and `reports/yosys-<timestamp>/`, and `logs/yosys.log` as `logs/yosys-<timestamp>.log`, using the same timestamp for all three.


## Limitations

- Behavioral memory implementations are replaced with black-box stubs. The upstream `tc_sram` implementation is replaced with `tc_sram_blackbox`, and NVDLA's simulation RAM models are replaced with corresponding black boxes. For functional simulation, the black-box stubs must be replaced with behavioral memory models. SRAM macros would be required for physical design with appropriate mappings and views, such as Liberty for physical synthesis and LEF/GDS for backend use.
- The provided flows do not verify functional correctness after synthesis. Post-synthesis functional simulation requires a testbench. Passing structural checks alone does not establish functional correctness.
- Some target-specific Slang options ignore assertions; Mempool also ignores initial blocks.
- For `asap7`, every variant except `cvfpu.fp32_fma` uses `async2sync` to convert asynchronous-load registers before cell mapping. This is a workaround for the available library mappings; the synthesized netlists do not preserve asynchronous-load behavior exactly.
- `cva6.default` and `cheshire.default` use fixed boot addresses in CVA6's controller and CSR logic: `0x80000000` for `cva6.default` and `0x02000000` for `cheshire.default`, matching Cheshire's default boot ROM. This makes the asynchronous reset values constant for synthesis. The `boot_addr_i` port in `cva6.default` is retained, but changing it does not change the fixed boot address; a different boot address requires updating the benchmark patches.
- `ibex.full` leaves I-cache scrambling disabled, despite enabling secure mode, lockstep, and memory ECC.
- `cvfpu.full` uses the upstream-default THMULTI divider, which does not support FP8/FP8alt division or square root. Those formats remain enabled for other operations. Its upstream warning is retained for simulation and excluded from synthesis for Yosys-Slang compatibility.
- Technology-specific SDC files are included with each variant, but the elaboration and Yosys synthesis flows do not read them. Synthesis performs cell mapping and structural validation; it does not establish timing closure.
