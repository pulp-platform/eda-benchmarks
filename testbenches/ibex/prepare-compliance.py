# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
from pathlib import Path
import shutil
import subprocess
import sys
from bin_to_vmem import bin_to_vmem

source, output = map(Path, sys.argv[1:3])
prefix = sys.argv[3]
output.mkdir(parents=True, exist_ok=True)
build = source.parent / "compliance-firmware"
build.mkdir(exist_ok=True)
device = source / "riscv-target/ibex/device/rv32imc"

skipped = {
    "rv32i_I-EBREAK-01",
    "rv32i_I-ECALL-01",
    "rv32i_I-MISALIGN_JMP-01",
    "rv32i_I-MISALIGN_LDST-01",
}
suites = {
    "rv32i": "rv32i",
    "rv32im": "rv32im",
    "rv32imc": "rv32imc",
    "rv32Zicsr": "rv32i_zicsr",
    "rv32Zifencei": "rv32i",
}
cases = []
notices = []
for suite, arch in suites.items():
    for assembly in sorted((source / "riscv-test-suite" / suite / "src").glob("*.S")):
        name = f"{suite}_{assembly.stem}"
        if name in skipped:
            continue
        elf, binary = build / f"{name}.elf", build / f"{name}.bin"
        subprocess.run([
            prefix + "gcc", f"-march={arch}", "-mabi=ilp32", "-misa-spec=2.2",
            "-static", "-mcmodel=medany", "-fvisibility=hidden", "-nostdlib", "-nostartfiles",
            "-I" + str(source / "riscv-test-env"),
            "-I" + str(source / "riscv-test-env/p"),
            "-I" + str(source / "riscv-target/ibex"),
            "-DPRIV_MISA_S=0", "-DPRIV_MISA_U=0",
            '-DTRAPHANDLER="' + str(device / "handler.S") + '"',
            "-T" + str(device / "link.ld"), str(assembly), "-o", str(elf),
        ], check=True)
        subprocess.run([prefix + "objcopy", "-O", "binary", str(elf), str(binary)], check=True)
        case_dir = output / name
        case_dir.mkdir(exist_ok=True)
        bin_to_vmem(binary, case_dir / "firmware.txt")
        reference = assembly.parent.parent / "references" / f"{assembly.stem}.reference_output"
        shutil.copyfile(reference, case_dir / "reference.txt")
        (case_dir / "run.args").write_text(
            f"--meminit=ram,${{DATA_DIR}}/{name}/firmware.txt,vmem\n"
            f"+SIGNATURE_REFERENCE=${{DATA_DIR}}/{name}/reference.txt\n")
        cases.append(name)
        notices.append(str(assembly.relative_to(source)) + "\n" + assembly.read_text())

if len(cases) != 84:
    raise SystemExit(f"Expected 84 compliance programs, found {len(cases)}")
(output / "testcases.txt").write_text("\n".join(cases) + "\n")
(output / "README.md").write_text(
    "# Ibex ISA compliance data\n\n"
    "testcases.txt lists the 84 programs executed by the simulation runner. Each program\n"
    "has a directory containing firmware.txt, reference.txt, and run.args.\n\n"
    "Four upstream-known failures are excluded:\n\n"
    + "".join(f"- {name}\n" for name in sorted(skipped))
    + "\nEBREAK and ECALL access stvec, which Ibex does not implement. The misalignment\n"
    "tests assume trapping behavior incompatible with Ibex compressed instructions\n"
    "and misaligned accesses. See https://github.com/lowRISC/ibex/issues/100.\n\n"
    "Suite revision: 844c6660ef3f0d9b96957991109dfd80cc4938e2 (Ibex CI pin).\n"
    "Compiler: upstream lowRISC GCC rv32imcb 20220210-1 (GCC 10.2.0), ISA specification 2.2; original CSR names.\n")
for license_file in source.glob("COPYING*"):
    shutil.copyfile(license_file, output / ("LICENSE." + license_file.name))
(output / "LICENSE.sources.txt").write_text("\n\n".join(notices))
