#!/bin/sh

#
# This is just a small example to prove that we can build SC21 apps
# from the cmd-line.
#
mkdir -p NoNibViewer.app/Contents/MacOS
echo "APPL????" > NoNibViewer.app/Contents/PkgInfo
g++ -c -pipe -c AppController.mm -o AppController.o
g++ -c -pipe -c main.mm -o main.o
g++ -o NoNibViewer.app/Contents/MacOS/NoNibViewer -framework Cocoa -framework Inventor -framework SC21 AppController.o main.o
