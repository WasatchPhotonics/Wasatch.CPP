CC  = gcc
CPP = g++

LFLAGS_LIB  =
LFLAGS_APP  = -L${WASATCH_CPP}/lib
CFLAGS_BASE = -I${WASATCH_CPP}/include \
              -c \
              -Wall \
              -Wunused \
              -Wmissing-include-dirs \
              -Werror \
              -g \
              -O0 \
              -fpic \
              -fno-stack-protector \
              -shared	

export UNAME = $(shell uname)

# MacOS X configuration
ifeq ($(UNAME), Darwin)
    LIBBASENAME = libwasatch
    SUFFIX      = dylib
    LFLAGS_APP += -L/usr/lib \
                  -lstdc++
    LFLAGS_LIB += -dynamic \
                  -dynamiclib \
                  -framework Carbon \
                  -framework CoreFoundation \
                  -framework IOKit 
                                    
    CFLAGS_BASE = -I${WASATCH_CPP}/include \
                  -c \
                  -Wall \
                  -Wunused \
                  -Wmissing-include-dirs \
                  -Werror \
                  -g \
                  -O0 \
                  -fpic \
                  -fno-stack-protector 

# Cygwin-32 configuration 
else ifeq ($(findstring CYGWIN, $(UNAME)), CYGWIN)
    # caller can override this, but this is the current Ocean Optics default
    VISUALSTUDIO_PROJ ?= VisualStudio2015bbbbbbb
    LIBBASENAME = wasatch
    SUFFIX      = dll
    CFLAGS_BASE = -I${WASATCH_CPP}/include \
                  -c \
                  -Wall \
                  -Wunused \
                  -Werror \
                  -ggdb3 \
                  -shared

# MinGW-32 configuration
else ifeq ($(findstring MINGW, $(UNAME)), MINGW)
    SUFFIX      = dll
    LIBBASENAME = libwasatch
    LFLAGS_APP += -L/local/lib \
                  -lusb0 \
                  -lstdc++ \
                  -lm
    LFLAGS_LIB += -L/local/lib \
                  -lusb0 \
                  -shared

# Linux configuration
else
    SUFFIX      = so
    LIBBASENAME = libwasatch
    LFLAGS_APP += -L/usr/lib \
                  -lstdc++ \
                  -lusb \
                  -lm
    LFLAGS_LIB += -L/usr/lib \
                  -shared \
                  -lusb
endif

# enable Logger
ifndef logger
    logger = 1
endif
ifeq ($(logger),1)
    CFLAGS_BASE += -DWP_DEBUG
endif

# osx install name
ifdef install_name
    LFLAGS_LIB += -install_name $(install_name)
endif

# these are for the .o files making up libwasatch
CPPFLAGS     = $(CFLAGS_BASE)
CFLAGS       = $(CFLAGS_BASE) -std=gnu99

# allow for a 32 bit build
ifdef wordwidth
ifeq ($(wordwidth),32)
	CPPFLAGS += -arch i386
	CFLAGS += -arch i386
	LFLAGS_APP += -arch i386
	LFLAGS_LIB += -arch i386
endif
ifeq ($(wordwidth),fat)
	CPPFLAGS += -arch i386 -arch x86_64
	CFLAGS += -arch i386 -arch x86_64
	LFLAGS_APP += -arch i386 -arch x86_64
	LFLAGS_LIB += -arch i386 -arch x86_64
endif
endif

export LIBNAME=$(LIBBASENAME).$(SUFFIX)

SUFFIXES = .c .cpp .o .d

SRCS_CPP := $(wildcard *.cpp)
DEPS_CPP := $(patsubst %.cpp,%.d,$(SRCS_CPP))
OBJS_CPP := $(patsubst %.cpp,%.o,$(SRCS_CPP))

SRCS_C   := $(wildcard *.c)
DEPS_C   := $(patsubst %.c,%.d,$(SRCS_C))
OBJS_C   := $(patsubst %.c,%.o,$(SRCS_C))

VISUALSTUDIO_PROJECTS = VisualStudio2019

ifneq ($(MAKECMDGOALS),clean)
    -include $(DEPFILES)
endif

deps: ${DEPS_CPP} ${DEPS_C}

%.d: %.cpp
	@echo caching $@
	${CPP} ${CFLAGS_BASE} -MM $< | sed "s/$*.o/& $@/g" > $@

%.d: %.c
	@echo caching $@
	${CC} ${CFLAGS_BASE} -MM $< | sed "s/$*.o/& $@/g" > $@

%.o: %.cpp
	@echo building $@
	${CPP} ${CPPFLAGS} $< -o $@

%.o: %.c
	@echo building $@
	${CC} ${CFLAGS} $< -o $@

objs: subdirs ${OBJS_CPP} ${OBJS_C}
	/bin/cp *.o ${WASATCH_CPP}/lib 1>/dev/null 2>&1 || true

subdirs:
	if [ "$(SUBDIRS)" ] ; then for d in $(SUBDIRS) ; do $(MAKE) -C $$d || exit ; done ; else true ; fi

clean:
	@echo cleaning $$PWD
	@for d in $(SUBDIRS); do $(MAKE) -C $$d $@ || exit; done
	@$(RM) -f *.d *.o *.obj *.exe *.stackdump lib/* $(APPS)
	@for VS in $(VISUALSTUDIO_PROJECTS) ; \
     do \
        if [ -d os-support/windows/$$VS ] ; \
        then \
            echo cleaning os-support/windows/$$VS ; \
            ( cd os-support/windows/$$VS && $(MAKE) clean ) || exit ; \
        fi ; \
     done
	@if [ -d doc ] ; then ( cd doc && $(RM) -rf man rtf html *.err ) ; fi

new: clean all
