set(CMAKE_CXX_COMPILER mpicxx)

set(CMAKE_CXX_FLAGS
	"-Wall -Wno-deprecated-writable-strings -Wno-deprecated-declarations -Wno-sign-compare -O3 $ENV{CFLAGS}"
)

set(SPARSE_GRID_DIR "${VENDOR_DIR}/SparseGrid/SparseGrid")

include_directories(
	"$ENV{CALPHA}/include"
	"$ENV{CALPHA}/vendor"
	"${SPARSE_GRID_DIR}/include"
)

add_executable(vary vary.cpp Problem.cpp)

target_link_libraries(vary
	Algebra
	Helpers
	HotSpot
	SparseGrid
	System
	Temperature
	mpich
)

add_library(HotSpot STATIC IMPORTED)
set_property(
	TARGET HotSpot PROPERTY
	IMPORTED_LOCATION $ENV{CALPHA}/vendor/hotspot/libhotspot.a
)

add_library(SparseGrid STATIC IMPORTED)
set_property(
	TARGET SparseGrid PROPERTY
	IMPORTED_LOCATION ${SPARSE_GRID_DIR}/lib/libsparsegrid.a
)

macro(import_library name)
	add_library(${name} STATIC IMPORTED)
	set_property(
		TARGET ${name} PROPERTY
		IMPORTED_LOCATION $ENV{CALPHA}/build/lib/${name}/lib${name}.a
	)
endmacro()

import_library(Algebra)
import_library(Helpers)
import_library(System)
import_library(Temperature)
