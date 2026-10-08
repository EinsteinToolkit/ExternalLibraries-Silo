#! /bin/bash

################################################################################
# Build
################################################################################

# Set up shell
if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
    set -x                      # Output commands
fi
set -e                          # Abort on errors


    
# Define some environment variables
export CC=${EXTERNAL_CC:-${CC}}
export CXX=${EXTERNAL_CXX:-${CXX}}
export F90=${EXTERNAL_F90:-${F90}}
export LD=${EXTERNAL_LD:-${LD}}
export CFLAGS=${EXTERNAL_CFLAGS:-${CFLAGS}}
export CXXFLAGS=${EXTERNAL_CXXFLAGS:-${CXXFLAGS}}
export F90FLAGS=${EXTERNAL_F90FLAGS:-${F90FLAGS}}
export LDFLAGS=${EXTERNAL_LDFLAGS:-${LDFLAGS}}



# Set locations
THORN=Silo
NAME=Silo-4.12.1
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

cd ${NAME}

echo "Silo: Applying patches..."
# Some (ancient but still used) versions of patch don't support the
# patch format used here but also don't report an error using the exit
# code. So we use this patch to test for this
${PATCH?} -p1 < ${SRCDIR}/../dist/patchtest.patch
if [ ! -e .patch_tmp ]; then
    echo 'BEGIN ERROR'
    echo 'The version of patch is too old to understand this patch format.'
    echo 'Please set the PATCH environment variable to a more recent '
    echo 'version of the patch command.'
    echo 'END ERROR'
    exit 1
fi
rm -f .patch_tmp

echo "Silo: Configuring..."

unset LIBS
unset LD

if [ "${CCTK_DEBUG_MODE}" = yes ]; then
    SILO_BUILD_TYPE=Debug
else
    SILO_BUILD_TYPE=RelWithDebInfo
fi

mkdir build
cd build

# ZFP compression leads to compile time failures in zfp due to only some code
# being awre of using a bns struct rather than globals
# force libdir so that it does not change from lib to lib64 and we can refer to
# it in detect.sh
# SILO_CONFIG_SITE prevents CMake from loading a file localhost.cmake messeing
# things up
${CMAKE_DIR:+${CMAKE_DIR}/bin/}cmake -DSILO_ENABLE_ZFP=OFF -DSILO_ENABLE_FPZIP=OFF -DSILO_ENABLE_FORTRAN=OFF -DCMAKE_BUILD_TYPE=${SILO_BUILD_TYPE} -DSILO_ENABLE_HDF5=ON -DHDF5_ROOT=${HDF5_DIR} -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR} -DSILO_CONFIG_SITE=/dev/null -DCMAKE_INSTALL_LIBDIR=${INSTALL_DIR}/lib ..

echo "Silo: Building..."
${MAKE}

echo "Silo: Installing..."
${MAKE} install
popd

echo "Silo: Cleaning up..."
rm -rf ${BUILD_DIR}

date > ${DONE_FILE}
echo "Silo: Done."
