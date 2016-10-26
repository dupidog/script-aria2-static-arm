#!/bin/bash

TOOLCHAINDIR=/opt
TOOLCHAIN=$TOOLCHAINDIR/arm-2014.05
PREFIX=$TOOLCHAIN/usr/local
HOST=arm-none-linux-gnueabi

mkdir -p $TOOLCHAIN
mkdir -p $PREFIX

echo "Start build static aria2c for arm"
echo "TOOLCHAIN: $TOOLCHAIN"
echo "PREFIX:    $PREFIX"
echo "HOST:      $HOST"
echo "BUILDROOT: $(pwd)"
echo

# Install build packages
apt-get install -y build-essential autoconf autopoint automake lib32z1 git docbook2x krb5-multidev libkrb5-3 pkg-config

# Download and extract crosscompiler
wget http://dupidog.tk/arm-2014.05-29-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2
tar -jxf arm-2014.05-29-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2i -C $TOOLCHAINDIR

# PATH for crosscompiler
PATH=$PATH:$TOOLCHAIN/bin/

# Dependence package list
# 1. c-ares
# 2. expat
# 3. zlib
# 4. openssl
# 5. libssh2 (not ok yet)
# 6. sqlite3

# Build and install dependence
# 1. c-ares
git clone https://github.com/c-ares/c-ares.git
cd c-ares
git checkout -b dev cares-1_12_0
sed -i 's#\[-\]#[1.12.0]#' configure.ac
./buildconf
./configure --prefix=$PREFIX --host=$HOST CC=$HOST-gcc --enable-shared=no --enable-static=yes
make
make install
cd ..

# 2. expat
git clone http://git.code.sf.net/p/expat/code_git expat
cd expat
git checkout -b dev R_2_2_0
./buildconf.sh
./configure --prefix=$PREFIX --target=$HOST --host=$HOST CC=$HOST-gcc --enable-shared=no --enable-static=yes
make
make install
cd ..

# 3. zlib
git clone https://github.com/madler/zlib.git
cd zlib
git checkout -b dev v1.2.8
prefix=$PREFIX AR=$HOST-ar CC=$HOST-gcc CFLAGS="-O4" ./configure --static
make
make install
cd ..

# 4. openssl
git clone https://github.com/openssl/openssl.git
cd openssl
git checkout -b dev OpenSSL-fips-2_0_12
./Configure --prefix=$PREFIX --openssldir=$PREFIX --with-zlib-lib=$PREFIX/lib --with-zlib-include=$PREFIX/include --cross-compile-prefix=$HOST- linux-armv4
mv /usr/bin/pod2man /usr/bin/pod2man.bak
make
make install
mv /usr/bin/pod2man.bak /usr/bin/pod2man
cd ..

# 5. libssh2 (not ok yet)

# 6. sqlite3
wget http://www.sqlite.org/2016/sqlite-autoconf-3150000.tar.gz
tar -zxf sqlite-autoconf-3150000.tar.gz
cd sqlite-autoconf-3150000
./configure --prefix=$PREFIX --target=$HOST --host=$HOST CC=$HOST-gcc --enable-threadsafe=no --enable-shared=no --enable-static=yes
make
make install
cd ..

# Build aria2
git clone https://github.com/aria2/aria2.git
cd aria2
autoreconf -i
./configure --host=$HOST --prefix=$PREFIX ARIA2_STATIC=yes CFLAGS="-I$PREFIX/include" LDFLAGS="-L$PREFIX/lib" CPPFLAGS="-I$PREFIX/include" SQLITE3_CFLAGS="-I$PREFIX/include" SQLITE3_LIBS="$PREFIX/lib/libsqlite3.la"
make
make install
cd ..

# Strip binary
cp $PREFIX/bin/aria2c .
$HOST-strip aria2c

echo
echo "Done!"
