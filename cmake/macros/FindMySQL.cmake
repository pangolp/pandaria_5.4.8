#
# Find the MySQL client includes and library
#

# This module defines
# MYSQL_INCLUDE_DIR, where to find mysql.h
# MYSQL_LIBRARIES, the libraries to link against to connect to MySQL
# MYSQL_FOUND, if false, you cannot build anything that requires MySQL.

# also defined, but not for general use are
# MYSQL_LIBRARY, where to find the MySQL library.

set(MYSQL_FOUND 0)

if(WIN32)
  # read environment variables and change \ to /
  SET(PROGRAM_FILES_32 $ENV{ProgramFiles})
  if(${PROGRAM_FILES_32})
    STRING(REPLACE "\\\\" "/" PROGRAM_FILES_32 ${PROGRAM_FILES_32})
  endif(${PROGRAM_FILES_32})

  SET(PROGRAM_FILES_64 $ENV{ProgramW6432})
  if(${PROGRAM_FILES_64})
     STRING(REPLACE "\\\\" "/" PROGRAM_FILES_64 ${PROGRAM_FILES_64})
  endif(${PROGRAM_FILES_64})
endif(WIN32)

# Find MariaDB for Windows
if(WIN32)
  # Set know versions MariaDB
  set(_MARIADB_KNOWN_VERSIONS "MariaDB 10.5" "MariaDB 10.4" "MariaDB 10.3" "MariaDB 10.2")

  # Set default options
  set(MARIADB_FOUND_LIB 0)
  set(MARIADB_FOUND_INCLUDE 0)
  set(MARIADB_FOUND_EXECUTABLE 0)
  set(MARIADB_FOUND 0)

  macro(FindLibMariaDB MariaDBVersion)
  # Find include
  find_path(MYSQL_INCLUDE_DIR
    NAMES
      mysql.h
    PATHS
      ${MYSQL_ADD_INCLUDE_PATH}
      "${PROGRAM_FILES_64}/${MariaDBVersion}/include/mysql"
      "${PROGRAM_FILES_32}/${MariaDBVersion}/include/mysql"
      "${_VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/include/mysql"
    DOC
      "Specify the directory containing mysql.h."
  )

  if(MYSQL_INCLUDE_DIR)
    set(MARIADB_FOUND_INCLUDE 1)
  endif()

  find_library(MYSQL_LIBRARY
    NAMES
      libmariadb
    PATHS
      ${MYSQL_ADD_LIBRARIES_PATH}
      "${PROGRAM_FILES_64}/${MariaDBVersion}/lib"
      "${PROGRAM_FILES_64}/${MariaDBVersion}/lib/opt"
      "${PROGRAM_FILES_32}/${MariaDBVersion}/lib"
      "${PROGRAM_FILES_32}/${MariaDBVersion}/lib/opt"
      "$ENV{ProgramFiles}/${MariaDBVersion}/lib/opt"
      "$ENV{SystemDrive}/${MariaDBVersion}/lib/opt"
      "${_VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/lib"
    DOC
      "Specify the location of the mysql library here."
  )

  if(MYSQL_LIBRARY)
    set(MARIADB_FOUND_LIB 1)
  endif()

  find_program(MYSQL_EXECUTABLE mysql
    PATHS
      "${PROGRAM_FILES_64}/${MariaDBVersion}/bin"
      "${PROGRAM_FILES_64}/${MariaDBVersion}/bin/opt"
      "${PROGRAM_FILES_32}/${MariaDBVersion}/bin"
      "${PROGRAM_FILES_32}/${MariaDBVersion}/bin/opt"
      "$ENV{ProgramFiles}/${MariaDBVersion}/bin/opt"
      "$ENV{SystemDrive}/${MariaDBVersion}/bin/opt"
    DOC
        "path to your mysql binary.")

  if(MYSQL_LIBRARY AND MYSQL_INCLUDE_DIR AND MYSQL_EXECUTABLE)
    set(MARIADB_FOUND 1)
  endif()

  endmacro(FindLibMariaDB)

  foreach(version ${_MARIADB_KNOWN_VERSIONS})
    if(NOT MARIADB_FOUND)
      FindLibMariaDB(${version})
    endif()
  endforeach()
endif()

if(UNIX)
  set(MYSQL_CONFIG_PREFER_PATH "$ENV{MYSQL_HOME}/bin" CACHE FILEPATH
    "preferred path to MySQL (mysql_config)"
  )

  find_program(MYSQL_CONFIG mysql_config
    ${MYSQL_CONFIG_PREFER_PATH}
    /usr/local/mysql/bin/
    /usr/local/bin/
    /usr/bin/
  )

  if(MYSQL_CONFIG)
    message(STATUS "Using mysql-config: ${MYSQL_CONFIG}")
    # set INCLUDE_DIR
    exec_program(${MYSQL_CONFIG}
      ARGS --include
      OUTPUT_VARIABLE MY_TMP
    )

    string(REGEX REPLACE "-I([^ ]*)( .*)?" "\\1" MY_TMP "${MY_TMP}")
    set(MYSQL_ADD_INCLUDE_PATH ${MY_TMP} CACHE FILEPATH INTERNAL)
    #message("[DEBUG] MYSQL ADD_INCLUDE_PATH : ${MYSQL_ADD_INCLUDE_PATH}")
    # set LIBRARY_DIR
    exec_program(${MYSQL_CONFIG}
      ARGS --libs_r
      OUTPUT_VARIABLE MY_TMP
    )
    set(MYSQL_ADD_LIBRARIES "")
    string(REGEX MATCHALL "-l[^ ]*" MYSQL_LIB_LIST "${MY_TMP}")
    foreach(LIB ${MYSQL_LIB_LIST})
      string(REGEX REPLACE "[ ]*-l([^ ]*)" "\\1" LIB "${LIB}")
      list(APPEND MYSQL_ADD_LIBRARIES "${LIB}")
      #message("[DEBUG] MYSQL ADD_LIBRARIES : ${MYSQL_ADD_LIBRARIES}")
    endforeach(LIB ${MYSQL_LIB_LIST})

    set(MYSQL_ADD_LIBRARIES_PATH "")
    string(REGEX MATCHALL "-L[^ ]*" MYSQL_LIBDIR_LIST "${MY_TMP}")
    foreach(LIB ${MYSQL_LIBDIR_LIST})
      string(REGEX REPLACE "[ ]*-L([^ ]*)" "\\1" LIB "${LIB}")
      list(APPEND MYSQL_ADD_LIBRARIES_PATH "${LIB}")
      #message("[DEBUG] MYSQL ADD_LIBRARIES_PATH : ${MYSQL_ADD_LIBRARIES_PATH}")
    endforeach(LIB ${MYSQL_LIBS})

  else(MYSQL_CONFIG)
    set(MYSQL_ADD_LIBRARIES "")
    list(APPEND MYSQL_ADD_LIBRARIES "mysqlclient_r")
  endif(MYSQL_CONFIG)
endif(UNIX)

find_path(MYSQL_INCLUDE_DIR
  NAMES
    mysql.h
  PATHS
    ${MYSQL_ADD_INCLUDE_PATH}
    /usr/include
    /usr/include/mysql
    /usr/local/include
    /usr/local/include/mysql
    /usr/local/mysql/include
    "C:/Program Files/MySQL/MySQL Server 8.0/include"
    "C:/Program Files/MySQL/include"
    "C:/MySQL/include"
    "[HKEY_LOCAL_MACHINE\\SOFTWARE\\MySQL AB\\MySQL Server 8.0;Location]/include"
    "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\MySQL AB\\MySQL Server 8.0;Location]/include"
    "$ENV{ProgramFiles}/MySQL/*/include"
    "$ENV{SystemDrive}/MySQL/*/include"
    "c:/msys/local/include"
    "$ENV{MYSQL_INCLUDE_DIR}"
  DOC
    "Specify the directory containing mysql.h."
)

if(UNIX)
  foreach(LIB ${MYSQL_ADD_LIBRARIES})
    find_library(MYSQL_LIBRARY
      NAMES
        mysql libmysql ${LIB}
      PATHS
        ${MYSQL_ADD_LIBRARIES_PATH}
        /usr/lib
        /usr/lib/mysql
        /usr/local/lib
        /usr/local/lib/mysql
        /usr/local/mysql/lib
      DOC "Specify the location of the mysql library here.")
  endforeach(LIB ${MYSQL_ADD_LIBRARY})
endif(UNIX)

if(WIN32)
  find_library(MYSQL_LIBRARY
    NAMES
      libmysql
    PATHS
      ${MYSQL_ADD_LIBRARIES_PATH}
      "C:/Program Files/MySQL/MySQL Server 8.0/lib"
      "C:/Program Files/MySQL/MySQL Server 8.0/lib/opt"
      "C:/Program Files/MySQL/lib"
      "C:/MySQL/lib/debug"
      "[HKEY_LOCAL_MACHINE\\SOFTWARE\\MySQL AB\\MySQL Server 8.0;Location]/lib"
      "[HKEY_LOCAL_MACHINE\\SOFTWARE\\MySQL AB\\MySQL Server 8.0;Location]/lib/opt"
      "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\MySQL AB\\MySQL Server 8.0;Location]/lib"
      "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\MySQL AB\\MySQL Server 8.0;Location]/lib/opt"
      "$ENV{ProgramFiles}/MySQL/*/lib/opt"
      "$ENV{SystemDrive}/MySQL/*/lib/opt"
      "c:/msys/local/include"
      "$ENV{MYSQL_LIBRARY}"
    DOC "Specify the location of the mysql library here.")
endif(WIN32)

# On Windows you typically don't need to include any extra libraries
# to build MYSQL stuff.
if(NOT WIN32)
  find_library(MYSQL_EXTRA_LIBRARIES
    NAMES
      z zlib
    PATHS
      /usr/lib
      /usr/local/lib
    DOC
      "if more libraries are necessary to link in a MySQL client (typically zlib), specify them here.")
else(NOT WIN32)
  set(MYSQL_EXTRA_LIBRARIES "")
endif(NOT WIN32)

if(UNIX)
  find_program(MYSQL_EXECUTABLE mysql
    PATHS
      ${MYSQL_CONFIG_PREFER_PATH}
      /usr/local/mysql/bin/
      /usr/local/bin/
      /usr/bin/
    DOC
      "path to your mysql binary.")
endif(UNIX)

if(WIN32)
  find_program(MYSQL_EXECUTABLE mysql
    PATHS
      "${PROGRAM_FILES_64}/MySQL/MySQL Server 8.0/bin"
      "${PROGRAM_FILES_64}/MySQL/MySQL Server 8.0/bin/opt"
      "${PROGRAM_FILES_64}/MySQL/bin"
      "${PROGRAM_FILES_32}/MySQL/MySQL Server 8.0/bin"
      "${PROGRAM_FILES_32}/MySQL/MySQL Server 8.0/bin/opt"
      "${PROGRAM_FILES_32}/MySQL/bin"
      "C:/MySQL/bin/debug"
      "[HKEY_LOCAL_MACHINE\\SOFTWARE\\MySQL AB\\MySQL Server 8.0;Location]/bin"
      "[HKEY_LOCAL_MACHINE\\SOFTWARE\\MySQL AB\\MySQL Server 8.0;Location]/bin/opt"
      "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\MySQL AB\\MySQL Server 8.0;Location]/bin"
      "[HKEY_LOCAL_MACHINE\\SOFTWARE\\Wow6432Node\\MySQL AB\\MySQL Server 8.0;Location]/bin/opt"
      "$ENV{ProgramFiles}/MySQL/MySQL Server 8.0/bin/opt"
      "$ENV{SystemDrive}/MySQL/MySQL Server 8.0/bin/opt"
      "c:/msys/local/include"
      "$ENV{MYSQL_ROOT}/bin"
    DOC
      "path to your mysql binary.")
endif(WIN32)

if(MYSQL_LIBRARY)
  if(MYSQL_INCLUDE_DIR)
    set(MYSQL_FOUND 1)
    message(STATUS "Found MySQL library: ${MYSQL_LIBRARY}")
    message(STATUS "Found MySQL headers: ${MYSQL_INCLUDE_DIR}")
  else(MYSQL_INCLUDE_DIR)
    message(FATAL_ERROR "Could not find MySQL headers! Please install the development libraries and headers")
  endif(MYSQL_INCLUDE_DIR)
  if(MYSQL_EXECUTABLE)
    message(STATUS "Found MySQL executable: ${MYSQL_EXECUTABLE}")
  endif(MYSQL_EXECUTABLE)
  mark_as_advanced(MYSQL_FOUND MYSQL_LIBRARY MYSQL_EXTRA_LIBRARIES MYSQL_INCLUDE_DIR MYSQL_EXECUTABLE)
else(MYSQL_LIBRARY)
  message(FATAL_ERROR "Could not find the MySQL libraries! Please install the development libraries and headers")
endif(MYSQL_LIBRARY)
