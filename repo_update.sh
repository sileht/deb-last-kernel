#!/bin/bash

# set -x
set -e

TAG="^v5.4[^-]*$"
SKIP_BUILD=$1

cd  ~/workspace/kernel/linux
git fetch --all --tags -q
VERSION=$(git tag | grep $TAG | sort -V | tail -1)
git reset --hard $VERSION
VERSION=${VERSION#v}
NEXT_SUFFIX=$(cat .version)
SUFFIX=$((NEXT_SUFFIX - 1))

# echo $VERSION

CURRENT=$(awk -F: '/^Version: /{print $2}' ../mykernel.control | xargs)
if [ "$VERSION-$SUFFIX" == "$CURRENT" ]; then
    echo "Up to date ($VERSION-$SUFFIX == $CURRENT)"
    exit 0
else
    echo "Building new kernel ($VERSION-$SUFFIX != $CURRENT)"
fi

if [ ! "$SKIP_BUILD" ]; then
    make olddefconfig
    time schedtool -B -n 1 -e ionice -n 1 make -j $(nproc) bindeb-pkg
fi

cd  ~/workspace/kernel

sed -e "s,#VERSION#,${VERSION},g" -e "s,#SUFFIX#,${NEXT_SUFFIX},g" mykernel.template > mykernel.control

sudo equivs-build mykernel.control

dpkg-scanpackages --multiversion . /dev/null | gzip -9c > Packages.gz
