cmake_minimum_required(VERSION 4.1)
project(imgui_library)

set(CMAKE_CXX_STANDARD 20)

add_library(imgui_library STATIC
        include/imconfig.h
        include/imgui.h
        include/imgui_internal.h
        include/imstb_rectpack.h
        include/imstb_textedit.h
        include/imstb_truetype.h
        include/backends/imgui_impl_dx12.h
        include/backends/imgui_impl_win32.h

        src/imgui.cpp
        src/imgui_demo.cpp
        src/imgui_draw.cpp
        src/imgui_tables.cpp
        src/imgui_widgets.cpp
        src/backends/imgui_impl_dx12.cpp
        src/backends/imgui_impl_win32.cpp
)

target_include_directories(imgui_library PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
target_include_directories(imgui_library PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include/backends)

if (MSVC)
    set_target_properties(imgui_library PROPERTIES
            WINDOWS_EXPORT_ALL_SYMBOLS ON
    )
endif ()
