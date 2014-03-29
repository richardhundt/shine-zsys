
CURDIR = $(shell pwd)
DEPDIR = ${CURDIR}/deps

export DEBUG=
export DEBUG=-g

SHC = shinec ${DEBUG}

export PREFIX = /usr/local
export BUILD= ${CURDIR}/build

CFLAGS=-O2 -Wall
LDFLAGS=-lm -ldl -lstdc++
SOFLAGS=-O2 -Wall

LDPRE=
LDPOST=

OS_NAME=$(shell uname -s)

ifeq (${OS_NAME}, Darwin)
LIBEXT=dylib
LDPRE+=-Wl,-all_load
SOFLAGS+=-dynamic -bundle -undefined dynamic_lookup
else
LIBEXT=so
LDPRE+=-Wl,--whole-archive
LDPOST+=-Wl,--no-whole-archive -Wl,-E
SOFLAGS+=-shared -fPIC
endif

all: dirs deps ${BUILD}/zsys.so

${BUILD}/zsys.so: deps
	${SHC} -n "zsys" zsys.shn ${BUILD}/zsys.o
	${SHC} -n "zsys.ffi" zsys/ffi.shn ${BUILD}/zsys_ffi.o
	${CC} ${SOFLAGS} -o ${BUILD}/zsys.so \
	${BUILD}/zsys.o ${BUILD}/zsys_ffi.o ${LDPRE} \
	${BUILD}/libsodium.a ${BUILD}/libzmq.a ${BUILD}/libczmq.a \
	${LDPOST} ${LDFLAGS}

dirs:
	mkdir -p ${BUILD}

deps: ${BUILD}/libzmq.a ${BUILD}/libczmq.a ${BUILD}/libsodium.a

${BUILD}/libsodium.a: ${DEPDIR}/libsodium/Makefile
	cd ${DEPDIR}/libsodium && make && make install
	cp ${BUILD}/lib/libsodium.a ${BUILD}/

${DEPDIR}/libsodium/Makefile:
	git submodule update --init ${DEPDIR}/libsodium
	cd ${DEPDIR}/libsodium && ./autogen.sh && ./configure --prefix=${BUILD}

${BUILD}/libczmq.a: ${BUILD}/libzmq.a ${DEPDIR}/czmq/Makefile
	cd ${DEPDIR}/czmq && make && make install
	cp ${BUILD}/lib/libczmq.a ${BUILD}/

${DEPDIR}/czmq/Makefile:
	git submodule update --init ${DEPDIR}/czmq
	cd ${DEPDIR}/czmq && ./autogen.sh && ./configure \
	--with-libzmq=${BUILD}/ --prefix=${BUILD} 

${BUILD}/libzmq.a: ${DEPDIR}/libzmq/Makefile
	cd ${DEPDIR}/libzmq && make && make install
	cp ${BUILD}/lib/libzmq.a ${BUILD}/

${DEPDIR}/libzmq/Makefile:
	git submodule update --init ${DEPDIR}/libzmq
	cd ${DEPDIR}/libzmq && ./autogen.sh && ./configure \
	--prefix=${BUILD} --with-libsodium=${BUILD} 

clean:
	rm -rf ${BUILD}/*

realclean: clean
	make -C ${DEPDIR}/libzmq clean
	make -C ${DEPDIR}/czmq clean

install: all
	mkdir -p ${PREFIX}/lib/shine
	install -m 0644 ${BUILD}/zsys.so ${PREFIX}/lib/shine/zsys.so

uninstall:
	rm -f ${PREFIX}/lib/shine/zsys.so

.PHONY: all dirs deps clean realclean install uninstall
