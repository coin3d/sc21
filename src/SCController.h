/* ============================================================== *
 |                                                                |
 | This file is part of SC21, a Cocoa user interface binding for  |
 | the Coin 3D visualization library.                             |
 |                                                                |
 | Copyright (c) 2003 Systems in Motion. All rights reserved.     |
 |                                                                |
 | SC21 is free software; you can redistribute it and/or          |
 | modify it under the terms of the GNU General Public License    |
 | ("GPL") version 2 as published by the Free Software            |
 | Foundation.                                                    |
 |                                                                |
 | A copy of the GNU General Public License can be found in the   |
 | source distribution of SC21. You can also read it online at    |
 | http://www.gnu.org/licenses/gpl.txt.                           |
 |                                                                |
 | For using Coin with software that can not be combined with the |
 | GNU GPL, and for taking advantage of the additional benefits   |
 | of our support services, please contact Systems in Motion      |
 | about acquiring a Coin Professional Edition License.           |
 |                                                                |
 | See http://www.coin3d.org/mac/SC21 for more information.       |
 |                                                                |
 | Systems in Motion, Bygdoy Alle 5, 0257 Oslo, Norway.           |
 |                                                                |
 * ============================================================== */
 

#import <Cocoa/Cocoa.h>
#import <SC21/SCEventConverter.h>
#import <SC21/SCCamera.h>

@class SCView;

class SoCamera;
class SoGroup;
class SoLight;
class SoSceneManager;

// FIXME: Why inherit from NSResponder? (kintel 20040407)
// If we change it, we might need to fix initWithCoder, incl. versioning
@interface SCController : NSResponder
{
  IBOutlet SCView * view;
  SCCamera * _camera;
  SCEventConverter * _eventconverter;
  NSTimer * _timerqueuetimer;
  NSTimer * _delayqueuetimer;
  SoGroup * _scenegraph;	  // the whole scenegraph
  SoSceneManager * _scenemanager;
  BOOL _handleseventsinviewer;
  float _autoclipvalue;
}

/*" Static initialization "*/
+ (void)initCoin;

/*" Initializing an SCController "*/
- (id)init;
- (void)commonInit;

/*" Getting the view associated with the controller "*/
- (void)setView:(SCView *)newview;
- (SCView *)view;

/*" Coin rendering and related functionality "*/
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

/*" Debugging aids. "*/
- (BOOL)dumpSceneGraph;

/*" Event handling "*/
- (BOOL)handleEvent:(NSEvent *)event;
- (BOOL)handleEventAsCoinEvent:(NSEvent *)event;
- (BOOL)handleEventAsViewerEvent:(NSEvent *)event;
- (void)setHandlesEventsInViewer:(BOOL)yn;
- (BOOL)handlesEventsInViewer;

/*" Timer management. "*/
- (void)startTimers;
- (void)stopTimers;
- (void)setDelayQueueInterval:(NSTimeInterval)interval;
- (NSTimeInterval)delayQueueInterval;


@end


// --------------------- Notifications ------------------------

/*" Posted whenever the viewer mode (pass events to the scenegraph
    vs. interpret events as viewer manipulation) changes.
 "*/
extern NSString * SCModeChangedNotification;

/*" Posted when the scenegraph is changed through #setSceneGraph: "*/
extern NSString * SCSceneGraphChangedNotification;

/*" Posted if #setSceneGraph: is called with a scenegraph that
    does not contain a camera. Register for this notification if
    you want to issue a warning to your users that they will not
    be able to see anything. Note that SCExaminerController does
    not post this notification; instead, it simply adds a camera
    in front of the scenegraph.
 "*/
extern NSString * SCNoCameraFoundInSceneNotification;

/*" Posted if #setSceneGraph: is called with a scenegraph that
    does not contain a light. Register for this notification if
    you want to issue a warning to your users that they will not
    be able to see much in the scene (since only ambient light
    will be used.)
"*/
extern NSString * SCNoLightFoundInSceneNotification;
