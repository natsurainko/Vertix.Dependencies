# Vertix.Dependencies

This repository provides header files and precompiled libraries required for the [Vertix](https://github.com/natsurainko/Vertix) 3D game development framework.  
**Target platform: Windows x64 (MSVC toolchain).**

All libraries and files in this repository are configured and compiled to be easily integrated into `Vertix` projects. See details for each included library and dependency below.

## Provided Libraries and Dependencies

### 1. [assimp/assimp](https://github.com/assimp/assimp)
- **Type:** Header files, Dynamic-Link Library (DLL), Static-Link Library (LIB)
- **Build:** Compiled from source using the Visual Studio toolchain with default configuration.
- **Details:** Provides model import/export functionality.
- **Binary and headers are included.**

### 2. [microsoft/DirectX-Headers](https://github.com/microsoft/DirectX-Headers)
- **Type:** Header files only.
- **Details:** Provides Direct3D12 API definitions.
- **NOTE:** Precompiled libraries (lib files) are **not** provided in this repository.  
  Please use the `Windows SDK` for the required libraries at link time.

### 3. [microsoft/DirectXTK12](https://github.com/microsoft/DirectXTK12)
- **Type:** Header files, Static-Link Library (LIB)
- **Build:** Compiled from source using Visual Studio with the `DirectXTK_Desktop_2026.slnx` solution provided in the official repository.
- **Details:** Provides utility classes and helpers for Direct3D 12.
- **Binary and headers are included.**

### 4. [microsoftconnect/GameInput](https://github.com/microsoftconnect/GameInput)
- **Type:** Header files, Static-Link Library (LIB)
- **Source:** Both headers and libraries are taken from the official `Releases` of the GameInput repository.
- **Details:** Provides modern game input API support.

### 5. [ocornut/imgui](https://github.com/ocornut/imgui)
- **Type:** Header files, Static-Link Library (LIB)
- **Build:** Compiled from source using the Visual Studio toolchain.
- **Details:** Only the Win32/DX12 backend is included. All files are copied from the original repository and **unmodified** except for header include path fixes.  
  The folder/file structure is as follows:

    ```
    ├─include
    │  ├─imconfig.h
    │  ├─imgui.h
    │  ├─imgui_internal.h
    │  ├─imstb_rectpack.h
    │  ├─imstb_textedit.h
    │  ├─imstb_truetype.h
    │  └─backends
    │      ├─imgui_impl_dx12.h
    │      └─imgui_impl_win32.h
    └─src
        ├─imgui.cpp
        ├─imgui_demo.cpp
        ├─imgui_draw.cpp
        ├─imgui_tables.cpp
        ├─imgui_widgets.cpp
        └─backends
            ├─imgui_impl_dx12.cpp
            └─imgui_impl_win32.cpp
    ```
- **Headers and static library are included.**

### 6. [microsoft/DirectXShaderCompiler](https://github.com/microsoft/DirectXShaderCompiler) (`dxcompiler`)
- **Type:** DLL (optional runtime dependency)
- **Details:** `dxcompiler` headers and static libraries are **not** provided or needed as part of this repository.
- **Usage:** Please use the headers and static library from the `Windows SDK`.  
  **The DLL file is included here (copied from official Releases) in case a runtime dependency on DXC is required.**

## License

Each library and file included in this repository retains its original license. Refer to the respective projects for detailed licensing terms.

## Notes

- All binaries are compiled or included for **Windows x64 (MSVC)**.
- This repository is not intended as a comprehensive package manager, but as a dependency distribution for [Vertix](https://github.com/natsurainko/Vertix).
- For issues or feature requests, please use the [Vertix](https://github.com/natsurainko/Vertix) main repository.
