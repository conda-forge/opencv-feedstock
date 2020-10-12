import unittest
import platform
import numpy as np
import cv2


@unittest.skipIf(platform.system() == 'Windows',
                 'FFMPEG currently not built on Windows')
class TestVideoRead(unittest.TestCase):
    def test_load_avi(self):
        cap = cv2.VideoCapture('test.avi')
        res, frame = cap.read()
        self.assertTrue(res, "Can not read video frame from file")


class TestImageRead(unittest.TestCase):
    def test_load_image_png(self):
        im = cv2.imread('color_palette_alpha.png')
        self.assertIsNotNone(im, "Cannot read png image from file")

    def test_load_image_jpg(self):
        im = cv2.imread('test_1_c1.jpg')
        self.assertIsNotNone(im, "Cannot read jpg image from file")


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
