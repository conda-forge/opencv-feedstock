import unittest
import platform

import numpy as np

import cv2

@unittest.skipIf(platform.system() == 'Windows',
                 'FFMPEG currently not built on Windows')
class TestVideoRead(unittest.TestCase):

    @classmethod
    def setUpClass(cls):
        cls.avi_path = 'VID00003-20100701-2204.avi'

    def test_load_avi(self):
        cap = cv2.VideoCapture(self.avi_path)
        res, frame = cap.read()
        self.assertTrue(res, "Can not read video frame from file")


class TestGEMM(unittest.TestCase):
    def test_gemm_big(self):
        sz = (500, 500)
        a = np.ones(sz, dtype=float)
        b = np.eye(sz[0])
        c = np.ones(sz, dtype=float)
        x = cv2.gemm(a, b, 2, c, 3)
        gold = np.full(sz, 5, dtype=float)
        self.assertTrue(np.array_equal(gold, x),
                        "Array returned by GEMM is not valid")


if __name__ == '__main__':
    unittest.main()
