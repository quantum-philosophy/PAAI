cmake_minimum_required(VERSION 2.6)

project(ALUQ)

set(VENDOR_DIR ${PROJECT_SOURCE_DIR}/vendor)
add_subdirectory(csrc)

add_custom_target(tags
	COMMAND cd ${PROJECT_BINARY_DIR} && ctags -R ../*
)
