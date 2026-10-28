Notices for lowRISC Spike aadf648d742de54f0a50eec01ceffd13ed12a1d1,
used by the Ibex co-simulation testbench.

Source: https://github.com/lowRISC/riscv-isa-sim/tree/aadf648d742de54f0a50eec01ceffd13ed12a1d1
LICENSE.Spike: source repository LICENSE.
LICENSE.SoftFloat: notice from softfloat/softfloat.h (Release 3d).
LICENSE.libfdt: fdt/ copyright notices, using the BSD-2-Clause alternative.
BSD text: https://github.com/dgibson/dtc/blob/main/BSD-2-Clause
LICENSE.riscv-opcodes: encoding.h's upstream riscv-opcodes 4d7f46e LICENSE.

Spike and libfdt are linked into the simulator. libsoftfloat.so is loaded
from the separate Spike installation; it is not bundled in simulator archives.
