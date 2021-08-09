#! /bin/bash

################################################################################
# Build
################################################################################

# Set up shell
if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
    set -x                      # Output commands
fi
set -e                          # Abort on errors



# Set locations
THORN=Silo
NAME=silo-4.10.2-bsd
SRCDIR="$(dirname $0)"
BUILD_DIR=${SCRATCH_BUILD}/build/${THORN}
if [ -z "${SILO_INSTALL_DIR}" ]; then
    INSTALL_DIR=${SCRATCH_BUILD}/external/${THORN}
else
    echo "BEGIN MESSAGE"
    echo "Installing Silo into ${SILO_INSTALL_DIR}"
    echo "END MESSAGE"
    INSTALL_DIR=${SILO_INSTALL_DIR}
fi
DONE_FILE=${SCRATCH_BUILD}/done/${THORN}
SILO_DIR=${INSTALL_DIR}

echo "Silo: Preparing directory structure..."
cd ${SCRATCH_BUILD}
mkdir build external done 2> /dev/null || true
rm -rf ${BUILD_DIR} ${INSTALL_DIR}
mkdir ${BUILD_DIR} ${INSTALL_DIR}

# Build core library
echo "Silo: Unpacking archive..."
pushd ${BUILD_DIR}
${TAR?} xf ${SRCDIR}/../dist/${NAME}.tar

echo "Silo: Configuring..."
cd ${NAME}

unset LIBS

if [ "${CCTK_DEBUG_MODE}" = yes ]; then
    SILO_OPTIMISE=
else
    SILO_OPTIMISE=--enable-optimization
fi

mkdir build
cd build
# need to extract the actual directory with HDF5 in it from the potentially
# longer list HDF5 supplied
HDF5_INC_DIR="`for DIR in $HDF5_INC_DIRS ; do
  ls 2>/dev/null $DIR/hdf5.h
done | head -n1 | sed 's!/hdf5\.h$!!'`"
HDF5_LIB_DIR="`for DIR in $HDF5_LIB_DIRS ; do
  ls 2>/dev/null $DIR/libhdf5.* $HDF5_LIB_DIRS/hdf5.lib $HDF5_LIB_DIRS/*hdf5.dylib
done | head -n1 | sed 's!/[^/]*$!!'`"

../configure --disable-fortran ${SILO_OPTIMISE} --with-hdf5=${HDF5_INC_DIR},${HDF5_LIB_DIR} --prefix=${INSTALL_DIR}

echo "Silo: Building..."
${MAKE}

echo "Silo: Installing..."
${MAKE} install
popd

echo "Silo: Cleaning up..."
rm -rf ${BUILD_DIR}

date > ${DONE_FILE}
echo "Silo: Done."
