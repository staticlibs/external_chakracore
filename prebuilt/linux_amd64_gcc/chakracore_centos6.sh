#!/bin/bash
#
# Copyright 2018, alex at staticlibs.net
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e
set -x

# variables
export CHAKRACORE_GIT_TAG=v1.8.4
export D="sudo docker exec builder"

# docker
sudo docker pull centos:6
sudo docker run \
    -id \
    --name builder \
    -w /opt \
    -v `pwd`:/host \
    -e PERL5LIB=/opt/rh/devtoolset-7/root//usr/lib64/perl5/vendor_perl:/opt/rh/devtoolset-7/root/usr/lib/perl5:/opt/rh/devtoolset-7/root//usr/share/perl5/vendor_perl \
    -e LD_LIBRARY_PATH=/opt/rh/devtoolset-7/root/usr/lib64:/opt/rh/devtoolset-7/root/usr/lib:/opt/rh/python27/root/usr/lib64 \
    -e PYTHONPATH=/opt/rh/devtoolset-7/root/usr/lib64/python2.6/site-packages:/opt/rh/devtoolset-7/root/usr/lib/python2.6/site-packages \
    -e PKG_CONFIG_PATH=/opt/rh/python27/root/usr/lib64/pkgconfig \
    -e PATH=/opt/rh/devtoolset-7/root/usr/bin:/opt/rh/python27/root/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    centos:6 \
    bash

# dependencies
$D yum install -y \
    centos-release-scl-rh
$D yum install -y \
    devtoolset-7 \
    python27 \
    git \
    svn \
    zip \
    xz \
    libxml2-devel

# ninja
$D git clone https://github.com/ninja-build/ninja.git
$D bash -c "cd ninja && git checkout v1.8.2"
$D bash -c "cd ninja && ./configure.py --bootstrap"
$D mkdir -p /usr/local/bin
$D ln -s /opt/ninja/ninja /usr/local/bin/ninja

# cmake
$D git clone https://github.com/Kitware/CMake.git
$D bash -c "cd CMake && git checkout v3.4.3"
$D bash -c "cd CMake && ./configure --prefix=/usr/local"
$D bash -c "cd CMake && make -j 4"
$D bash -c "cd CMake && make install"

# icu
$D git clone https://github.com/staticlibs/external_icu.git
$D mkdir -p /usr/local/include
$D ln -s /opt/external_icu/include/unicode /usr/local/include/unicode
$D mkdir -p /usr/local/lib64
$D ln -s /opt/external_icu/prebuilt/linux_amd64_gcc/libicuuc.so /usr/local/lib64/libicuuc.so
$D ln -s /opt/external_icu/prebuilt/linux_amd64_gcc/libicui18n.so /usr/local/lib64/libicui18n.so

# clang
$D svn checkout https://llvm.org/svn/llvm-project/llvm/tags/RELEASE_502/final/ llvm
$D svn checkout https://llvm.org/svn/llvm-project/cfe/tags/RELEASE_502/final/ llvm/tools/clang
$D mkdir llvm-build
$D bash -c "cd llvm-build && \
    cmake \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_ENABLE_ASSERTIONS=ON \
    -DLLVM_ENABLE_TERMINFO=OFF \
    -DLLVM_ENABLE_LIBXML2=FORCE_ON \
    -DLLVM_TARGETS_TO_BUILD=X86 \
    -DCMAKE_INSTALL_PREFIX=/opt/llvm-install \
    -DCMAKE_C_COMPILER=/opt/rh/devtoolset-7/root/usr/bin/gcc \
    -DCMAKE_CXX_COMPILER=/opt/rh/devtoolset-7/root/usr/bin/g++ \
    /opt/llvm"
$D ninja -C /opt/llvm-build
$D ninja -C /opt/llvm-build install

# patchelf
$D git clone https://github.com/wilton-iot/tools_linux_patchelf.git
$D mkdir -p /usr/local/bin
$D ln -s /opt/tools_linux_patchelf/patchelf /usr/local/bin/patchelf

# chakracore
$D git clone https://github.com/Microsoft/ChakraCore.git
$D bash -c "cd ChakraCore && git checkout ${CHAKRACORE_GIT_TAG}"
$D mkdir chakracore-build
$D bash -c "cd chakracore-build && \
    cmake \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=/opt/llvm-install/bin/clang++ \
    -DCMAKE_C_COMPILER=/opt/llvm-install/bin/clang \
    -DICU_SETTINGS_RESET=1 \
    -DSHARED_LIBRARY_SH=1 \
    -DLIBS_ONLY_BUILD_SH=1 \
    -DCC_USES_SYSTEM_ARCH_SH=1 \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
    -DCMAKE_C_FLAGS=--gcc-toolchain=/opt/rh/devtoolset-7/root/usr \
    -DCMAKE_CXX_FLAGS=--gcc-toolchain=/opt/rh/devtoolset-7/root/usr \
    /opt/ChakraCore"
$D ninja -C /opt/chakracore-build
$D cp /opt/chakracore-build/libChakraCore.so .
$D strip libChakraCore.so
$D patchelf --set-rpath '$ORIGIN/.' libChakraCore.so
$D mv libChakraCore.so /host
