Sc21 Usage Examples 
-------------------

This folder contains the following example programs demonstrating how
you can use Sc21:

++ Sc21Viewer

This is a very simple viewer demonstrating how you can use Sc21. 
It shows you how to open an Inventor or VRML file from disk and
display it. It also demonstrates some ways to interact with the
SCController via context menu actions.

++ Sc21FullscreenViewer

This is a viewer similar to Sc21Viewer, which demonstrates how to use
Coin and Sc21 in fullscreen mode.

++ CustomEventHandling

This is a viewer similar to Sc21Viewer, which demonstrates how to
implement a custom Sc21 event handler. It also shows you how to
emulate the "viewing" vs. "picking" concept used in the So@GUI@
libraries (i.e. having two separate modes: either handling events in
the viewer or sending them down the scenegraph).

++ Viewtiful

Viewtiful is a slightly more involved example showing how to create
a Document-Based Application with Sc21. It includes features such as:
 o Double-click on 3D model to open it
 o Drag and Drop files to the viewer icon
 o Copy to pasteboard
 o New from pasteboard
 o Refresh model
 o Connection to services

++ NoNibViewer

This is a very simple example showing how to write an Sc21 application
without using any nib files.
Note that this way of developing applications is not recommended and
this example is present here just as a proof of concept.

                                --><--

Important note regarding Universal Binaries:
--------------------------------------------

By default, only the native version of the examples is built. To build
universal binaries, do the following:

  - bring up the Target settings dialog (Project -> Edit Active Target)
  - choose the "Build" tab
  - change the Architectures setting from $(NATIE_ARCH) to "ppc i386".
  - rebuild

If you are doing this on a PowerPC machine, you also need to select
the Universal Binaries SDK:

  - bring up the Project Info dialog (Project -> Edit Project Settings)
  - choose the "General" tab
  - select "Mac OS 10.4 (Universal) for the "Cross-Develope Using
    Target SDK" setting

    If you haven't done so yet, you also have to create a symbolic
    link in the Universal Binary SDK so that Inventor.framework and
    Sc21.framework in /Library/Frameworks are found:

    - sudo ln -s /Library/Frameworks /Developer/SDKs/MacOSX10.4u.sdk/

                                --><--

More information about Sc21 can be found at http://www.coin3d.org/mac/Sc21/


