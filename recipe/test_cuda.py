"""Check CUDA packaging without a GPU; use --require-gpu for device validation."""
import argparse
import re
import unittest

import cv2
import numpy as np

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("cuda_version")
parser.add_argument("--require-gpu", action="store_true")
args, unittest_args = parser.parse_known_args()
with_cuda = args.cuda_version != "None"
device_count = cv2.cuda.getCudaEnabledDeviceCount()
if args.require_gpu and (not with_cuda or device_count <= 0):
    raise RuntimeError("A CUDA build and a working NVIDIA GPU/driver are required")


def pooling_net():
    net = cv2.dnn.Net()
    net.addLayerToPrev("pool", "Pooling", cv2.CV_32F,
                       {"pool": "MAX", "kernel_size": 2, "stride": 2})
    return net


class TestCUDA(unittest.TestCase):
    def test_build(self):
        info = cv2.getBuildInformation()
        if with_cuda:
            self.assertRegex(info, rf"NVIDIA CUDA:\s+YES \(ver {re.escape(args.cuda_version)}[.,)]", info)
            self.assertRegex(info, r"cuDNN:\s+YES \(ver 9\.", info)
            for name in ("add", "resize", "cvtColor", "createGaussianFilter",
                         "createBackgroundSubtractorMOG2"):
                self.assertTrue(hasattr(cv2.cuda, name), name)
        else:
            self.assertNotRegex(info, r"NVIDIA CUDA:\s+YES", info)
            self.assertFalse(hasattr(cv2.cuda, "resize"))

    def test_pooling_reference(self):
        net = pooling_net()
        net.setInput(np.arange(16, dtype=np.float32).reshape(1, 1, 4, 4))
        np.testing.assert_array_equal(net.forward(), [[[[5, 7], [13, 15]]]])

    @unittest.skipUnless(with_cuda and device_count > 0, "No CUDA device; build checks still run")
    def test_gpu_mat_and_resize(self):
        image = np.arange(48, dtype=np.uint8).reshape(4, 4, 3)
        gpu = cv2.cuda_GpuMat()
        gpu.upload(image)
        np.testing.assert_array_equal(gpu.download(), image)
        actual = cv2.cuda.resize(gpu, (8, 8), interpolation=cv2.INTER_NEAREST).download()
        expected = cv2.resize(image, (8, 8), interpolation=cv2.INTER_NEAREST)
        np.testing.assert_array_equal(actual, expected)

    @unittest.skipUnless(with_cuda and device_count > 0, "No CUDA device; cuDNN execution untested")
    def test_cudnn_pooling(self):
        self.assertIn(cv2.dnn.DNN_TARGET_CUDA,
                      cv2.dnn.getAvailableTargets(cv2.dnn.DNN_BACKEND_CUDA))
        net = pooling_net()
        net.setPreferableBackend(cv2.dnn.DNN_BACKEND_CUDA)
        net.setPreferableTarget(cv2.dnn.DNN_TARGET_CUDA)
        net.setInput(np.arange(16, dtype=np.float32).reshape(1, 1, 4, 4))
        np.testing.assert_array_equal(net.forward(), [[[[5, 7], [13, 15]]]])
        # Refuse a numerically correct result obtained by silently falling back to CPU.
        self.assertIn("CUDA/CUDA", net.dump())


if __name__ == "__main__":
    unittest.main(argv=[__file__, *unittest_args])
