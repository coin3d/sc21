/* =============================================================== *
|                                                                 |
| This file is part of Sc21, a Cocoa user interface binding for   |
| the Coin 3D visualization library.                              |
|                                                                 |
| Copyright (c) 2003-2004 Systems in Motion. All rights reserved. |
|                                                                 |
| Sc21 is free software; you can redistribute it and/or           |
| modify it under the terms of the GNU General Public License     |
| ("GPL") version 2 as published by the Free Software             |
| Foundation.                                                     |
|                                                                 |
| A copy of the GNU General Public License can be found in the    |
| source distribution of Sc21. You can also read it online at     |
| http://www.gnu.org/licenses/gpl.txt.                            |
|                                                                 |
| For using Coin with software that can not be combined with the  |
| GNU GPL, and for taking advantage of the additional benefits    |
| of our support services, please contact Systems in Motion       |
| about acquiring a Coin Professional Edition License.            |
|                                                                 |
| See http://www.coin3d.org/mac/Sc21 for more information.        |
|                                                                 |
| Systems in Motion, Bygdoy Alle 5, 0257 Oslo, Norway.            |
|                                                                 |
* =============================================================== */

#import <Cocoa/Cocoa.h>
#import <Sc21/SCCamera.h>
#import <Sc21/SCDefines.h>
#import <Inventor/nodes/SoCamera.h>
#import <Inventor/nodes/SoSeparator.h>
#import <Inventor/nodes/SoDirectionalLight.h>

// Note: I find it really degoutant that this class should be named
// SCSceneGraph instead of SCSceneGraph -- scenegraph is one word,
// for goddess sake! But the folks who designed the original Inventor
// API Thought Different, and hence are using setSceneGraph() &c.
// all over the place... so for consistency's sake, let's trudge along.
// kyrah 20040716

@interface SCSceneGraph : NSObject {
  // FIXME: Pimplify.
  @protected
  SCCamera * camera;
  SoSeparator * scenegraph;	 
  SoSeparator * superscenegraph;
  SoDirectionalLight * headlight;  
}

  /*" Initialization "*/
- (id)initWithContentsOfFile:(NSString *)filename;
- (id)initWithContentsOfURL:(NSURL *)url;

  /*" Automatic headlight configuration "*/
- (SoDirectionalLight *)headlight;
- (BOOL)headlightIsOn;
- (void)setHeadlightIsOn:(BOOL)yn;

  /*" Camera handling. "*/
- (void)setCamera:(SoCamera *)camera;
- (SoCamera *)camera;
- (SCCameraType)cameraType; // see SCCamera.h for SCCameraType enum
- (void) viewAll;

- (NSString *)name;
- (BOOL)setName:(NSString *)name;
- (SoSeparator *)superSceneGraph; 
- (SoSeparator *)root;
- (void)setRoot:(SoSeparator *)root;

// FIXME: NSCoding support!
// FIXME: implement copy/paste - initWithPasteboard &c.
// FIXME: add +(id) scenegraphNamed:(NSString *) name which will look for named nodes in all
// .iv/.wrl files in the app bundle
// FIXME: add "lazy initialization methods (initByReferencing[File|URL])
// FIXME: Provide incremental loading delegate method (as in NSImage)?

@end

// FIXME: When done with pimplification, move to private header file!
@interface SCSceneGraph (InternalAPI)
- (SoLight *)_SC_findLightInSceneGraph:(SoGroup *)root;
- (SoCamera *)_SC_findCameraInSceneGraph:(SoGroup *)root;
- (SoSeparator *)_SC_createSuperSceneGraph:(SoGroup *)scenegraph;
@end  

// ------------------ Notifications -----------------------

/*" Posted if #setSceneGraph: is called with a scenegraph that
    does not contain a camera. Register for this notification if
    you want to issue a warning to your users that they will not
    be able to see anything. Note that SCExaminerController does
    not post this notification; instead, it simply adds a camera
    in front of the scenegraph.
"*/
SC21_EXTERN NSString * SCNoCameraFoundInSceneNotification;

/*" Posted if #setSceneGraph: is called with a scenegraph that
    does not contain a light. Register for this notification if
    you want to issue a warning to your users that they will not
    be able to see much in the scene (since only ambient light
    will be used.)
"*/
SC21_EXTERN NSString * SCNoLightFoundInSceneNotification;

/*" Posted whenever the headlight has been turned on or off. "*/
SC21_EXTERN NSString * SCHeadlightChangedNotification;
