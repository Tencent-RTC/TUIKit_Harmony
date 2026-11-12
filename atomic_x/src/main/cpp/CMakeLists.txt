cmake_minimum_required(VERSION 3.5.0)
project(aiaudiocodec)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

add_library(aiaudiocodec SHARED opus_codec.cpp)

target_link_libraries(aiaudiocodec PUBLIC
    libace_napi.z.so
    libnative_media_codecbase.so
    libnative_media_acodec.so
    libnative_media_core.so
)
