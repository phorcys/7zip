# -*- mode: makefile-gmake -*-

c_flags =
cxx_flags =

# Add special options for GCC 16 and later
cxx_flags += -Wno-error=array-bounds

ifeq (hurd-i386, $(DEB_HOST_ARCH))
  cxx_flags += -Wno-error=conversion
endif

ifneq ($(c_flags),)
  export DEB_CFLAGS_MAINT_APPEND = $(c_flags)
endif
ifneq ($(cxx_flags),)
  export DEB_CXXFLAGS_MAINT_APPEND = $(cxx_flags)
endif
