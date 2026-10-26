# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0
import jstyleson, sys
cfg = jstyleson.load(open(sys.argv[1]))
c = cfg['cluster']
values = {
    'MEM_DRAM_ORIGIN': cfg['dram']['address'], 'MEM_DRAM_SIZE': cfg['dram']['length'],
    'SNRT_BASE_HARTID': c['cluster_base_hartid'], 'SNRT_CLUSTER_CORE_NUM': len(c['cores']),
    'SNRT_TCDM_START_ADDR': c['cluster_base_addr'], 'SNRT_CLUSTER_OFFSET': c['cluster_base_offset'],
    'SNRT_TCDM_SIZE': c['tcdm']['size'] * 1024, 'SNRT_NFPU_PER_CORE': c['n_fpu'],
    'ELEN': 64 if 'd' in c['cores'][0]['isa'] else 32,
}
for name, value in values.items(): print(f'-D{name}={value}')
