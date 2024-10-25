#! /bin/bash

################################################################################
# Prepare
################################################################################

# Set up shell
if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
    set -x                      # Output commands
fi
set -e                          # Abort on errors

. $CCTK_HOME/lib/make/bash_utils.sh

# Take care of requests to build the library in any case
SILO_DIR_INPUT=$SILO_DIR
if [ "$(echo "${SILO_DIR}" | tr '[a-z]' '[A-Z]')" = 'BUILD' ]; then
    SILO_BUILD=1
    SILO_DIR=
else
    SILO_BUILD=
fi

# default value for FORTRAN support
if [ -z "$SILO_ENABLE_FORTRAN" ] ; then
    SILO_ENABLE_FORTRAN="OFF"
fi

################################################################################
# Decide which libraries to link with
################################################################################

# Set up names of the libraries based on configuration variables. Also
# assign default values to variables.
# Try to find the library if build isn't explicitly requested
if [ -z "${SILO_BUILD}" -a -z "${SILO_INC_DIRS}" -a -z "${SILO_LIB_DIRS}" -a -z "${SILO_LIBS}" ]; then
    find_lib SILO silo 1 1.0 "siloh5" "silo.h" "$SILO_DIR"
fi

THORN=Silo

# configure library if build was requested or is needed (no usable
# library found)
if [ -n "$SILO_BUILD" -o -z "${SILO_DIR}" ]; then
    echo "BEGIN MESSAGE"
    echo "Using bundled Silo..."
    echo "END MESSAGE"
    SILO_BUILD=1

    check_tools "tar patch"
    
    # Set locations
    BUILD_DIR=${SCRATCH_BUILD}/build/${THORN}
    if [ -z "${SILO_INSTALL_DIR}" ]; then
        INSTALL_DIR=${SCRATCH_BUILD}/external/${THORN}
    else
        echo "BEGIN MESSAGE"
        echo "Installing Silo into ${SILO_INSTALL_DIR}"
        echo "END MESSAGE"
        INSTALL_DIR=${SILO_INSTALL_DIR}
    fi
    SILO_DIR=${INSTALL_DIR}
    # Fortran modules may be located in the lib directory
    SILO_INC_DIRS="${SILO_DIR}/include ${SILO_DIR}/lib"
    SILO_LIB_DIRS="${SILO_DIR}/lib"
    SILO_LIBS="siloh5"
else
    DONE_FILE=${SCRATCH_BUILD}/done/${THORN}
    if [ ! -e ${DONE_FILE} ]; then
        mkdir ${SCRATCH_BUILD}/done 2> /dev/null || true
        date > ${DONE_FILE}
    fi
fi

if [ -n "$SILO_DIR" ]; then
    : ${SILO_RAW_LIB_DIRS:="$SILO_LIB_DIRS"}
    # Fortran modules may be located in the lib directory
    SILO_INC_DIRS="$SILO_RAW_LIB_DIRS $SILO_INC_DIRS"
    # We need the un-scrubbed inc dirs to look for a header file below.
    : ${SILO_RAW_INC_DIRS:="$SILO_INC_DIRS"}
else
    echo 'BEGIN ERROR'
    echo 'ERROR in Silo configuration: Could neither find nor build library.'
    echo 'END ERROR'
    exit 1
fi

################################################################################
# Check for additional libraries
################################################################################

# Silo's cmakr script wants to test-compile and needs the extra
# libraries specified by the user, howerver Cactus does not provide them during
# the build stage, since it extends them by teh ExternalLibraries generated
# ones
SILO_CCTK_LIBS="$LIBS"
SILO_CCTK_LIBDIRS="$LIBDIRS"

################################################################################
# Configure Cactus
################################################################################

# Pass configuration options to build script
echo "BEGIN MAKE_DEFINITION"
echo "SILO_BUILD          = ${SILO_BUILD}"
echo "SILO_ENABLE_FORTRAN = ${SILO_ENABLE_FORTRAN}"
echo "LIBSZ_DIR           = ${LIBSZ_DIR}"
echo "LIBZ_DIR            = ${LIBZ_DIR}"
echo "SILO_INSTALL_DIR    = ${SILO_INSTALL_DIR}"
echo "SILO_CCTK_LIBDIRS   = ${SILO_CCTK_LIBDIRS}"
echo "SILO_CCTK_LIBS      = ${SILO_CCTK_LIBS}"
echo "END MAKE_DEFINITION"

# Pass options to Cactus
echo "BEGIN MAKE_DEFINITION"
echo "SILO_DIR            = ${SILO_DIR}"
echo "SILO_ENABLE_FORTRAN = ${SILO_ENABLE_FORTRAN}"
echo "SILO_INC_DIRS       = ${SILO_INC_DIRS} ${ZLIB_INC_DIRS}"
echo "SILO_LIB_DIRS       = ${SILO_LIB_DIRS} ${ZLIB_LIB_DIRS}"
echo "SILO_LIBS           = ${SILO_LIBS}"
echo "END MAKE_DEFINITION"

echo 'INCLUDE_DIRECTORY $(SILO_INC_DIRS)'
echo 'LIBRARY_DIRECTORY $(SILO_LIB_DIRS)'
echo 'LIBRARY           $(SILO_LIBS)'
