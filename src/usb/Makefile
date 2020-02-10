WASATCH_CPP = ../..

all: deps objs

include $(WASATCH_CPP)/common.mk

ifeq ($(UNAME), Linux)
    SUBDIRS = linux
else ifeq ($(findstring CYGWIN, $(UNAME)), CYGWIN)
    SUBDIRS = winusb
else ifeq ($(findstring MINGW, $(UNAME)), MINGW)
    SUBDIRS = linux
else
    SUBDIRS = osx
endif
