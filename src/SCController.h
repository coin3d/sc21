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
#import <Sc21/SCDefines.h>
#import <Sc21/SCCamera.h>

class SoCamera;
class SoGroup;
class SoLight;
class SoDirectionalLight;
class SoSceneManager;
@class SCEventConverter;
@class _SCControllerP;

@interface SCController : NSObject <NSCoding>
{
  @protected
    _SCControllerP * sccontrollerpriv;
}

/*" Static initialization "*/
+ (void)initCoin;

/*" Initializing an SCController "*/
- (id)init;

- (void)setDelegate:(id)newdelegate;
- (id)delegate;

/*" Coin rendering and related functionality "*/

- (void)setRedrawHandler:(id)handler;
- (id)redrawHandler;
- (void)setRedrawSelector:(SEL)selector;
- (SEL)redrawSelector;
- (void)render;
- (void)setSceneGraph:(SoGroup *)scenegraph;
- (SoGroup *)sceneGraph;
- (void)setSceneManager:(SoSceneManager *)scenemanager;
- (SoSceneManager *)sceneManager;
- (void)setBackgroundColor:(NSColor *)color;
- (NSColor *)backgroundColor;
- (void)viewSizeChanged:(NSRect)size;
- (void)setAutoClipValue:(float)autoclipvalue;
- (float)autoClipValue;

/*" Camera handling. "*/
- (void)setCamera:(SoCamera *)camera;
- (SoCamera *)camera;
- (SCCameraType)cameraType; // see SCCamera.h for SCCameraType enum

/*" Automatic headlight configuration "*/
- (SoDirectionalLight *)headlight;
- (BOOL)headlightIsOn;
- (void)setHeadlightIsOn:(BOOL)yn;

/*" Event handling "*/
- (BOOL)handleEvent:(NSEvent *)event inView:(NSView *)view;
- (BOOL)handleEventAsCoinEvent:(NSEvent *)event inView:(NSView *)view;
- (BOOL)handleEventAsViewerEvent:(NSEvent *)event inView:(NSView *)view;
- (void)setHandlesEventsInViewer:(BOOL)yn;
- (BOOL)handlesEventsInViewer;

/*" Timer management. "*/
- (void)startTimers;
- (void)stopTimers;

@end

@interface NSObject (SCControllerDelegate)
- (SoGroup *)willSetSceneGraph:(SoGroup *)scenegraph;
- (void)didSetSceneGraph:(SoGroup *)superscenegraph;
@end

// --------------------- Notifications ------------------------

/*" Posted whenever the viewer mode (pass events to the scenegraph
    vs. interpret events as viewer manipulation) changes.
 "*/
SC21_EXTERN NSString * SCModeChangedNotification;

/*" Posted when the scenegraph is changed through #setSceneGraph: "*/
SC21_EXTERN NSString * SCSceneGraphChangedNotification;

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
