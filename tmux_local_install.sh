#!/bin/bash

# Script for installing tmux on systems where you don't have root access.
# tmux will be installed in $HOME/local/bin.
# It's assumed that wget and a C/C++ compiler are installed.

# exit on error
set -e

TMUX_VERSION=3.0a

# create our directories
mkdir -p $HOME/local $HOME/tmux_tmp
cd $HOME/tmux_tmp

# download source files for tmux, libevent, and ncurses
#wget -O tmux-${TMUX_VERSION}.tar.gz http://sourceforge.net/projects/tmux/files/tmux/tmux-${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz/download
echo "Downloading tmux..."
wget https://github.com/tmux/tmux/releases/download/${TMUX_VERSION}/tmux-${TMUX_VERSION}.tar.gz
echo "Downloading libevent..."
wget https://github.com/libevent/libevent/releases/download/release-2.1.11-stable/libevent-2.1.11-stable.tar.gz
echo "Downloading ncurses..."
wget ftp://ftp.gnu.org/pub/gnu/ncurses/ncurses-6.2.tar.gz

# extract files, configure, and compile

############
# libevent #
############
echo "Installing libevent..."
tar xvzf libevent-2.1.11-stable.tar.gz
cd libevent-2.1.11-stable
./configure --prefix=$HOME/local --disable-shared
make -j$(nproc)
make install
cd ..

############
# ncurses  #
############
echo "Installing ncurses..."
tar xvzf ncurses-6.2.tar.gz
cd ncurses-6.2
./configure --prefix=$HOME/local
make -j$(nproc)
make install
cd ..

############
# tmux     #
############
echo "Installing tmux..."
tar xvzf tmux-${TMUX_VERSION}.tar.gz
cd tmux-${TMUX_VERSION}
./configure CFLAGS="-I$HOME/local/include -I$HOME/local/include/ncurses" LDFLAGS="-L$HOME/local/lib -L$HOME/local/include/ncurses -L$HOME/local/include"
CPPFLAGS="-I$HOME/local/include -I$HOME/local/include/ncurses" LDFLAGS="-static -L$HOME/local/include -L$HOME/local/include/ncurses -L$HOME/local/lib" make -j$(nproc)
cp tmux $HOME/local/bin
cd ..

# cleanup
rm -rf $HOME/tmux_tmp

echo "$HOME/local/bin/tmux is now available. You can optionally add $HOME/local/bin to your PATH."
