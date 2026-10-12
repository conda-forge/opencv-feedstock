"""Check the native output without relying on Python bindings."""
import json
from pathlib import Path
import sys

version = sys.argv[1]
prefix = Path(sys.prefix)
modules = """
alphamat bgsegm calib ccalib core datasets dnn dnn_objdetect dnn_superres dpm
face features flann freetype fuzzy gapi geometry hfs highgui img_hash imgcodecs
imgproc intensity_transform line_descriptor ml objdetect optflow phase_unwrapping
photo plot ptcloud quality rapid reg rgbd saliency shape signal stereo stitching
structured_light superres surface_matching text tracking video videoio videostab
wechat_qrcode xfeatures2d ximgproc xobjdetect xphoto xstereo
""".split()
if sys.platform != "win32":
    modules += ["bioinspired", "hdf"]

for module in modules:
    if sys.platform == "win32":
        library = prefix / "Library/bin" / f"opencv_{module}{version.replace('.', '')}.dll"
    else:
        extension = "dylib" if sys.platform == "darwin" else "so"
        library = prefix / "lib" / f"libopencv_{module}.{extension}"
    assert library.is_file(), library

record, = (prefix / "conda-meta").glob("libopencv-*.json")
dependencies = {spec.split()[0] for spec in json.loads(record.read_text())["depends"]}
assert not dependencies.intersection({"python", "numpy", "gstreamer", "gst-plugins-base"}), dependencies
