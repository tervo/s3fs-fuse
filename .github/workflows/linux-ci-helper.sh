#!/bin/sh
#
# s3fs - FUSE-based file system backed by Amazon S3
#
# Copyright(C) 2007 Takeshi Nakatani <ggtakec.com>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#

echo "${PRGNAME} [INFO] Start Linux helper for installing packages."

#-----------------------------------------------------------
# Common variables
#-----------------------------------------------------------
PRGNAME=`basename $0`

#-----------------------------------------------------------
# Parameter check
#-----------------------------------------------------------
#
# Usage: ${PRGNAME} "OS:VERSION"
#
if [ $# -ne 1 ]; then
    echo "${PRGNAME} [ERROR] No container name options specified."
fi

#-----------------------------------------------------------
# Container OS variables
#-----------------------------------------------------------
CONTAINER_FULLNAME=$1
CONTAINER_OSNAME=`echo ${CONTAINER_FULLNAME} | sed 's/:/ /g' | awk '{print $1}'`
CONTAINER_OSVERSION=`echo ${CONTAINER_FULLNAME} | sed 's/:/ /g' | awk '{print $2}'`

#-----------------------------------------------------------
# Common variables for pip
#-----------------------------------------------------------
PIP_BIN="pip3"
PIP_OPTIONS="--upgrade"
INSTALL_AWSCLI_PACKAGES="awscli"

#-----------------------------------------------------------
# Parameters for configure(set environments)
#-----------------------------------------------------------
CONFIGURE_OPTIONS="CXXFLAGS='-std=c++11 -DS3FS_PTHREAD_ERRORCHECK=1' --prefix=/usr --with-openssl"

#-----------------------------------------------------------
# OS dependent variables
#-----------------------------------------------------------
if [ "${CONTAINER_FULLNAME}" = "ubuntu:21.10" ]; then
    PACKAGE_MANAGER_BIN="apt-get"
    PACKAGE_UPDATE_OPTIONS="update -y -qq"

    INSTALL_PACKAGES="autoconf autotools-dev default-jdk fuse libfuse-dev libcurl4-openssl-dev libxml2-dev locales-all mime-support libtool pkg-config libssl-dev attr wget python2 python3-pip"
    INSTALL_CPPCHECK_OPTIONS=""

elif [ "${CONTAINER_FULLNAME}" = "ubuntu:20.04" ]; then
    PACKAGE_MANAGER_BIN="apt-get"
    PACKAGE_UPDATE_OPTIONS="update -y -qq"

    INSTALL_PACKAGES="autoconf autotools-dev default-jdk fuse libfuse-dev libcurl4-openssl-dev libxml2-dev locales-all mime-support libtool pkg-config libssl-dev attr wget python2 python3-pip"
    INSTALL_CPPCHECK_OPTIONS=""

elif [ "${CONTAINER_FULLNAME}" = "ubuntu:18.04" ]; then
    PACKAGE_MANAGER_BIN="apt-get"
    PACKAGE_UPDATE_OPTIONS="update -y -qq"

    INSTALL_PACKAGES="autoconf autotools-dev default-jdk fuse libfuse-dev libcurl4-openssl-dev libxml2-dev locales-all mime-support libtool pkg-config libssl-dev attr wget python3-pip"
    INSTALL_CPPCHECK_OPTIONS=""

elif [ "${CONTAINER_FULLNAME}" = "ubuntu:16.04" ]; then
    PACKAGE_MANAGER_BIN="apt-get"
    PACKAGE_UPDATE_OPTIONS="update -y -qq"

    INSTALL_PACKAGES="autoconf autotools-dev default-jdk fuse libfuse-dev libcurl4-openssl-dev libxml2-dev locales-all mime-support libtool pkg-config libssl-dev attr wget python3-pip"
    INSTALL_CPPCHECK_OPTIONS=""

elif [ "${CONTAINER_FULLNAME}" = "debian:buster" ]; then
    PACKAGE_MANAGER_BIN="apt-get"
    PACKAGE_UPDATE_OPTIONS="update -y -qq"

    INSTALL_PACKAGES="autoconf autotools-dev default-jdk fuse libfuse-dev libcurl4-openssl-dev libxml2-dev locales-all mime-support libtool pkg-config libssl-dev attr wget python2 procps python3-pip"
    INSTALL_CPPCHECK_OPTIONS=""

elif [ "${CONTAINER_FULLNAME}" = "debian:stretch" ]; then
    PACKAGE_MANAGER_BIN="apt-get"
    PACKAGE_UPDATE_OPTIONS="update -y -qq"

    INSTALL_PACKAGES="autoconf autotools-dev default-jdk fuse libfuse-dev libcurl4-openssl-dev libxml2-dev locales-all mime-support libtool pkg-config libssl-dev attr wget procps python3-pip"
    INSTALL_CPPCHECK_OPTIONS=""

elif [ "${CONTAINER_FULLNAME}" = "centos:centos8" ]; then
    PACKAGE_MANAGER_BIN="dnf"
    PACKAGE_UPDATE_OPTIONS="update -y -qq"

    INSTALL_PACKAGES="curl-devel fuse fuse-devel gcc libstdc++-devel gcc-c++ glibc-langpack-en java-11-openjdk libxml2-devel mailcap git automake make openssl-devel attr diffutils wget python2 python3"
    INSTALL_CPPCHECK_OPTIONS="--enablerepo=powertools"

    # [NOTE]
    # Add -O2 to prevent the warning '_FORTIFY_SOURCE requires compiling with optimization(-O)'.
    #
    CONFIGURE_OPTIONS="CXXFLAGS='-O2 -std=c++11 -DS3FS_PTHREAD_ERRORCHECK=1' --prefix=/usr --with-openssl"

elif [ "${CONTAINER_FULLNAME}" = "centos:centos7" ]; then
    PACKAGE_MANAGER_BIN="yum"
    PACKAGE_UPDATE_OPTIONS="update -y"

    INSTALL_PACKAGES="curl-devel fuse fuse-devel gcc libstdc++-devel gcc-c++ glibc-langpack-en java-11-openjdk libxml2-devel mailcap git automake make openssl-devel attr wget python3 epel-release"
    INSTALL_CPPCHECK_OPTIONS="--enablerepo=epel"

    # [NOTE]
    # Add -O2 to prevent the warning '_FORTIFY_SOURCE requires compiling with optimization(-O)'.
    #
    CONFIGURE_OPTIONS="CXXFLAGS='-O2 -std=c++11 -DS3FS_PTHREAD_ERRORCHECK=1' --prefix=/usr --with-openssl"

elif [ "${CONTAINER_FULLNAME}" = "fedora:35" ]; then
    PACKAGE_MANAGER_BIN="dnf"
    PACKAGE_UPDATE_OPTIONS="update -y -qq"

    # TODO: Cannot use java-latest-openjdk (17) due to modules issue
    INSTALL_PACKAGES="curl-devel fuse fuse-devel gcc libstdc++-devel gcc-c++ glibc-langpack-en java-11-openjdk libxml2-devel mailcap git automake make openssl-devel wget attr diffutils python2 procps python3-pip"
    INSTALL_CPPCHECK_OPTIONS=""

elif [ "${CONTAINER_FULLNAME}" = "opensuse/leap:15" ]; then
    PACKAGE_MANAGER_BIN="zypper"
    PACKAGE_UPDATE_OPTIONS="refresh"

    INSTALL_PACKAGES="automake curl-devel fuse fuse-devel gcc-c++ java-11-openjdk libxml2-devel make openssl-devel python3-pip wget attr"
    INSTALL_CPPCHECK_OPTIONS=""

else
    echo "No container configured for: ${CONTAINER_FULLNAME}"
    exit 1
fi

#-----------------------------------------------------------
# Install
#-----------------------------------------------------------
#
# Update packages (ex. apt-get update -y -qq)
#
echo "${PRGNAME} [INFO] Updates."
${PACKAGE_MANAGER_BIN} ${PACKAGE_UPDATE_OPTIONS}

#
# Install pacakages ( with cppcheck )
#
echo "${PRGNAME} [INFO] Install packages."
${PACKAGE_MANAGER_BIN} install -y ${INSTALL_PACKAGES}

echo "${PRGNAME} [INFO] Install cppcheck package."
${PACKAGE_MANAGER_BIN} ${INSTALL_CPPCHECK_OPTIONS} install -y cppcheck

# Check Java version
java -version

#
# Install awscli
#
echo "${PRGNAME} [INFO] Install awscli package."
${PIP_BIN} install ${PIP_OPTIONS} ${INSTALL_AWSCLI_PACKAGES}
${PIP_BIN} install ${PIP_OPTIONS} rsa

#-----------------------------------------------------------
# Set environment for configure
#-----------------------------------------------------------
echo "${PRGNAME} [INFO] Set environment for configure options"
export CONFIGURE_OPTIONS

echo "${PRGNAME} [INFO] Finish Linux helper for installing packages."
exit 0

#
# Local variables:
# tab-width: 4
# c-basic-offset: 4
# End:
# vim600: expandtab sw=4 ts=4 fdm=marker
# vim<600: expandtab sw=4 ts=4
#
