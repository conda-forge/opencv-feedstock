#!/usr/bin/env bash

OUTDIR=~

#-- List of active modules: opencv_calib3d;opencv_core;opencv_features2d;opencv_flann;opencv_highgui;opencv_imgcodecs;opencv_imgproc;opencv_java_bindings_generator;opencv_ml;opencv_objdetect;opencv_photo;
#                           opencv_python_bindings_generator;opencv_shape;opencv_stitching;opencv_superres;opencv_video;opencv_videoio;opencv_videostab;opencv_aruco;opencv_bgsegm;opencv_bioinspired;opencv_ccalib;opencv_datasets;opencv_dpm;opencv_face;opencv_freetype;opencv_fuzzy;opencv_hdf;opencv_hfs;opencv_img_hash;opencv_line_descriptor;opencv_optflow;opencv_phase_unwrapping;opencv_plot;opencv_reg;opencv_rgbd;opencv_saliency;opencv_stereo;opencv_structured_light;opencv_surface_matching;opencv_tracking;opencv_xfeatures2d;opencv_ximgproc;opencv_xobjdetect;opencv_xphoto
# ..
# -- BUILD_opencv_python2=1
# -- BUILD_opencv_python3=1
#-- List of active modules: opencv_calib3d;opencv_core;opencv_features2d;opencv_flann;opencv_highgui;opencv_imgcodecs;opencv_imgproc;opencv_java_bindings_generator;opencv_ml;opencv_objdetect;opencv_photo;
#                           opencv_python_bindings_generator;
#                           opencv_python2;opencv_python3;
#                           opencv_shape;opencv_stitching;opencv_superres;opencv_video;opencv_videoio;opencv_videostab;opencv_aruco;opencv_bgsegm;opencv_bioinspired;opencv_ccalib;opencv_datasets;opencv_dpm;opencv_face;opencv_freetype;opencv_fuzzy;opencv_hdf;opencv_hfs;opencv_img_hash;opencv_line_descriptor;opencv_optflow;opencv_phase_unwrapping;opencv_plot;opencv_reg;opencv_rgbd;opencv_saliency;opencv_stereo;opencv_structured_light;opencv_surface_matching;opencv_tracking;opencv_xfeatures2d;opencv_ximgproc;opencv_xobjdetect;opencv_xphoto
# -- ocv_define_module( calib3d opencv_imgproc opencv_features2d WRAP java python )
# -- ocv_add_module( calib3d opencv_imgproc opencv_features2d WRAP java python )

# We are not making it into:
# -- OPENCV_MODULES_BUILD=opencv_calib3d;opencv_core;opencv_features2d;opencv_flann;opencv_highgui;opencv_imgcodecs;opencv_imgproc;opencv_java_bindings_generator;opencv_ml;opencv_objdetect;opencv_photo;opencv_python_bindings_generator
# But are (well, for one Python anyway: opencv_python2_7_15) into:
# -- OPENCV_MODULES_DISABLED_FORCE=opencv_cudaarithm;opencv_cudabgsegm;opencv_cudacodec;opencv_cudafeatures2d;opencv_cudafilters;opencv_cudaimgproc;opencv_cudalegacy;opencv_cudaobjdetect;opencv_cudaoptflow;opencv_cudastereo;opencv_cudawarping;opencv_cudev;opencv_dnn;opencv_java;opencv_js;opencv_python2_7_15

# Are we not making it into 'List of active modules' first? Nope, first failure is around OPENCV_MODULES_{BUILD,DISABLED_FORCE}

set -x
for _OPENCV_USE_N_PYTHON_PATCH in 1 0; do
# for _OPENCV_USE_N_PYTHON_PATCH in 1; do
  if [[ ${_OPENCV_USE_N_PYTHON_PATCH} == 1 ]]; then
    SUFFIX=.new
  else
    SUFFIX=.old
  fi
  export OPENCV_USE_N_PYTHON_PATCH=${_OPENCV_USE_N_PYTHON_PATCH}
  rm -rf ${OUTDIR}/opencv-build
  mkdir -p ${OUTDIR}/opencv-build
  ln -s /opt/git_cache ${OUTDIR}/opencv-build/git_cache
  ln -s /opt/src_cache ${OUTDIR}/opencv-build/src_cache
  conda-build ~/conda/aggregate/opencv-feedstock -m ~/conda/aggregate/conda_build_config.yaml --croot ${OUTDIR}/opencv-build --no-build-id 2>&1 | tee ${OUTDIR}/opencv-build/build.log
  rm -rf ${OUTDIR}/opencv-build${SUFFIX}
  mv ${OUTDIR}/opencv-build ${OUTDIR}/opencv-build${SUFFIX}
done

bcompare ${OUTDIR}/opencv-build.old ${OUTDIR}/opencv-build.new &
