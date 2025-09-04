cmake_minimum_required(VERSION 3.20)
project(ffiasm_tests LANGUAGES C CXX ASM_NASM)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# GMP
find_package(PkgConfig REQUIRED)
pkg_check_modules(GMP REQUIRED IMPORTED_TARGET gmp)

# Пути
set(FFIASM_GEN_DIR ${CMAKE_SOURCE_DIR})  # fr.* и fq.* лежат в корне
set(FFIASM_VENDOR ${CMAKE_SOURCE_DIR}/third_party/ffiasm_upstream)

include_directories(${FFIASM_GEN_DIR})
include_directories(${FFIASM_VENDOR}/c)
include_directories(${FFIASM_VENDOR}/test)

# Собираем сгенерённые поля (ASM + C++)
# Linux: nasm -> ELF64; если macOS — нужно -fmacho64 и префикс, это можно донастроить при необходимости.
enable_language(ASM_NASM)
if(APPLE)
  set(CMAKE_ASM_NASM_OBJECT_FORMAT macho64)
  add_compile_options($<$<COMPILE_LANGUAGE:ASM_NASM>:--prefix _>)
else()
  set(CMAKE_ASM_NASM_OBJECT_FORMAT elf64)
endif()

add_library(ffiasm_fields STATIC
  ${FFIASM_GEN_DIR}/fr.cpp
  ${FFIASM_GEN_DIR}/fr.asm
  ${FFIASM_GEN_DIR}/fq.cpp
  ${FFIASM_GEN_DIR}/fq.asm
)

target_link_libraries(ffiasm_fields PRIVATE PkgConfig::GMP)

# Подтягиваем GoogleTest через FetchContent (без плясок с системной libgtest-dev)
include(FetchContent)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/refs/tags/v1.14.0.zip
)
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

# Собираем тесты из upstream/test + конкретный alt_bn128_test.cpp из upstream/c
file(GLOB_RECURSE FFIASM_UPSTREAM_TEST_SOURCES
  ${FFIASM_VENDOR}/test/*.cpp
)

add_executable(alt_bn128_tests
  ${FFIASM_VENDOR}/c/alt_bn128_test.cpp
  ${FFIASM_UPSTREAM_TEST_SOURCES}
)

target_link_libraries(alt_bn128_tests
  PRIVATE
    ffiasm_fields
    gtest_main
    PkgConfig::GMP
)

# Быстрые флаги
if (MSVC)
  target_compile_options(alt_bn128_tests PRIVATE /O2)
else()
  target_compile_options(alt_bn128_tests PRIVATE -O2 -march=native)
endif()

include(GoogleTest)
gtest_discover_tests(alt_bn128_tests)
