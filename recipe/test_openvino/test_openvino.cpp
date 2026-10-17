// Usage: test_openvino <identity.onnx> available|missing
//
// "missing": libopencv must load and work without the OpenVINO runtime; the
// dnn OpenVINO backend is not offered and G-API OpenVINO inference throws.
// "available": both run the identity model through OpenVINO.
#include <opencv2/core.hpp>
#include <opencv2/dnn.hpp>
#include <opencv2/gapi.hpp>
#include <opencv2/gapi/infer.hpp>
#include <opencv2/gapi/infer/ov.hpp>

#include <cstring>
#include <iostream>
#include <string>

G_API_NET(IdentityNet, <cv::GMat(cv::GMat)>, "identity-net");

static int fail(const std::string& msg) {
    std::cerr << "FAIL: " << msg << std::endl;
    return 1;
}

int main(int argc, char** argv) {
    if (argc != 3)
        return fail("usage: test_openvino <identity.onnx> available|missing");
    const std::string model = argv[1];
    const bool expected = std::strcmp(argv[2], "available") == 0;

    int sz[] = {1, 3, 64, 64};
    cv::Mat input(4, sz, CV_32F);
    cv::randu(input, 0, 1);

    bool dnn_openvino = false;
    for (const auto& bt : cv::dnn::getAvailableBackends()) {
        // DNN_BACKEND_INFERENCE_ENGINE_NGRAPH (internal value) or the public alias
        if (bt.first == 1000000 || bt.first == cv::dnn::DNN_BACKEND_INFERENCE_ENGINE)
            dnn_openvino = true;
    }
    if (dnn_openvino != expected)
        return fail(std::string("dnn OpenVINO backend available: ") + (dnn_openvino ? "yes" : "no"));
    if (expected) {
        // Only the classic engine dispatches to non-OpenCV backends in 5.0.
        cv::dnn::Net net = cv::dnn::readNetFromONNX(model, cv::dnn::ENGINE_CLASSIC);
        net.setPreferableBackend(cv::dnn::DNN_BACKEND_INFERENCE_ENGINE);
        net.setInput(input);
        cv::Mat out = net.forward();
        if (cv::norm(input.reshape(1, 1), out.reshape(1, 1), cv::NORM_INF) != 0)
            return fail("dnn OpenVINO output differs from input");
    }
    std::cout << "dnn: ok" << std::endl;

    cv::GMat in;
    cv::GComputation comp(cv::GIn(in), cv::GOut(cv::gapi::infer<IdentityNet>(in)));
    auto params = cv::gapi::ov::Params<IdentityNet>{model, "", "CPU"};
    cv::Mat out;
    try {
        comp.apply(cv::gin(input), cv::gout(out), cv::compile_args(cv::gapi::networks(params)));
    } catch (const std::exception& e) {
        if (!expected && std::string(e.what()).find("OpenVINO runtime") != std::string::npos) {
            std::cout << "gapi: ok (" << e.what() << ")" << std::endl;
            return 0;
        }
        return fail(std::string("gapi: ") + e.what());
    }
    if (!expected)
        return fail("gapi OpenVINO inference ran without the OpenVINO runtime");
    if (cv::norm(input.reshape(1, 1), out.reshape(1, 1), cv::NORM_INF) != 0)
        return fail("gapi OpenVINO output differs from input");
    std::cout << "gapi: ok" << std::endl;
    return 0;
}
