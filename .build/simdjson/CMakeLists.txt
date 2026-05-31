cmake_minimum_required(VERSION 4.0)
project(simdjson)
set(CMAKE_CXX_STANDARD 20)
add_library(simdjson STATIC
        simdjson.h
        simdjson.cpp
)
set_target_properties(simdjson PROPERTIES LINKER_LANGUAGE CXX)
