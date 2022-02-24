#!/bin/bash
#
mkdir -p ~/git/hub/simmel/
pushd ~/git/hub/simmel/
git clone https://github.com/simmel/urxvt-resize-font.git
popd

mkdir -p ~/.urxvt/ext/
ln --symbolic  ~/git/hub/simmel/urxvt-resize-font/resize-font ~/.urxvt/ext/

echo "Add the the following line to .Xdefaults or .Xresources"
echo "URxvt.perl-ext-common: default,tabbed,matcher,resize-font,-tabbed"
