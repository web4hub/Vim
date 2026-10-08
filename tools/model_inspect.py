#!/usr/bin/env python3
"""Safe metadata/tensor inspector for AI model artifacts.

Never unpickles PyTorch checkpoints and never executes model code.
"""
from __future__ import annotations

import json
import os
import struct
import sys
import zipfile
from typing import Any, BinaryIO

GGML_TYPES = {
    0:"F32", 1:"F16", 2:"Q4_0", 3:"Q4_1", 6:"Q5_0", 7:"Q5_1",
    8:"Q8_0", 9:"Q8_1", 10:"Q2_K", 11:"Q3_K_S", 12:"Q3_K_M",
    13:"Q3_K_L", 14:"Q4_K_S", 15:"Q4_K_M", 16:"Q5_K_S", 17:"Q5_K_M",
    18:"Q6_K", 19:"Q8_K", 20:"IQ2_XXS", 21:"IQ2_XS", 22:"IQ3_XXS",
    23:"IQ1_S", 24:"IQ4_NL", 25:"IQ3_S", 26:"IQ2_S", 27:"IQ4_XS",
    28:"I8", 29:"I16", 30:"I32", 31:"I64", 32:"F64", 33:"IQ1_M",
    34:"BF16", 35:"TQ1_0", 36:"TQ2_0",
}
GGUF_KV_TYPES = {
    0:"UINT8",1:"INT8",2:"UINT16",3:"INT16",4:"UINT32",5:"INT32",
    6:"FLOAT32",7:"BOOL",8:"STRING",9:"ARRAY",10:"UINT64",11:"INT64",12:"FLOAT64",
}

def read_exact(f: BinaryIO, n: int) -> bytes:
    b = f.read(n)
    if len(b) != n:
        raise ValueError("unexpected end of file")
    return b

def u32(f): return struct.unpack("<I", read_exact(f, 4))[0]
def u64(f): return struct.unpack("<Q", read_exact(f, 8))[0]
def string(f) -> str:
    n = u64(f)
    if n > 16 * 1024 * 1024:
        raise ValueError("string too large")
    return read_exact(f, n).decode("utf-8", "replace")

def gguf_value(f, typ: int, depth=0):
    if depth > 4: raise ValueError("nested GGUF array too deep")
    if typ == 0: return struct.unpack("<B", read_exact(f,1))[0]
    if typ == 1: return struct.unpack("<b", read_exact(f,1))[0]
    if typ == 2: return struct.unpack("<H", read_exact(f,2))[0]
    if typ == 3: return struct.unpack("<h", read_exact(f,2))[0]
    if typ == 4: return u32(f)
    if typ == 5: return struct.unpack("<i", read_exact(f,4))[0]
    if typ == 6: return struct.unpack("<f", read_exact(f,4))[0]
    if typ == 7: return bool(u32(f))
    if typ == 8: return string(f)
    if typ == 10: return u64(f)
    if typ == 11: return struct.unpack("<q", read_exact(f,8))[0]
    if typ == 12: return struct.unpack("<d", read_exact(f,8))[0]
    if typ == 9:
        et = u32(f); n = u64(f)
        if n > 1_000_000: raise ValueError("array too large")
        return [gguf_value(f, et, depth + 1) for _ in range(n)]
    raise ValueError(f"unknown GGUF metadata type {typ}")

def parse_gguf(path):
    out = {"format":"GGUF", "tensors":[], "metadata":{}}
    with open(path, "rb") as f:
        if read_exact(f,4) != b"GGUF": raise ValueError("invalid GGUF magic")
        version, nt, nk = u32(f), u64(f), u64(f)
        out["version"], out["tensor_count"], out["metadata_count"] = version, nt, nk
        if nk > 1_000_000 or nt > 10_000_000: raise ValueError("unreasonable GGUF counts")
        for _ in range(nk):
            key = string(f); typ = u32(f)
            out["metadata"][key] = gguf_value(f, typ)
        for _ in range(nt):
            name = string(f); nd = u32(f)
            if nd > 64: raise ValueError("invalid tensor rank")
            shape = [u64(f) for _ in range(nd)]
            typ = u32(f); offset = u64(f)
            out["tensors"].append({"name":name, "shape":shape,
                                   "dtype":GGML_TYPES.get(typ, f"GGML_TYPE_{typ}"),
                                   "offset":offset})
    return out

def parse_safetensors(path):
    out = {"format":"Safetensors", "tensors":[], "metadata":{}}
    size = os.path.getsize(path)
    with open(path, "rb") as f:
        n = struct.unpack("<Q", read_exact(f,8))[0]
        if n > min(size - 8, 100 * 1024 * 1024): raise ValueError("invalid Safetensors header length")
        header = json.loads(read_exact(f,n).decode("utf-8"))
    for name, info in header.items():
        if name == "__metadata__":
            out["metadata"] = info if isinstance(info, dict) else {}
            continue
        if not isinstance(info, dict): continue
        out["tensors"].append({
            "name": name,
            "shape": info.get("shape", []),
            "dtype": info.get("dtype", "UNKNOWN"),
            "data_offsets": info.get("data_offsets", []),
        })
    out["tensor_count"] = len(out["tensors"])
    return out

def parse_pt(path):
    out = {"format":"PyTorch checkpoint", "tensors":[], "metadata":{}}
    out["safe_note"] = "PyTorch pickle payload was not unpickled or executed."
    try:
        with zipfile.ZipFile(path) as z:
            names = z.namelist()
            out["archive_entries"] = len(names)
            out["archive_type"] = "ZIP/Torch archive"
            out["pickle_present"] = any(n.endswith("data.pkl") for n in names)
            out["metadata"]["archive_entries"] = names[:100]
    except zipfile.BadZipFile:
        out["archive_type"] = "non-ZIP checkpoint; tensor inspection unavailable without unsafe deserialization"
    return out

def parse_onnx(path):
    out = {"format":"ONNX", "tensors":[], "metadata":{}}
    try:
        import onnx
    except ImportError:
        out["error"] = "Python package 'onnx' is required for ONNX graph inspection"
        return out
    model = onnx.load_model(path, load_external_data=False)
    out["ir_version"] = model.ir_version
    out["opset_import"] = [{"domain":x.domain, "version":x.version} for x in model.opset_import]
    out["producer"] = {"name":model.producer_name, "version":model.producer_version}
    out["graph"] = {"name":model.graph.name, "nodes":len(model.graph.node),
                    "inputs":len(model.graph.input), "outputs":len(model.graph.output),
                    "initializers":len(model.graph.initializer)}
    out["metadata"] = {p.key:p.value for p in model.metadata_props}
    for t in model.graph.initializer:
        out["tensors"].append({"name":t.name, "shape":list(t.dims),
                               "dtype":onnx.TensorProto.DataType.Name(t.data_type)})
    return out

def enrich(out):
    md = out.get("metadata", {})
    def first(*keys):
        for k in keys:
            if k in md and md[k] not in ("", None):
                return md[k]
        return None
    arch = first("general.architecture","architecture","model_type","model.architecture")
    q = first("general.file_type","general.quantization_version","quantization","quantization_config",
              "quantization_method","quantization_type")
    out["architecture"] = arch if arch is not None else "unknown"
    out["quantization"] = q if q is not None else "none/unknown"
    out["metadata"] = md
    return out

def main():
    if len(sys.argv) != 3 or sys.argv[1] not in {"info","tensors","architecture","quantization"}:
        raise SystemExit("usage: model_inspect.py {info|tensors|architecture|quantization} FILE")
    path = os.path.abspath(sys.argv[2])
    if not os.path.isfile(path): raise SystemExit(f"file not found: {path}")
    ext = os.path.splitext(path)[1].lower()
    parser = {".gguf":parse_gguf, ".safetensors":parse_safetensors,
              ".pt":parse_pt, ".onnx":parse_onnx}.get(ext)
    if not parser: raise SystemExit(f"unsupported model extension: {ext}")
    result = enrich(parser(path))
    result["file"] = path
    result["size_bytes"] = os.path.getsize(path)
    if sys.argv[1] == "tensors":
        result = {k:result[k] for k in ("format","file","size_bytes","tensor_count","tensors") if k in result}
    elif sys.argv[1] == "architecture":
        result = {k:result[k] for k in ("format","file","architecture","graph","producer","opset_import","metadata") if k in result}
    elif sys.argv[1] == "quantization":
        result = {k:result[k] for k in ("format","file","quantization","metadata") if k in result}
    print(json.dumps(result, ensure_ascii=False, indent=2))

if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, json.JSONDecodeError, struct.error, UnicodeError) as e:
        print(json.dumps({"error":str(e)}))
        raise SystemExit(1)
