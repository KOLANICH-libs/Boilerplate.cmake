# This is free and unencumbered software released into the public domain.

# Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

# In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# For more information, please refer to <https://unlicense.org/>


# This is the library abstracting out common boilerplate in my CMake projects

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}" "${CMAKE_CURRENT_LIST_DIR}/Hardening" "${CMAKE_CURRENT_LIST_DIR}/GenPkgConfig" "${CMAKE_CURRENT_LIST_DIR}/MaximumUpgradeLanguages" "${CMAKE_CURRENT_LIST_DIR}/thirdParty/sanitizers/cmake")


include(ParsePackagingArguments)
include(GenPkgConfig)
include(CPackComponent)
include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

find_package(Sanitizers)

include(Hardening)
include(MaximumUpgradeLanguages)


if(${CMAKE_VERSION} VERSION_GREATER "3.14")
	set(OPTIONAL_ARCH_INDEPENDENT "ARCH_INDEPENDENT")
endif()

macro(pass_through_cpack_vars)
	get_cmake_property(cpackVarsToPassthrough VARIABLES)
	foreach(varName ${cpackVarsToPassthrough})
		if(varName MATCHES "^CPACK_")
			set("${varName}" "${${varName}}" PARENT_SCOPE)
		endif()
	endforeach()
endmacro()

set(DEP_DISCOVERY_PACKAGES_DEBIAN "cmake, pkg-config, pkg-conf")
set(DEP_DISCOVERY_PACKAGES_RPM "${DEP_DISCOVERY_PACKAGES_DEBIAN}")

function(searchLicenseFile parentDir resultVariable)
	file(GLOB res "COPYING" "COPYING.*" "Copying" "Copying.*" "copying" "copying*" "LICENSE" "LICENSE.*" "License" "License.*" "license" "license.*" "UNLICENSE" "UNLICENSE.*")
	set("${resultVariable}" "${res}" PARENT_SCOPE)
endfunction()

function(searchReadMeFile parentDir resultVariable)
	file(GLOB res "ReadMe" "ReadMe.*" "README" "README.*" "READ_ME" "READ_ME.*" "readme" "readme.*")
	set("${resultVariable}" "${res}" PARENT_SCOPE)
endfunction()

macro(initBoilerplate)
	if(CMAKE_PROJECT_NAME STREQUAL PROJECT_NAME)
		set(IS_MAIN_PROJECT ON)
	endif()

	maximum_upgrade_languages_versions()

	option(BUILD_SHARED_LIBS "Build shared libs" ON)

	if(IS_MAIN_PROJECT)
		set(CPACK_PACKAGE_NAME "${PROJECT_NAME}")
		set(CPACK_PACKAGE_DESCRIPTION "${PROJECT_DESCRIPTION}")
		set(CPACK_DEBIAN_PACKAGE_NAME "${CPACK_PACKAGE_NAME}")
		set(CPACK_RPM_PACKAGE_NAME "${CPACK_PACKAGE_NAME}")
		set(CPACK_PACKAGE_HOMEPAGE_URL "${PROJECT_HOMEPAGE_URL}")
		set(CPACK_PACKAGE_MAINTAINER "${CPACK_PACKAGE_VENDOR}")
		set(CPACK_DEBIAN_PACKAGE_MAINTAINER "${CPACK_PACKAGE_MAINTAINER}")
		set(CPACK_PACKAGE_MAINTAINER "${CPACK_PACKAGE_VENDOR}")
		set(CPACK_DEB_COMPONENT_INSTALL ON)
		set(CPACK_RPM_COMPONENT_INSTALL ON)
		set(CPACK_NSIS_COMPONENT_INSTALL ON)
		#set(CPACK_DEBIAN_ENABLE_COMPONENT_DEPENDS ON)
		#set(CPACK_RPM_ENABLE_COMPONENT_DEPENDS ON)
		set(CPACK_DEBIAN_COMPRESSION_TYPE "xz")

		searchLicenseFile("${CMAKE_CURRENT_SOURCE_DIR}" CPACK_RESOURCE_FILE_LICENSE)
		searchReadMeFile("${CMAKE_CURRENT_SOURCE_DIR}" CPACK_RESOURCE_FILE_README)
	endif()
endmacro()
initBoilerplate()

macro(_currentDirScanSources NON_RECURSIVE_GLOB)
	if(_SOURCES)
		set(SRCFILES "${_SOURCES}")
	else()
		if(${NON_RECURSIVE_GLOB})
			set(GLOB_TYPE "GLOB")
		else()
			set(GLOB_TYPE "GLOB_RECURSE")
		endif()
		#message(STATUS "NON_RECURSIVE_GLOB ${NON_RECURSIVE_GLOB}")
		#message(STATUS "GLOB_TYPE ${GLOB_TYPE}")
		file("${GLOB_TYPE}" SRCFILES "${CMAKE_CURRENT_SOURCE_DIR}/*.c" "${CMAKE_CURRENT_SOURCE_DIR}/*.cc" "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp" "${CMAKE_CURRENT_SOURCE_DIR}/*.cxx" "${CMAKE_CURRENT_SOURCE_DIR}/*.c++")
	endif()
endmacro()


function(_buildAndPackageLib _NAME)
	set(FAKE_ARGN "NAME;${_NAME};${ARGN}")  # working around CMake bugs! See the error message in `parse_packaging_arguments` for making a default value for `CMAKE_EXPORT_NAMESPACE`  if `_NAME` is not set
	parse_packaging_arguments("" #prefix
		"TARGET_NAME_WITH_LIB_PREFIX;DO_NOT_ADD_LIB_PREFIX;NON_RECURSIVE_GLOB" # options
		"NAME;INSTALL_INCLUDE_DIR;INSTALL_LIB_DIR;COMPONENT;DESCRIPTION;VERSION;URL;TYPE;CMAKE_EXPORT_NAME;CMAKE_EXPORT_NAMESPACE;USE_INCLUDES_FROM" # one_value_keywords
		"SOURCES;PUBLIC_INCLUDES;PUBLIC_LIBS;PRIVATE_LIBS;PRIVATE_INCLUDES" #multi_value_keywords
		${FAKE_ARGN}
	)

	string(TOUPPER "${_NAME}" LIB_NAME_UPPER)

	if(_TARGET_NAME_WITH_LIB_PREFIX)
		set(TARGET_NAME "lib${_NAME}")
		set(_DO_NOT_ADD_LIB_PREFIX ON)
	else()
		set(TARGET_NAME "${_NAME}")
	endif()

	if(_TYPE)
		if(_TYPE STREQUAL "INTERFACE")
		else()
			_currentDirScanSources("${_NON_RECURSIVE_GLOB}")
		endif()
	else()
		_currentDirScanSources("${_NON_RECURSIVE_GLOB}")
		if(SRCFILES)
			if(BUILD_SHARED_LIBS)
				set(_TYPE "SHARED")
			else()
				set(_TYPE "STATIC")
			endif()
		else()
			if(_PUBLIC_INCLUDES)
				set(_TYPE "INTERFACE")
			else()
				message(FATAL_ERROR "Library ${_NAME} is of unknown type. The current source dir contains no source code files, so it cannot be SHARED or STATIC. You don't provide PUBLIC_INCLUDES, so it cannot be INTERFACE (a header-only library)")
			endif()
		endif()
		message(STATUS "Library ${_NAME} will be of autodetected type ${_TYPE}")
	endif()

	if(_TYPE STREQUAL "INTERFACE")
		add_library("${TARGET_NAME}" INTERFACE)
		set(_ARCH_INDEPENDENT ON)
	else()
		add_library("${TARGET_NAME}" "${_TYPE}" "${SRCFILES}")
		set(_ARCH_INDEPENDENT OFF)
	endif()

	if(_ARCH_INDEPENDENT)
		string(REPLACE "/${CMAKE_LIBRARY_ARCHITECTURE}" "" _INSTALL_LIB_DIR "${_INSTALL_LIB_DIR}")
	endif()

	if(_TYPE STREQUAL "INTERFACE")
		set(TARGET_PUBLIC_PROP_TYPE "INTERFACE")
	else()
		set(TARGET_PUBLIC_PROP_TYPE "PUBLIC")
		target_compile_definitions("${TARGET_NAME}" PRIVATE "-D${LIB_NAME_UPPER}_EXPORTS")
		set_target_properties("${TARGET_NAME}" PROPERTIES
			SOVERSION "${_VERSION}"
			CXX_STANDARD 20
		)
		if(_DO_NOT_ADD_LIB_PREFIX)
			set_target_properties("${TARGET_NAME}" PROPERTIES
				PREFIX ""
			)
		endif()
		harden("${TARGET_NAME}")
		add_sanitizers("${TARGET_NAME}")
	endif()

	if(_PUBLIC_INCLUDES)
		target_include_directories("${TARGET_NAME}" ${TARGET_PUBLIC_PROP_TYPE} "$<INSTALL_INTERFACE:${_INSTALL_INCLUDE_DIR}>" "$<BUILD_INTERFACE:${_PUBLIC_INCLUDES}>")
	else()
		if(_TYPE STREQUAL "INTERFACE")
			message(FATAL_ERROR "Library ${_NAME} is a header-only one and MUST have headers. You must provide PUBLIC_INCLUDES")
		endif()
	endif()

	if(_PRIVATE_INCLUDES)
		message(STATUS "_PRIVATE_INCLUDES ${_PRIVATE_INCLUDES}")
		target_include_directories("${TARGET_NAME}" PRIVATE "$<INSTALL_INTERFACE:${_INSTALL_INCLUDE_DIR}>" "$<BUILD_INTERFACE:${_PRIVATE_INCLUDES}>")
	endif()

	target_link_libraries("${TARGET_NAME}" ${TARGET_PUBLIC_PROP_TYPE} ${_PUBLIC_LIBS} PRIVATE ${_PRIVATE_LIBS})

	if(_TYPE STREQUAL "SHARED")
		set(SDK_PACKAGE_IS_MAIN_PACKAGE OFF)
		if(_PUBLIC_INCLUDES)
			if(NOT _USE_INCLUDES_FROM)
				set(GENERATE_SEPARATE_SDK_PACKAGE ON)
			else()
				set(GENERATE_SEPARATE_SDK_PACKAGE OFF)
			endif()
		else()
			set(GENERATE_SEPARATE_SDK_PACKAGE OFF)
		endif()
	else()
		set(SDK_PACKAGE_IS_MAIN_PACKAGE ON)
		set(GENERATE_SEPARATE_SDK_PACKAGE OFF)
	endif()

	string(TOUPPER "${_COMPONENT}" COMPONENT_NAME_UPPER)


	set(PKG_CONFIG_NAME "${CMAKE_EXPORT_NAME}")

	if(_COMPONENT)
		if(SDK_PACKAGE_IS_MAIN_PACKAGE)
			set(SDK_COMPONENT_NAME "${_COMPONENT}")
			unset(_COMPONENT)
			message(STATUS "Generating only SDK package (${SDK_COMPONENT_NAME}) for ${_NAME}")
			set(AUTODISCOVERY_CONFIGS_COMPONENT_NAME "${SDK_COMPONENT_NAME}")
		else()
			if(GENERATE_SEPARATE_SDK_PACKAGE)
				set(SDK_COMPONENT_NAME "${_COMPONENT}_sdk")
				message(STATUS "Generating a binary package (${_COMPONENT}) and a SDK package (${SDK_COMPONENT_NAME}) for ${_NAME}")
				set(AUTODISCOVERY_CONFIGS_COMPONENT_NAME "${SDK_COMPONENT_NAME}")
			else()
				message(STATUS "Generating a binary package (${_COMPONENT}) and for ${_NAME} and putting autodiscovery configs into it")
				set(AUTODISCOVERY_CONFIGS_COMPONENT_NAME "${_COMPONENT}")
			endif()
		endif()

		if(_COMPONENT)
			cpack_add_component("${_COMPONENT}"
				DISPLAY_NAME "${_NAME}"
				DESCRIPTION "${_DESCRIPTION}"
			)
			list(APPEND CPACK_COMPONENTS_ALL "${_COMPONENT}")  # strangely, not populated automatically correctly
		endif()

		# Don't if(_COMPONENT) them, used later even if _COMPONENT is FALSE !
		set("CPACK_DEBIAN_${COMPONENT_NAME_UPPER}_PACKAGE_NAME" "lib${_NAME}")
		set("CPACK_RPM_${COMPONENT_NAME_UPPER}_PACKAGE_NAME" "lib${_NAME}")

		if(_USE_INCLUDES_FROM)
			message(STATUS "USE_INCLUDES_FROM currently only suppreses generation of SDK package.")
		endif()

		if(SDK_COMPONENT_NAME)
			string(TOUPPER "${SDK_COMPONENT_NAME}" SDK_COMPONENT_NAME_UPPER)

			if(_COMPONENT)
				cpack_add_component(${SDK_COMPONENT_NAME}
					DISPLAY_NAME "Development files for ${_COMPONENT}"
					DESCRIPTION "Headers and other files needed for using `${_COMPONENT}` in own software"
					DEPENDS "${_COMPONENT}"
				)
				set("CPACK_DEBIAN_${SDK_COMPONENT_NAME_UPPER}_PACKAGE_DEPENDS" "${CPACK_DEBIAN_${COMPONENT_NAME_UPPER}_PACKAGE_NAME}")
				set("CPACK_RPM_${SDK_COMPONENT_NAME_UPPER}_PACKAGE_DEPENDS" "${CPACK_RPM_${COMPONENT_NAME_UPPER}_PACKAGE_NAME}")
			else()
				cpack_add_component(${SDK_COMPONENT_NAME}
					DISPLAY_NAME "${_NAME}"
					DESCRIPTION "${_DESCRIPTION}"
				)
			endif()

			set("CPACK_DEBIAN_${SDK_COMPONENT_NAME_UPPER}_PACKAGE_NAME" "${CPACK_DEBIAN_${COMPONENT_NAME_UPPER}_PACKAGE_NAME}-dev")
			set("CPACK_DEBIAN_${SDK_COMPONENT_NAME_UPPER}_PACKAGE_SUGGESTS" "${DEP_DISCOVERY_PACKAGES_DEBIAN}")

			set("CPACK_RPM_${SDK_COMPONENT_NAME_UPPER}_PACKAGE_NAME" "${CPACK_RPM_${COMPONENT_NAME_UPPER}_PACKAGE_NAME}-devel")
			set("CPACK_RPM_${SDK_COMPONENT_NAME_UPPER}_PACKAGE_SUGGESTS" "${DEP_DISCOVERY_PACKAGES_RPM}")

			list(APPEND CPACK_COMPONENTS_ALL "${SDK_COMPONENT_NAME}")  # strangely, not populated automatically correctly
		endif()
	else()
		message(FATAL_ERROR "No COMPONENT was specified for the lib ${_NAME}")
	endif()

	if(_PUBLIC_INCLUDES)
		foreach(include ${_PUBLIC_INCLUDES})
			if(IS_DIRECTORY "${include}")
				file(GLOB_RECURSE HEADERS "${include}/*.h" "${include}/*.hxx" "${include}/*.hpp")
				foreach(headerFile ${HEADERS})
					get_filename_component(headerFileParentDir "${headerFile}" DIRECTORY)
					file(RELATIVE_PATH headerFileRelParentDir "${include}" "${headerFileParentDir}")

					install(FILES "${headerFile}"
						DESTINATION "${_INSTALL_INCLUDE_DIR}/${headerFileRelParentDir}"
						COMPONENT "${SDK_COMPONENT_NAME}"
					)
					# CMake Error in ...: Target "libclpp" INTERFACE_SOURCES property contains path: "..." which is prefixed in the source directory.
					#target_sources("${TARGET_NAME}" ${TARGET_PUBLIC_PROP_TYPE} "${headerFile}")
				endforeach()
			else()
				install(FILES ${include}
					DESTINATION "${_INSTALL_INCLUDE_DIR}"
					COMPONENT "${SDK_COMPONENT_NAME}"
				)
				#target_sources("${TARGET_NAME}" ${TARGET_PUBLIC_PROP_TYPE} "${include}")
			endif()
		endforeach()
	endif()

	set(CMAKE_EXPORT_NAME "${_NAME}")

	install(TARGETS "${TARGET_NAME}"
		EXPORT ${CMAKE_EXPORT_NAME}
		LIBRARY
			DESTINATION "${_INSTALL_LIB_DIR}"
			COMPONENT "${_COMPONENT}"
		ARCHIVE
			DESTINATION "${_INSTALL_LIB_DIR}"
			COMPONENT "${SDK_COMPONENT_NAME}"
		INCLUDES
			DESTINATION "${_INSTALL_INCLUDE_DIR}"
			# COMPONENT "${SDK_COMPONENT_NAME}" # component is not allowed for includes! Headers are installed separately! Includes only marks the headers for export
	)

	# BUG IN CMake! When cross-compiling, shared libs are not installed!
	if(_TYPE STREQUAL "SHARED")
		if(CMAKE_CROSSCOMPILING)
			message(STATUS "Overcoming CMake bug with non-installing shared libs while cross-compiling")
			install(FILES "$<TARGET_FILE:${TARGET_NAME}>"
				DESTINATION "${_INSTALL_LIB_DIR}"
				COMPONENT "${_COMPONENT}"
			)
		endif()
	endif()

	if(_ARCH_INDEPENDENT)
		set(_ARCH_INDEPENDENT "ARCH_INDEPENDENT")
	else()
		set(_ARCH_INDEPENDENT "")
	endif()
	

	generate_and_install_autodiscovery_configs("${TARGET_NAME}"
		NAME "${_NAME}"
		VERSION "${_VERSION}"
		DESCRIPTION "${_DESCRIPTION}"
		URL "${_URL}"
		COMPONENT "${AUTODISCOVERY_CONFIGS_COMPONENT_NAME}"
		INSTALL_LIB_DIR "${_INSTALL_LIB_DIR}"
		INSTALL_INCLUDE_DIR "${_INSTALL_INCLUDE_DIR}"
		PKG_CONFIG_REQUIRES ${_PKG_CONFIG_REQUIRES}
		PKG_CONFIG_CONFLICTS ${_PKG_CONFIG_CONFLICTS}
		CMAKE_EXPORT_NAME "${CMAKE_EXPORT_NAME}"
		CMAKE_EXPORT_NAMESPACE "${_CMAKE_EXPORT_NAMESPACE}"
		${_ARCH_INDEPENDENT}
		PUBLIC_LIBS "${_PUBLIC_LIBS}"
		PUBLIC_INCLUDES "${_PUBLIC_INCLUDES}"
	)

	pass_through_cpack_vars()  # into macro scope (which is the same as the scope from which the macro was called). Unfortunately we have to do this ssince cpack_add_component populates info into some variables
endfunction()

macro(buildAndPackageLib)
	cmake_parse_arguments("" #prefix
		"DO_NOT_PASSTHROUGH" # options
		"" # one_value_keywords
		"" #multi_value_keywords
		${ARGN}
	)
	_buildAndPackageLib(${_UNPARSED_ARGUMENTS})
	if(_DO_NOT_PASSTHROUGH)  # ToDo: Find a better way. We need to detect the scope without a parent scope ourselves, so we can populate this var ourselves
	else()
		pass_through_cpack_vars()  # into parent dir
	endif()
endmacro()

function(generate_cmake_autodiscovery_configs TARGET_NAME)
	parse_packaging_arguments("" #prefix
		"ARCH_INDEPENDENT;FROM_PKG_CONFIG" # options
		"CMAKE_EXPORT_NAME;CMAKE_EXPORT_NAMESPACE;COMPONENT;INSTALL_LIB_DIR" # one_value_keywords
		"" #multi_value_keywords
		${ARGN}
	)

	if(_ARCH_INDEPENDENT)
		set(_ARCH_INDEPENDENT "${OPTIONAL_ARCH_INDEPENDENT}")
	endif()

	set(CMAKE_CONFIG_FILE_BASENAME "${_CMAKE_EXPORT_NAME}Config.cmake")
	set(CMAKE_EXPORT_FILE_BASENAME "${_CMAKE_EXPORT_NAME}Export.cmake")
	set(CMAKE_CONFIG_VERSION_FILE_BASENAME "${_CMAKE_EXPORT_NAME}ConfigVersion.cmake")
	set(CMAKE_CONFIG_VERSION_FILE_NAME "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_CONFIG_VERSION_FILE_BASENAME}")

	set(EXPORT_NAMESPACE "${_CMAKE_EXPORT_NAMESPACE}::")

	export(TARGETS "${TARGET_NAME}"
		NAMESPACE "${EXPORT_NAMESPACE}"
		FILE "${CMAKE_EXPORT_FILE_BASENAME}"
		EXPORT_LINK_INTERFACE_LIBRARIES
	)

	if(_FROM_PKG_CONFIG)
		set(CMAKE_CONFIG_FILE_NAME "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_CONFIG_FILE_BASENAME}")
		configure_package_config_file("${PackagingTemplatesDir}/CMakeConfig.cmake.in" "${CMAKE_CONFIG_FILE_NAME}"
			INSTALL_DESTINATION "${_INSTALL_LIB_DIR}/cmake"
		)
		install(FILES "${CMAKE_CONFIG_FILE_NAME}"
			DESTINATION "${_INSTALL_LIB_DIR}/cmake/${CMAKE_EXPORT_NAME}"
			COMPONENT "${_COMPONENT}"
		)
	else()
		install(EXPORT "${_CMAKE_EXPORT_NAME}"
			FILE "${CMAKE_CONFIG_FILE_BASENAME}"
			NAMESPACE "${EXPORT_NAMESPACE}"
			DESTINATION "${_INSTALL_LIB_DIR}/cmake/${_CMAKE_EXPORT_NAME}"
			COMPONENT "${_COMPONENT}"
		)
	endif()

	write_basic_package_version_file(
		"${CMAKE_CONFIG_VERSION_FILE_NAME}"
		VERSION "100500.100500.100500"  # any version of same bitness suits. CMake cannot compare to infinity, so use a large number we expect to be greater than any future version
		COMPATIBILITY AnyNewerVersion
		"${_ARCH_INDEPENDENT}"
	)
	install(FILES "${CMAKE_CONFIG_VERSION_FILE_NAME}"
		DESTINATION "${_INSTALL_LIB_DIR}/cmake/${CMAKE_EXPORT_NAME}"
		COMPONENT "${_COMPONENT}"
	)
endfunction()

function(generate_and_install_autodiscovery_configs TARGET_NAME)
	parse_packaging_arguments(""
		"ARCH_INDEPENDENT" # options
		"NAME;VERSION;DESCRIPTION;URL;COMPONENT;INSTALL_LIB_DIR;INSTALL_INCLUDE_DIR;CMAKE_EXPORT_NAME;CMAKE_EXPORT_NAMESPACE;PKG_CONFIG_NAME" # one_value_keywords
		"PKG_CONFIG_REQUIRES;PKG_CONFIG_CONFLICTS" # multi_value_keywords
		${ARGN}
	)

	configure_pkg_config_file("${TARGET_NAME}"
		NAME "${_PKG_CONFIG_NAME}"
		VERSION "${_VERSION}"
		DESCRIPTION "${_DESCRIPTION}"
		URL "${_URL}"
		COMPONENT "${_COMPONENT}"
		INSTALL_LIB_DIR "${_INSTALL_LIB_DIR}"
		INSTALL_INCLUDE_DIR "${_INSTALL_INCLUDE_DIR}"
		REQUIRES ${_PKG_CONFIG_REQUIRES}
		CONFLICTS ${_PKG_CONFIG_CONFLICTS}
	)

	generate_cmake_autodiscovery_configs("${TARGET_NAME}"
		CMAKE_EXPORT_NAME "${_CMAKE_EXPORT_NAME}"
		CMAKE_EXPORT_NAMESPACE "${_CMAKE_EXPORT_NAMESPACE}"
		COMPONENT "${_COMPONENT}"
		INSTALL_LIB_DIR "${_INSTALL_LIB_DIR}"
		"${_ARCH_INDEPENDENT}"
	)
endfunction()
