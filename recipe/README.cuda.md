# CUDA variant

The initial CUDA variant is Linux x86-64/headless with CUDA 12.9 and cuDNN 9.
It includes the contrib CUDA modules and the CUDA/cuDNN DNN backend. CPU and
Qt builds remain available without CUDA dependencies.

CUDA uses GCC 14 and glibc >=2.28 (required by cuDNN). GPU targets are Turing
and newer: SM 75, 80, 86, 89, 90, 100 and 120, plus compute-120 PTX for newer
GPUs. An NVIDIA driver supporting CUDA 12.9 or newer is required. CUDA 13,
Windows/ARM/Qt CUDA builds, and NVDEC/NVENC (`cudacodec`) are not enabled yet.

## Installation

Once these draft builds are published, request the CUDA build explicitly:

```sh
pixi add 'opencv=*=headless_cuda129_*'
# Optional; its exact libopencv dependency selects the matching CUDA plugin.
pixi add opencv-gstreamer
```

All four outputs share the CUDA build tag; Python bindings and GStreamer pin
libopencv exactly. CUDA run exports retain the build flavor so downstream
CUDA consumers cannot silently resolve to CPU libraries. CUDA variants are
down-prioritized, and require the `__cuda` virtual package, so ordinary installs
prefer CPU builds. The CUDA runtime libraries are dependencies; a system CUDA
toolkit is not required. Installing CUDA dependencies beside a CPU build does
not enable GPU support.

## Validation

Package tests check the CUDA libraries, runtime dependencies, build information
and Python API availability without requiring a GPU. On a GPU host they also
exercise GpuMat upload/download, resize, and cuDNN-backed DNN pooling. The DNN
test rejects silent CPU fallback.

To require real GPU execution rather than permit device-test skips:

```sh
python recipe/test_cuda.py 12.9 --require-gpu -v
```

GPU-less CI uses conda-forge's `CONDA_OVERRIDE_CUDA` for dependency solving only;
it does not prove GPU execution. Do not use that override to bypass driver
requirements on an actual GPU host.
