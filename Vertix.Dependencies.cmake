# Vertix.Dependencies — imported library targets
# Include this from your project CMakeLists.txt:
#   include(/path/to/Vertix.Dependencies/Vertix.Dependencies.cmake)
#
# All targets are GLOBAL so they're visible in subdirectories.

set(VX_INCLUDES  ${CMAKE_CURRENT_LIST_DIR}/includes)
set(VX_LIBRARIES ${CMAKE_CURRENT_LIST_DIR}/libraries)

# ---- d3d12 (headers only) ----
add_library(d3d12 INTERFACE IMPORTED GLOBAL)
set_target_properties(d3d12 PROPERTIES
    INTERFACE_INCLUDE_DIRECTORIES "${VX_INCLUDES}/d3d12"
)

# ---- simdjson ----
add_library(simdjson STATIC IMPORTED GLOBAL)
set_target_properties(simdjson PROPERTIES
    IMPORTED_LOCATION_DEBUG   "${VX_LIBRARIES}/Debug/simdjson.lib"
    IMPORTED_LOCATION_RELEASE "${VX_LIBRARIES}/Release/simdjson.lib"
    INTERFACE_INCLUDE_DIRECTORIES "${VX_INCLUDES}/simdjson"
)

# ---- fastgltf ----
add_library(fastgltf STATIC IMPORTED GLOBAL)
set_target_properties(fastgltf PROPERTIES
    IMPORTED_LOCATION_DEBUG   "${VX_LIBRARIES}/Debug/fastgltf.lib"
    IMPORTED_LOCATION_RELEASE "${VX_LIBRARIES}/Release/fastgltf.lib"
    INTERFACE_INCLUDE_DIRECTORIES "${VX_INCLUDES}/fastgltf"
)
target_link_libraries(fastgltf INTERFACE simdjson)

# ---- imgui ----
add_library(imgui STATIC IMPORTED GLOBAL)
set_target_properties(imgui PROPERTIES
    IMPORTED_LOCATION_DEBUG   "${VX_LIBRARIES}/Debug/imgui.lib"
    IMPORTED_LOCATION_RELEASE "${VX_LIBRARIES}/Release/imgui.lib"
    INTERFACE_INCLUDE_DIRECTORIES "${VX_INCLUDES}/imgui"
)

# ---- DirectXTK12 ----
add_library(DirectXTK12 STATIC IMPORTED GLOBAL)
set_target_properties(DirectXTK12 PROPERTIES
    IMPORTED_LOCATION_DEBUG   "${VX_LIBRARIES}/Debug/DirectXTK12.lib"
    IMPORTED_LOCATION_RELEASE "${VX_LIBRARIES}/Release/DirectXTK12.lib"
    INTERFACE_INCLUDE_DIRECTORIES "${VX_INCLUDES}/DirectXTK12"
)

# ---- GameInput (static lib, no Debug/Release distinction) ----
add_library(GameInput STATIC IMPORTED GLOBAL)
set_target_properties(GameInput PROPERTIES
    IMPORTED_LOCATION "${VX_LIBRARIES}/GameInput.lib"
    INTERFACE_INCLUDE_DIRECTORIES "${VX_INCLUDES}/GameInput"
)

# ---- dxcompiler + dxil (import libs; DLLs copied to libraries/ at build time) ----
add_library(dxcompiler STATIC IMPORTED GLOBAL)
set_target_properties(dxcompiler PROPERTIES
    IMPORTED_LOCATION "${VX_LIBRARIES}/dxcompiler.lib"
    INTERFACE_INCLUDE_DIRECTORIES "${VX_INCLUDES}/dxcompiler"
)

add_library(dxil STATIC IMPORTED GLOBAL)
set_target_properties(dxil PROPERTIES
    IMPORTED_LOCATION "${VX_LIBRARIES}/dxil.lib"
    INTERFACE_INCLUDE_DIRECTORIES "${VX_INCLUDES}/dxcompiler"
)
