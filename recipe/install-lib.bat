@echo ON

cd build
cmake --install .
if %ERRORLEVEL% neq 0 exit 1

cd ..
rmdir /s /q build
