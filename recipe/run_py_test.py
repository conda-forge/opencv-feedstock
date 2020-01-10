import unittest
import os.path as op
import platform
import shutil
import tempfile

import numpy as np
import requests

import cv2

OPENCV_AVI_URL = 'https://github.com/opencv/opencv_extra/raw/master/testdata/highgui/video/VID00003-20100701-2204.avi'
OPENCV_IMAGE_URL = 'https://github.com/opencv/opencv_extra/raw/master/testdata/highgui/readwrite/color_palette_alpha.png'

@unittest.skipIf(platform.system() == 'Windows',
                 'FFMPEG currently not built on Windows')
class TestVideoRead(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.temp_dir = tempfile.mkdtemp()
        cls.avi_path = op.join(cls.temp_dir, 'test.avi')
        req = requests.get(OPENCV_AVI_URL, stream=True)
        with open(cls.avi_path, 'wb') as f:
            shutil.copyfileobj(req.raw, f)

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.avi_path, ignore_errors=True)

    def test_load_avi(self):
        cap = cv2.VideoCapture(self.avi_path)
        res, frame = cap.read()
        self.assertTrue(res, "Can not read video frame from file")


class TestImageRead(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp_dir = tempfile.mkdtemp()
        cls.image_path = op.join(cls.temp_dir, 'test.png')
        req = requests.get(OPENCV_IMAGE_URL, stream=True)
        with open(cls.image_path, 'wb') as f:
            shutil.copyfileobj(req.raw, f)

    @classmethod
    def tearDownClass(cls):
        shutil.rmtree(cls.image_path, ignore_errors=True)

    def test_load_image(self):
        im = cv2.imread(self.image_path)
        self.assertIsNotNone(im, "Cannot read image from file")


class TestGEMM(unittest.TestCase):
    def test_gemm_big(self):
        sz = (500, 500)
        a = np.ones(sz, dtype=float)
        b = np.eye(sz[0])
        c = np.ones(sz, dtype=float)
        x = cv2.gemm(a, b, 2, c, 3)
        gold = np.full(sz, 5, dtype=float)
        self.assertTrue(np.array_equal(gold, x), "Array returned by GEMM is not valid")


if __name__ == '__main__':
    unittest.main()
