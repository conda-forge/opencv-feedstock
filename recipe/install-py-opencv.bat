if "%PY3K%" == "0" goto py27
if "%PY_VER%" ==  "3.6" goto py3_but_not36
copy %SRC_DIR%\py3\Lib\site-packages\cv* %SP_DIR%
if errorlevel 1 exit /b 1

:py3_but_not36
call conda activate %SRC_DIR%\py3
set REAL_SP_DIR=%SP_DIR%
call conda install -y python=%PY_VER% --override-channels -c https://repo.continuum.io/pkgs/main
pushd build\modules\python3
cmake --build . --target clean --config Release
      find ./ -type f -exec sed -i '' -e "s/python3.6/python${PY_VER}/g" {} \;
      find ./ -type f -exec sed -i '' -e "s/36m/${PY_VER//./}m/g" {} \;
      cp -rf ../../../../work /tmp/py35-work-post-sed
      make -j${CPU_COUNT} ${VERBOSE_CM}
      make install ${VERBOSE_CM}
      cp -rf ${SRC_DIR}/py3/lib/python${PY_VER}/site-packages/cv2* ${REAL_SP_DIR}
      # In-case there are other non-3.6 python 3 versions to be built for:
      find ./ -type f -exec sed -i '' -e "s/python${PY_VER}/python3.6/g" {} \;
      find ./ -type f -exec sed -i '' -e "s/${PY_VER//./}m/py36m/g" {} \;
    popd
  fi
exit /b 0

:py27
copy %SRC_DIR%\py2\Lib\site-packages\cv* %SP_DIR%
if errorlevel 1 exit /b 1
