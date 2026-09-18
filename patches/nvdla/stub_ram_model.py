#!/usr/bin/env python3
# Copyright (c) 2026 ETH Zurich and University of Bologna.
# SPDX-License-Identifier: Apache-2.0

import os
import re
import sys
from collections import OrderedDict
from pathlib import Path


def strip_comments(text):
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    return re.sub(r"//[^\n]*", "", text)


def stub_ram_model(path):
    target = path.stem
    source = path.read_text()
    module_re = re.compile(r"(?m)^\s*module\s+" + re.escape(target) + r"\b")
    module_matches = list(module_re.finditer(source))
    if len(module_matches) != 1:
        raise SystemExit(
            "Expected exactly one outer module declaration {} in {} (found {})".format(
                target, path, len(module_matches)
            )
        )

    module_match = module_matches[0]
    header_end = source.find(";", module_match.end())
    if header_end < 0:
        raise SystemExit("Missing module-header terminator for {} in {}".format(target, path))
    header = source[module_match.start() : header_end + 1]
    open_paren = header.find("(")
    close_paren = header.rfind(")")
    if open_paren < 0 or close_paren < open_paren:
        raise SystemExit("Missing complete port list for {} in {}".format(target, path))

    port_text = strip_comments(header[open_paren + 1 : close_paren])
    header_ports = []
    for item in port_text.split(","):
        item = item.strip()
        if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_$]*", item):
            raise SystemExit("Malformed header port {!r} in {}".format(item, path))
        header_ports.append(item)
    if not header_ports or len(set(header_ports)) != len(header_ports):
        raise SystemExit("Header ports are empty or duplicated in {}".format(path))

    body_end = re.search(r"(?m)^\s*endmodule\b", source[header_end + 1 :])
    if body_end is None:
        raise SystemExit("Missing outer endmodule for {} in {}".format(target, path))
    body = source[header_end + 1 : header_end + 1 + body_end.start()]
    body = strip_comments(body)
    body = re.sub(r"(?m)^\s*`[^\n]*\n", "\n", body)

    body_lines = []
    routine_depth = 0
    for line in body.splitlines():
        if re.match(r"^\s*(?:automatic\s+)?(?:task|function)\b", line):
            routine_depth += 1
        if routine_depth == 0:
            body_lines.append(line)
        if routine_depth > 0 and re.match(r"^\s*end(?:task|function)\b", line):
            routine_depth -= 1
    if routine_depth != 0:
        raise SystemExit("Unterminated task/function declaration in {}".format(path))
    body = "\n".join(body_lines)

    declarations = OrderedDict()
    decl_re = re.compile(r"\b(input|output|inout)\b([^;]*);", re.S)
    qualifiers = re.compile(r"^(?:(?:wire|reg|logic|tri|signed|unsigned)\s+)*")
    identifier = r"[A-Za-z_][A-Za-z0-9_$]*"
    for match in decl_re.finditer(body):
        direction, payload = match.groups()
        if re.search(r"\[[^\]]*\]", payload):
            raise SystemExit("Vector outer port declarations are unsupported in {}".format(path))
        for item in payload.split(","):
            item = qualifiers.sub("", item.strip())
            if not re.fullmatch(identifier, item):
                raise SystemExit("Malformed {} declaration {!r} in {}".format(direction, item, path))
            if item in declarations:
                raise SystemExit("Port {} is declared more than once in {}".format(item, path))
            declarations[item] = direction

    header_set = set(header_ports)
    declaration_set = set(declarations)
    if header_set != declaration_set:
        missing = sorted(header_set - declaration_set)
        extra = sorted(declaration_set - header_set)
        raise SystemExit(
            "Port direction mismatch in {}: missing={} extra={}".format(path, missing, extra)
        )

    groups = OrderedDict()
    for port in header_ports:
        groups.setdefault(declarations[port], []).append(port)

    # Preserve the original leading comments, including copyright and license
    # notices, while discarding the implementation and its preprocessor code.
    original_header = re.match(
        r"\A(?:\s+|//[^\n]*(?:\n|$)|/\*.*?\*/)*", source, re.S
    ).group()
    lines = [
        "// Modified by pulp-benchmarks: replaced the RAM implementation with a black box.",
        original_header.rstrip(),
        "(* black_box, syn_black_box = 1 *)",
        "module {} (".format(target),
    ]
    for index, port in enumerate(header_ports):
        suffix = "," if index + 1 < len(header_ports) else ""
        lines.append("  {}{}".format(port, suffix))
    lines.append(");")
    for direction, ports in groups.items():
        lines.append("{} {};".format(direction, ", ".join(ports)))
    lines.append("endmodule")

    temporary = path.with_name(path.name + ".tmp.{}".format(os.getpid()))
    temporary.write_text("\n".join(lines) + "\n")
    temporary.replace(path)


def main():
    if len(sys.argv) < 2:
        raise SystemExit("Usage: {} <RAM-model>...".format(sys.argv[0]))
    for argument in sys.argv[1:]:
        stub_ram_model(Path(argument))


if __name__ == "__main__":
    main()
