
pushd build
  cmake --build . --target INSTALL --config Release
  if errorlevel 1 exit 1

  dir /s /q %LIBRARY_PREFIX%
  robocopy %LIBRARY_PREFIX%\ %LIBRARY_PREFIX%\ /E
  if %ERRORLEVEL% GEQ 8 exit 1

  rem Remove files installed in the wrong locations
  rd /S /Q "%LIBRARY_BIN%\Release"
popd

rem RD is a bit horrible and doesn't return an errorcode properly, so
rem the errorcode from robocopy is propagated (which is non-zero), so we
rem forcibly exit 0 here
exit 0
