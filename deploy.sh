#!/bin/bash
#
# Copyright 2012 Alexander Rössler <mail.aroessler@gmail.com>
#
# deploy.sh
# Script for deploying application to Open Build Service
#
# deploy.sh is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# deploy.sh is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with deploy.sh  If not, see <http://www.gnu.org/licenses/>.

CONFIG_DIR=`pwd`

DROPBOX_SCRIPT=dropbox.py
CHANGELOG_SCRIPT=changelog.py

NAME=`sed -n 's/.*NAME\s*=\s*\(.*\).*/\1/p' config.cfg`
SVN_URL=`sed -n 's/.*SVN_URL\s*=\s*\(.*\).*/\1/p' config.cfg`
GIT_URL=`sed -n 's/.*GIT_URL\s*=\s*\(.*\).*/\1/p' config.cfg`
DROPBOX_URL=`sed -n 's/.*DROPBOX_URL\s*=\s*\(.*\).*/\1/p' config.cfg`
AUTHOR=`sed -n 's/.*AUTHOR\s*=\s*\(.*\).*/\1/p' config.cfg`
TARGET_DIR=`sed -n 's/.*TARGET_DIR\s*=\s*\(.*\).*/\1/p' config.cfg`

if [ "$SVN_URL" != "" ]; then  
  echo "Checking out $NAME..."
  svn checkout $SVN_URL ./tmp/
  cd tmp
  SVN_VERSION=`svnversion`
else
  echo "Cloning $NAME..."
  git clone $GIT_URL ./tmp/
  cd tmp
fi

VERSION=`sed -n 's/.*VERSION\s*=\s*\([^\s]*\).*/\1/p' *.pro`
RELEASE="1"

echo "Detected version $VERSION"

TARBALL1="$NAME-$VERSION.tar.bz2"
TARBALL2="$NAME"_"$VERSION.orig.tar.gz"
TARBALL3="$NAME"_"$VERSION-$RELEASE.debian.tar.gz"
DSCFILE="$NAME"_"$VERSION-$RELEASE.dsc"
SPECFILE="$NAME.spec"
DSC_PRE="debian.dsc"
SPEC_PRE="rpm.spec"

echo "Preparing sources..."
find . -name ".svn" -type d -exec rm -rf {} \;
find . -name ".git" -type d -exec rm -rf {} \;
find . -name ".gitignore" -type f -exec rm -rf {} \;
cd ..
mv tmp "$NAME-$VERSION"

echo "Creating changelog..."
$CHANGELOG_SCRIPT "$NAME" "$AUTHOR"
rm ./debian/changelog
cp "changelog-deb.txt" ./debian/changelog
rm "changelog-deb.txt"
echo -e "" >> $SPECFILE
cat "changelog-rpm.txt" >> $SPECFILE
rm "changelog-rpm.txt"

echo "Creating tarballs..."
tar -cvjf $TARBALL1 "$NAME-$VERSION"
tar -czvf $TARBALL2 "$NAME-$VERSION"
tar -czvf $TARBALL3 "debian"
rm -R --force "$NAME-$VERSION"
MD5_1=`md5sum $TARBALL2 | awk '{ print $1 }'`
MD5_2=`md5sum $TARBALL3 | awk '{ print $1 }'`
FILESIZE_1=$(stat -c%s "$TARBALL2")
FILESIZE_2=$(stat -c%s "$TARBALL3")

echo "Start renaming..."
sed "s/!!NAME!!/$NAME/" $DSC_PRE | sed "s/!!VERSION!!/$VERSION-$RELEASE/"  > $DSCFILE
sed "s/!!NAME!!/$NAME/" $SPEC_PRE | sed "s/!!VERSION!!/$VERSION/" | sed "s/!!RELEASE!!/$RELEASE/" > $SPECFILE

echo -e "\n $MD5_1 $FILESIZE_1 $TARBALL2\n $MD5_2 $FILESIZE_2 $TARBALL3" >> $DSCFILE

echo "Removing old files..."
cd $TARGET_DIR
osc rm *.tar.bz2 --force
osc rm *.tar.gz --force
osc rm *.dsc --force
osc rm *.spec --force

echo "Moving new files..."
cd $CONFIG_DIR
mv $SPECFILE $TARGET_DIR
mv $DSCFILE $TARGET_DIR
mv $TARBALL1 $TARGET_DIR
mv $TARBALL2 $TARGET_DIR
mv $TARBALL3 $TARGET_DIR

echo "Adding new files..."
cd $TARGET_DIR
osc add $TARBALL3
osc add $TARBALL2
osc add $TARBALL1
osc add $DSCFILE
osc add $SPECFILE

echo "Copying files to Dropbox..."
mkdir $DROPBOX_URL
cp $TARBALL1 $DROPBOX_URL
echo $TARBALL1 >> "$CONFIG_DIR/puburl.txt"
$DROPBOX_SCRIPT puburl "$DROPBOX_URL$TARBALL1" >> "$CONFIG_DIR/puburl.txt"

echo "Releasing $NAME $VERSION..."
osc commit -m "Release $VERSION"