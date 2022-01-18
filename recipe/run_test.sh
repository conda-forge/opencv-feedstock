set -x
${CXX} $RECIPE_DIR/test.cpp -I$PREFIX/include/opencv4  -L$PREFIX/lib -o test
[ $(./test) != "$PKG_VERSION" ] && exit 1

if [ $($PYTHON -c 'import cv2; print(cv2.__version__)') == "$PKG_VERSION" ];then
    echo pass
fi

