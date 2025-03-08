#!/bin/sh

#  ci_post_clone.sh
#  Hackers
#
#  Created by シンジャスティン on 2023/08/23.
#

set -e

echo "Installing CocoaPods."
brew install cocoapods

echo "Installing pods."
cd $CI_PRIMARY_REPOSITORY_PATH/
pod install

echo "Post-clone script completed."
exit 0
