# bgfx.cmake - bgfx building in cmake
# Written in 2017 by Joshua Brookover <joshua.al.brookover@gmail.com>

include( CMakeParseArguments )

include( ${SE_THIRD_PARTY}/bgfx.cmake/cmake/bgfxToolUtils.cmake )

function(add_se_shader FILE)
	get_filename_component(FILE_NAME "${FILE}" NAME_WLE)
	get_filename_component(FILE_EXTENSION "${FILE}" LAST_EXT)
	string(LENGTH "${FILE_EXTENSION}" FILE_EXTENSION_LENGTH)
	file(RELATIVE_PATH FILE_RELATIVE_PATH ${SE_SOURCE}/Core/Shaders ${FILE})
	string(LENGTH "${FILE_RELATIVE_PATH}" FILE_RELATIVE_PATH_LENGTH)
	math(EXPR FILE_RELATIVE_PATH_WLE_LENGTH "${FILE_RELATIVE_PATH_LENGTH} - ${FILE_EXTENSION_LENGTH}")
	string(SUBSTRING "${FILE_RELATIVE_PATH}" 0 ${FILE_RELATIVE_PATH_WLE_LENGTH} FILE_RELATIVE_PATH_WLE)
	string(SUBSTRING "${FILE_NAME}" 0 2 TYPE)
	if("${TYPE}" STREQUAL "fs")
		set(TYPE "FRAGMENT")
	elseif("${TYPE}" STREQUAL "vs")
		set(TYPE "VERTEX")
	elseif("${TYPE}" STREQUAL "cs")
		set(TYPE "COMPUTE")
	else()
		set(TYPE "")
	endif()

	if(NOT "${TYPE}" STREQUAL "")
		set(COMMON FILE ${FILE} ${TYPE} INCLUDES ${SE_SOURCE}/Core/Shaders)
		set(RESULT_DIR "${SE_CONTENT}/Shader")
		set(OUTPUTS "")
		set(OUTPUTS_PRETTY "")

		if(WIN32)
			# dx9
			# if(NOT "${TYPE}" STREQUAL "COMPUTE")
			# 	set(DX9_OUTPUT ${RESULT_DIR}/dx9/${FILE_RELATIVE_PATH_WLE}.bin)
			# 	_bgfx_shaderc_parse(
			# 		DX9 ${COMMON} WINDOWS
			# 		PROFILE s_3_0
			# 		O 3
			# 		OUTPUT ${DX9_OUTPUT}
			# 	)
			# 	list(APPEND OUTPUTS "DX9")
			# 	set(OUTPUTS_PRETTY "${OUTPUTS_PRETTY}DX9, ")
			# endif()

			# dx11
			set(DX11_OUTPUT ${RESULT_DIR}/dx11/${FILE_RELATIVE_PATH_WLE}.bin)
			if(NOT "${TYPE}" STREQUAL "COMPUTE")
				_bgfx_shaderc_parse(
					DX11 ${COMMON} WINDOWS
					PROFILE s_5_0
					O 3
					OUTPUT ${DX11_OUTPUT}
				)
			else()
				_bgfx_shaderc_parse(
					DX11 ${COMMON} WINDOWS
					PROFILE s_5_0
					O 1
					OUTPUT ${DX11_OUTPUT}
				)
			endif()
			list(APPEND OUTPUTS "DX11")
			set(OUTPUTS_PRETTY "${OUTPUTS_PRETTY}DX11, ")
		endif()

		if(APPLE)
			# metal
			set(METAL_OUTPUT ${RESULT_DIR}/metal/${FILE_RELATIVE_PATH_WLE}.bin)
			_bgfx_shaderc_parse(METAL ${COMMON} OSX PROFILE metal OUTPUT ${METAL_OUTPUT})
			list(APPEND OUTPUTS "METAL")
			set(OUTPUTS_PRETTY "${OUTPUTS_PRETTY}Metal, ")
		endif()

		# essl
		# if(NOT "${TYPE}" STREQUAL "COMPUTE")
		# 	set(ESSL_OUTPUT ${RESULT_DIR}/essl/${FILE_RELATIVE_PATH_WLE}.bin)
		# 	_bgfx_shaderc_parse(ESSL ${COMMON} ANDROID OUTPUT ${ESSL_OUTPUT})
		# 	list(APPEND OUTPUTS "ESSL")
		# 	set(OUTPUTS_PRETTY "${OUTPUTS_PRETTY}ESSL, ")
		# endif()

		# glsl
		set(GLSL_OUTPUT ${RESULT_DIR}/glsl/${FILE_RELATIVE_PATH_WLE}.bin)
		if(NOT "${TYPE}" STREQUAL "COMPUTE")
			_bgfx_shaderc_parse(GLSL ${COMMON} LINUX PROFILE 140 OUTPUT ${GLSL_OUTPUT})
		else()
			_bgfx_shaderc_parse(GLSL ${COMMON} LINUX PROFILE 430 OUTPUT ${GLSL_OUTPUT})
		endif()
		list(APPEND OUTPUTS "GLSL")
		set(OUTPUTS_PRETTY "${OUTPUTS_PRETTY}GLSL, ")

		# spirv
		if(NOT "${TYPE}" STREQUAL "COMPUTE")
			set(SPIRV_OUTPUT ${RESULT_DIR}/spirv/${FILE_RELATIVE_PATH_WLE}.bin)
			_bgfx_shaderc_parse(SPIRV ${COMMON} LINUX PROFILE spirv OUTPUT ${SPIRV_OUTPUT})
			list(APPEND OUTPUTS "SPIRV")
			set(OUTPUTS_PRETTY "${OUTPUTS_PRETTY}SPIRV")
			set(OUTPUT_FILES "")
			set(COMMANDS "")
		endif()

		foreach(OUT ${OUTPUTS})
			list(APPEND OUTPUT_FILES ${${OUT}_OUTPUT})
			list(APPEND COMMANDS COMMAND "bgfx::shaderc" ${${OUT}})
			get_filename_component(OUT_DIR ${${OUT}_OUTPUT} DIRECTORY)
			file(MAKE_DIRECTORY ${OUT_DIR})
		endforeach()

		add_custom_command(
			MAIN_DEPENDENCY ${FILE} OUTPUT ${OUTPUT_FILES} ${COMMANDS}
			COMMENT "Compiling shader ${FILE} for ${OUTPUTS_PRETTY}"
		)
		add_custom_command(
			MAIN_DEPENDENCY ${FILE}
			OUTPUT ${OUTPUT_FILES} ${COMMANDS}
			COMMENT "Compiling shader ${FILE_RELATIVE_PATH} for ${OUTPUTS_PRETTY}"
		)
		set_property(GLOBAL APPEND PROPERTY SE_SHADER_LIST "${OUTPUT_FILES}")
	endif()
endfunction()

set(SE_SHADERS "")
file(GLOB_RECURSE SE_SHADER_FILES ${SE_SOURCE}/Core/Shaders/*.sc)
list(APPEND SE_SHADERS ${SE_SHADER_FILES})
foreach(SHADER ${SE_SHADERS})
	add_se_shader(${SHADER})
endforeach()
source_group("Shaders" FILES ${SE_SHADERS})
