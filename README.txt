Introduction
------------

Sc21 is an Objective-C++ framework to integrate the Coin library with
the Mac OS X user interface, allowing you to do Coin rendering in
Cocoa applications.

See http://www.coin3d.org/mac/Sc21/ for more information on Sc21.


Building
--------

To build the Sc21 framework and palette, open the Sc21.xcode project
and choose the target "Sc21 palette". (Since the palette depends on
the framework, the framework will be included in the build
automatically.) To build only the framework, use the "Sc21 framework"
target.

You can also build from the commandline by executing

xcodebuild -project Sc21.xcode -target <targetname> -buildstyle
release|debug

e.g.

xcodebuild -project Sc21.xcode -target "Sc21 framework" -buildstyle
debug


To build installer packages, Xcode 1.5 is required. The other targets
should be buildable with any Xcode version.

Contact
-------

Please contact us at <coin-support@coin3d.org> if you have any
questions regarding Sc21.


Enjoy!

--
Karin Kosina <kyrah@sim.no>
