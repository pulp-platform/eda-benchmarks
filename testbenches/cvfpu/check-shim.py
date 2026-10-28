#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
import ctypes
import struct
import sys


class Environment(ctypes.Structure):
    _fields_ = [('bis', ctypes.c_short), ('es', ctypes.c_char)]


Word = ctypes.c_uint32 * 2
library = ctypes.CDLL(sys.argv[1])
for width, exponent_bits, fmt in [(32, 8, 'f'), (64, 11, 'd')]:
    def words(value):
        integer = int.from_bytes(struct.pack('<' + fmt, value), 'little')
        return Word(integer & 0xffffffff, integer >> 32)

    for operation, left, right, expected in [
        ('fadd', 1.5, 2.25, 3.75),
        ('fsub', 3.75, 2.25, 1.5),
        ('fmul', 1.5, 2.0, 3.0),
        ('fdiv', 3.0, 2.0, 1.5),
    ]:
        direct_result, flat_result = Word(), Word()
        environment = Environment(width - 1, bytes([exponent_bits - 1]))
        direct = getattr(library, 'dpi_' + operation)
        flat = getattr(library, 'dpi_' + operation + '_flat')
        direct.argtypes = [ctypes.POINTER(ctypes.c_uint32)] * 3 + [
            ctypes.c_int, ctypes.POINTER(Environment)]
        flat.argtypes = [ctypes.POINTER(ctypes.c_uint32)] * 3 + [
            ctypes.c_int, ctypes.POINTER(ctypes.c_uint32)]
        direct_flags = direct(direct_result, words(left), words(right), 0,
                              ctypes.byref(environment))
        packed_environment = ctypes.c_uint32(((width - 1) << 8) | (exponent_bits - 1))
        flat_flags = flat(flat_result, words(left), words(right), 0,
                          ctypes.byref(packed_environment))
        assert list(direct_result) == list(flat_result)
        assert direct_flags == flat_flags
        assert list(flat_result)[:width // 32] == list(words(expected))[:width // 32], (
            operation, list(flat_result))
print('PASS: 8 FP32/FP64 cases agree across original and flattened DPI calls')
