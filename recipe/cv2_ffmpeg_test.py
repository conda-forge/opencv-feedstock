import unittest
import tempfile
import os.path as op
import platform
import shutil
import requests
import cv2


OPENCV_AVI_URL = 'https://github.com/opencv/opencv_extra/raw/master/testdata/highgui/video/VID00003-20100701-2204.avi'


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
        assert cap.read()[0]


if __name__ == '__main__':
    unittest.main()
