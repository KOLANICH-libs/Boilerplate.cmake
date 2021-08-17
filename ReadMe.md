Boilerplate.cmake
=================


My boilerplate for CMake-based C++ libraries.

Does the following:

* detects library type, INTERFACE or SHARED
* finds sources and builds a lib with them
* hardens it with my `Hardening.cmake`
* generates autodiscovery configs:
    * CMake
    * pkg-config
* Packages everything using CPack:
    * for a header-only lib generates single package
    * for a shared lib generates 2 packages, 1 for the lib (`lib*`) and 1 for haders (`lib*-dev`)
