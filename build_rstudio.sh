#!/bin/bash
# This script installs R and builds RStudio Desktop for Raspberry Pis running Raspbian Stretch

# Setup locale
sudo apt-get install -y locales
sudo DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
echo 'export LANG=en_US.UTF-8' >> ~/.profile
echo 'export LANGUAGE=en_US.UTF-8' >> ~/.profile

# Install R; Debian stretch has latest version
sudo apt-get update
sudo apt-get install -y r-base r-base-dev

# Set RStudio version
VERS=v1.2.1335

# Download RStudio source
mkdir ~/Downloads/
cd ~/Downloads/
wget -O $VERS https://github.com/rstudio/rstudio/tarball/$VERS
mkdir ~/Downloads/rstudio-$VERS
tar xvf ~/Downloads/$VERS -C ~/Downloads/rstudio-$VERS --strip-components 1
rm ~/Downloads/$VERS

# Run environment preparation scripts
sudo apt-get install -y openjdk-8-jdk
cd ~/Downloads/rstudio-$VERS/dependencies/linux/
./install-dependencies-debian --exclude-qt-sdk

# Run common environment preparation scripts
sudo apt-get install -y git
# No arm build for pandoc, so install outside of common script
sudo apt-get install -y pandoc
sudo apt-get install -y libcurl4-openssl-dev

cd ~/Downloads/rstudio-$VERS/dependencies/common/
./install-common
./install-gwt
./install-dictionaries
./install-mathjax
./install-boost
./install-pandoc
./install-libclang
./install-packages

# Add pandoc folder to override build check
mkdir ~/Downloads/rstudio-$VERS/dependencies/common/pandoc

# Get Closure Compiler and replace compiler.jar
cd ~/Downloads
wget http://dl.google.com/closure-compiler/compiler-latest.zip
unzip compiler-latest.zip
rm COPYING README.md compiler-latest.zip
sudo mv closure-compiler*.jar ~/Downloads/rstudio-$VERS/src/gwt/tools/compiler/compiler.jar

# Manually substitute libssl1.0-dev
sudo apt install -y libssl1.0-dev

# Configure cmake and build RStudio
cd ~/Downloads/rstudio-$VERS/
mkdir build
sudo cmake -DRSTUDIO_TARGET=Server -DCMAKE_BUILD_TYPE=Release -DOPENSSL_ROOT_DIR=/usr/lib/ssl -DOPENSSL_LIBRARIES=/usr/lib/ssl
sudo make install

# Additional install steps
sudo useradd -r rstudio-server
sudo cp /usr/local/lib/rstudio-server/extras/init.d/debian/rstudio-server /etc/init.d/rstudio-server
sudo chmod +x /etc/init.d/rstudio-server 
sudo cp /usr/local/lib/rstudio-server/extras/systemd/rstudio-server.service /lib/systemd/system/rstudio-server.service
sudo ln -f -s /usr/local/lib/rstudio-server/bin/rstudio-server /usr/sbin/rstudio-server
sudo chmod 777 -R /usr/local/lib/R/site-library/

# Clean the system of packages used for building
sudo apt-get autoremove -y cabal-install ghc openjdk-8-jdk pandoc libboost-all-dev
sudo rm -r -f ~/Downloads/rstudio-$VERS
sudo apt-get autoremove -y

# Start the server
sudo rstudio-server start

# Go to localhost:8787
