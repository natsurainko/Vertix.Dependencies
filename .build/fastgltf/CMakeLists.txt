cmake_minimum_required(VERSION 3.21)
project(fastgltf LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)

# Paths to externally-built simdjson
set(REPO_INCLUDES ${CMAKE_CURRENT_SOURCE_DIR}/../../includes)
set(REPO_LIBS ${CMAKE_CURRENT_SOURCE_DIR}/../../libraries)

add_library(fastgltf STATIC
    include/fastgltf/base64.hpp
    include/fastgltf/core.hpp
    include/fastgltf/dxmath_element_traits.hpp
    include/fastgltf/glm_element_traits.hpp
    include/fastgltf/tools.hpp
    include/fastgltf/types.hpp
    include/fastgltf/util.hpp
    include/fastgltf/math.hpp

    src/fastgltf.cpp
    src/base64.cpp
    src/io.cpp
)

target_include_directories(fastgltf PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${REPO_INCLUDES}/simdjson
)

target_link_libraries(fastgltf PRIVATE
    optimized ${REPO_LIBS}/Release/simdjson.lib
    debug ${REPO_LIBS}/Debug/simdjson.lib
)

target_compile_definitions(fastgltf PUBLIC
    FASTGLTF_USE_CUSTOM_SMALLVECTOR=0
    FASTGLTF_ENABLE_DEPRECATED_EXT=0
    FASTGLTF_DISABLE_CUSTOM_MEMORY_POOL=0
    FASTGLTF_USE_64BIT_FLOAT=0
)

if(MSVC)
    target_compile_options(fastgltf PRIVATE /EHsc /utf-8)
    target_compile_options(fastgltf PRIVATE $<$<CONFIG:RELEASE>:/O2 /Ob3 /Ot>)
    set_target_properties(fastgltf PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS ON)
endif()
