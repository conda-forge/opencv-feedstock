import cv2

# No OPENCV_VIDEOIO_PLUGIN_PATH override: test normal installed-plugin discovery.
assert cv2.videoio_registry.hasBackend(cv2.CAP_GSTREAMER)
assert not cv2.videoio_registry.isBackendBuiltIn(cv2.CAP_GSTREAMER)

cap = cv2.VideoCapture(
    "videotestsrc num-buffers=3 pattern=black ! "
    "video/x-raw,format=BGR,width=64,height=48,framerate=1/1 ! appsink",
    cv2.CAP_GSTREAMER,
)
try:
    assert cap.isOpened(), "GStreamer pipeline did not open"
    assert cap.getBackendName() == "GSTREAMER"
    for _ in range(3):
        ok, frame = cap.read()
        assert ok, "GStreamer did not deliver all frames"
        assert frame.shape == (48, 64, 3), frame.shape
        assert frame.dtype.name == "uint8", frame.dtype
        assert not frame.any(), "Expected a black frame"
    assert not cap.read()[0], "Expected end of stream"
finally:
    cap.release()
