
pushd build
  cmake --build . --target INSTALL --config Release
  if errorlevel 1 exit 1

  if "%ARCH%" == "32" ( set "OPENCV_ARCH=86")
  if "%ARCH%" == "64" ( set "OPENCV_ARCH=64")

  dir /s /q %LIBRARY_PREFIX%
  robocopy %LIBRARY_PREFIX%\x%OPENCV_ARCH%\vc%VS_MAJOR%\ %LIBRARY_PREFIX%\ /E
  if %ERRORLEVEL% GEQ 8 exit 1

  rem Remove files installed in the wrong locations
  rd /S /Q "%LIBRARY_BIN%\Release"
  rd /S /Q "%LIBRARY_PREFIX%\x%OPENCV_ARCH%"

popd

rem RD is a bit horrible and doesn't return an errorcode properly, so
rem the errorcode from robocopy is propagated (which is non-zero), so we
rem forcibly exit 0 here
exit 0
