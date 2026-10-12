"""Feature checks that work without a display, camera or GPU driver."""
from importlib import metadata
from pathlib import Path
import re
import sys
import unittest

import cv2
import numpy as np


class TestFeatures(unittest.TestCase):
    def test_build_features(self):
        info = cv2.getBuildInformation()
        for pattern in (
            r"OpenCL:\s+YES",
            r"Parallel framework:\s+TBB",
            r"Lapack:\s+YES",
            r"JPEG 2000:\s+OpenJPEG",
        ):
            self.assertRegex(info, pattern, info)
        if re.search(r"GUI:\s+QT", info):
            self.assertRegex(info, r"QT OpenGL support:\s+YES", info)

    def test_umat_cpu_fallback(self):
        cv2.ocl.setUseOpenCL(False)
        image = np.arange(300, dtype=np.uint8).reshape(10, 10, 3)
        expected = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        actual = cv2.cvtColor(cv2.UMat(image), cv2.COLOR_BGR2GRAY).get()
        np.testing.assert_array_equal(actual, expected)

    def test_dnn_umat_blob(self):
        image = np.arange(300, dtype=np.uint8).reshape(10, 10, 3)
        blob = cv2.dnn.blobFromImageWithParams(cv2.UMat(image), blob=cv2.UMat())
        np.testing.assert_array_equal(blob.get(), cv2.dnn.blobFromImage(image))

    def test_ocr(self):
        prefix = Path(sys.prefix) / ("Library" if sys.platform == "win32" else "")
        tessdata = prefix / "share/tessdata"
        self.assertTrue((tessdata / "eng.traineddata").is_file(), tessdata)
        ocr = cv2.text.OCRTesseract_create(str(tessdata), "eng", "", 3, 6)
        image = np.full((160, 600, 3), 255, dtype=np.uint8)
        cv2.putText(image, "HELLO", (30, 110), cv2.FONT_HERSHEY_SIMPLEX, 3, (0, 0, 0), 6)
        self.assertIn("HELLO", ocr.run(image, 0).upper())

    def test_gstreamer_is_optional(self):
        self.assertFalse(cv2.videoio_registry.hasBackend(cv2.CAP_GSTREAMER))

    def test_video_backend(self):
        if sys.platform.startswith("linux"):
            self.assertNotEqual(cv2.videoio_registry.getBackendName(cv2.CAP_V4L), "Unknown")

    def test_pip_metadata(self):
        for name in ("opencv-python", "opencv-python-headless"):
            self.assertEqual(metadata.version(name), cv2.__version__)


if __name__ == "__main__":
    unittest.main()
