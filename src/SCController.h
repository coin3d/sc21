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
#import <Sc21/SCSceneGraph.h>

class SoDirectionalLight;
class SoSceneManager;
@class SCEventConverter;
@class _SCControllerP;

@interface SCController : NSObject <NSCoding>
{
 @protected
  _SCControllerP * _sc_controller;
  // FIXME: Are we sure we don't want the delegate to be protected? kyrah 20040716
 @private
  id delegate;
  SCSceneGraph * scenegraph;
}

/*" Static initialization "*/
+ (void)initCoin;

/*" Initializing an SCController "*/
- (id)init;

/*" Delegate handling. "*/
- (void)setDelegate:(id)delegate;
- (id)delegate;

/*" Coin rendering and related functionality "*/

- (void)setRedrawHandler:(id)handler;
- (id)redrawHandler;
- (void)setRedrawSelector:(SEL)selector;
- (SEL)redrawSelector;
- (void)render;
- (void)setSceneGraph:(SCSceneGraph *)scenegraph;
- (SCSceneGraph *)sceneGraph;
- (void)setSceneManager:(SoSceneManager *)scenemanager;
- (SoSceneManager *)sceneManager;
- (void)setBackgroundColor:(NSColor *)color;
- (NSColor *)backgroundColor;
- (void)setAutoClipValue:(float)autoclipvalue;
- (float)autoClipValue;
- (void)setClearColorBuffer:(BOOL)yesno;
- (BOOL)clearColorBuffer;
- (void)setClearDepthBuffer:(BOOL)yesno;
- (BOOL)clearDepthBuffer;
- (void)viewSizeChanged:(NSRect)size;


/*" Camera handling. "*/
- (void)viewAll;

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

