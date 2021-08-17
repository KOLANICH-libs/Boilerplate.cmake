# This is free and unencumbered software released into the public domain.

# Anyone is free to copy, modify, publish, use, compile, sell, or distribute this software, either in source code form or as a compiled binary, for any purpose, commercial or non-commercial, and by any means.

# In jurisdictions that recognize copyright laws, the author or authors of this software dedicate any and all copyright interest in the software to the public domain. We make this dedication for the benefit of the public at large and to the detriment of our heirs and successors. We intend this dedication to be an overt act of relinquishment in perpetuity of all present and future rights to this software under copyright law.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

# For more information, please refer to <https://unlicense.org/>


# This is the library implementing a function making it easier to parse arguments related to packaging in functions related to packaging.

string(REPLACE "/${CMAKE_LIBRARY_ARCHITECTURE}" "" CMAKE_INSTALL_LIBDIR_ARCHIND "${CMAKE_INSTALL_LIBDIR}")

set(CMAKE_IS_PIECE_OF_SHIT "CMake is a piece of shit and coalesces the values. Passing an empty string will ... cause the next keyword be interpreted as the value. You must either just stop using this piece of shit and use other build system with less broken scripting language, such as Meson, depending on python, or set this value or set")

function(parse_packaging_arguments prefix options single_values lists)
	cmake_parse_arguments("${prefix}"
		"${options}"
		"${single_values}"
		"${lists}"
		${ARGN}
	)

	if(_DEBUG_PARSE_PACKAGING_ARGUMENTS)
		foreach(varName ${options} ${single_values} ${lists})
			message(STATUS "parsed value ${prefix}_${varName} ${${prefix}_${varName}}")
		endforeach()
	endif()

	if("NAME" IN_LIST single_values)
	endif()
	if("COMPONENT" IN_LIST single_values)
	endif()
	if("VERSION" IN_LIST single_values)
		if(${prefix}_VERSION)
		else()
			set(${prefix}_VERSION "${CPACK_PACKAGE_VERSION}")
		endif()
	endif()
	if("DESCRIPTION" IN_LIST single_values)
		if(${prefix}_DESCRIPTION)
		else()
			set(${prefix}_DESCRIPTION "${CPACK_PACKAGE_DESCRIPTION}")
		endif()
	endif()
	if("URL" IN_LIST single_values)
		if(${prefix}_URL)
		else()
			set(${prefix}_URL "${CPACK_PACKAGE_HOMEPAGE_URL}")
		endif()
	endif()
	if("INSTALL_LIB_DIR" IN_LIST single_values)
		if(${prefix}_INSTALL_LIB_DIR)
		else()
			if("ARCH_INDEPENDENT" IN_LIST options AND ${prefix}_ARCH_INDEPENDENT)
				set(${prefix}_INSTALL_LIB_DIR "${CMAKE_INSTALL_LIBDIR_ARCHIND}")
			else()
				set(${prefix}_INSTALL_LIB_DIR "${CMAKE_INSTALL_LIBDIR}")
			endif()
		endif()
	endif()
	if("INSTALL_INCLUDE_DIR" IN_LIST single_values)
		if(${prefix}_INSTALL_INCLUDE_DIR)
		else()
			set(${prefix}_INSTALL_INCLUDE_DIR "${CMAKE_INSTALL_INCLUDEDIR}")
		endif()
	endif()
	if("CMAKE_EXPORT_NAME" IN_LIST single_values)
		if(${prefix}_CMAKE_EXPORT_NAME)
		else()
			if("NAME" IN_LIST single_values)
				set(${prefix}_CMAKE_EXPORT_NAME "${${prefix}_NAME}")
			else()
				message(FATAL_ERROR "${CMAKE_IS_PIECE_OF_SHIT} NAME")
			endif()
		endif()
	endif()
	if("CMAKE_EXPORT_NAMESPACE" IN_LIST single_values)
		if(${prefix}_CMAKE_EXPORT_NAMESPACE)
		else()
			if("CMAKE_EXPORT_NAME" IN_LIST single_values)
				set(${prefix}_CMAKE_EXPORT_NAMESPACE "${${prefix}_CMAKE_EXPORT_NAME}")
			else()
				message(FATAL_ERROR "${CMAKE_IS_PIECE_OF_SHIT} CMAKE_EXPORT_NAME")
			endif()
		endif()
	endif()
	if("PKG_CONFIG_NAME" IN_LIST single_values)
		if(${prefix}_PKG_CONFIG_NAME)
		else()
			set(_PKG_CONFIG_NAME "${${prefix}_NAME}")
		endif()
	endif()

	if("PKG_CONFIG_REQUIRES" IN_LIST lists)
	endif()
	if("PKG_CONFIG_CONFLICTS" IN_LIST lists)
	endif()

	if(_DEBUG_PARSE_PACKAGING_ARGUMENTS)
		foreach(varName ${options} ${single_values} ${lists})
			message(STATUS "modified parsed value ${prefix}_${varName} ${${prefix}_${varName}}")
		endforeach()
	endif()

	foreach(varName ${options} ${single_values} ${lists})
		set("${prefix}_${varName}" "${${prefix}_${varName}}" PARENT_SCOPE)
	endforeach()
endfunction()
