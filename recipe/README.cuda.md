# CUDA variants

CUDA/compiler versions come from conda-forge's global pinning. The current
matrix builds both CUDA 12.9 and 13.4 on **linux-64, linux-aarch64 (SBSA), and
win-64**, with both **headless and Qt 6** variants. CPU builds remain available
on all existing platforms. Each variant builds both pinned HDF5 versions.

Linux uses the globally paired GCC versions (currently GCC 14 for CUDA 12.9,
GCC 15 for CUDA 13.4). cuDNN 9 requires glibc >=2.28, so the recipe raises the
CUDA 12 Linux sysroot floor while retaining the CPU glibc 2.17 baseline. Windows
uses conda-forge's MSVC toolchain. ARM builds explicitly select `arm-variant=sbsa`.

GPU targets and forward PTX come from `CUDAARCHS` in the selected conda-forge
CUDA compiler's activation scripts, not from the CI GPU or a hard-coded local
architecture list. A patch preserves CMake's architecture/family suffixes such
as `90a` and `100f` when OpenCV generates its legacy capability metadata.

The builds include contrib CUDA modules, cuBLAS/cuFFT, and the cuDNN-backed DNN
backend. NVDEC/NVENC (`cudacodec`) remains disabled. CUDA does not enable non-free
algorithms.

## Installation

Once the draft builds are published, select a CUDA/GUI build explicitly, e.g.:

```sh
pixi add 'opencv=*=headless_cuda129_*'
# Alternatively: pixi add 'opencv=*=qt6_cuda134_*'
pixi add opencv-gstreamer  # Optional; selects the matching core build.
```

All four outputs carry the CUDA flavor. Python bindings and GStreamer pin the
core exactly; CUDA run exports retain the build flavor. CUDA is down-prioritized
and requires a driver reporting `__cuda` at least as new as the selected toolkit,
so ordinary installs prefer CPU builds. Runtime CUDA libraries are dependencies;
a system toolkit is not required for Python/runtime use. C++ consumers using
`find_package(OpenCV)` need the matching toolkit. Adding CUDA dependencies to a
CPU build does not enable GPU support.

## Validation

Package tests check compiled libraries, runtime dependencies, build information,
Python APIs and CMake architecture handling without a GPU. On a GPU host they
also test GpuMat upload/download, resize and cuDNN pooling, rejecting CPU fallback
for the pooling layer. To require device execution (choose the installed toolkit):

```sh
python recipe/test_cuda.py 13.4 --require-gpu -v
```

GPU-less CI uses conda-forge's `CONDA_OVERRIDE_CUDA` for solving only; it does not
prove device execution. Do not override driver detection on real GPU hosts.
