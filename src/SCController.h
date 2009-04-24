/* =============================================================== *
 |                                                                 |
 | This file is part of Sc21, a Cocoa user interface binding for   |
 | the Coin 3D visualization library.                              |
 |                                                                 |
 | Copyright (c) 2003-2009 Kongsberg SIM AS . All rights reserved. |
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
 | of our support services, please contact Kongsberg SIM AS        |
 | about acquiring a Coin Professional Edition License.            |
 |                                                                 |
 | See http://www.coin3d.org/mac/Sc21 for more information.        |
 |                                                                 |
 | Kongsberg SIM AS , Bygdoy Alle 5, 0257 Oslo, Norway.            |
 |                                                                 |
 * =============================================================== */

#import <Cocoa/Cocoa.h>

#import <Sc21/SCDrawable.h>
#import <Sc21/SCSceneGraph.h>
#import <Sc21/SCEventHandler.h>

#import <Inventor/SoSceneManager.h>

@class SCControllerP;

@interface SCController : NSObject <NSCoding>
{
@protected
  SCControllerP * _sc_controller;
@private
  SCSceneGraph * sceneGraph;
  SCEventHandler * eventHandler;
}

#if 0 // FIXME: Hold back property implementation until this can be done properly. kintel 20090326.
//@property BOOL clearsColorBuffer;
//@property BOOL clearsDepthBuffer;
// FIXME: Should we set retain here as well, even when we implement the setter/getter ourselves? In general, is retain done for us or is this just a hint? kintel 20090325
//@property(retain) SCSceneGraph * sceneGraph;
//@property(retain) SCEventHandler * eventHandler;
#endif

/*" Static initialization "*/
+ (void)initCoin;

/*" Initializing an SCController "*/
- (id)init;

/*" Coin rendering and related functionality "*/
- (void)render;

/*" Accessing the drawable "*/
// FIXME: -> property?
- (void)setDrawable:(id<SCDrawable>)newdrawable;
- (id<SCDrawable>)drawable;

/*" Accessing the scenegraph and scenemanager "*/
- (void)setSceneGraph:(SCSceneGraph *)scenegraph;
- (SCSceneGraph *)sceneGraph;
- (void)setSceneManager:(SoSceneManager *)scenemanager;
- (SoSceneManager *)sceneManager;

/*" Render settings "*/
// FIXME: -> property?
- (void)setBackgroundColor:(NSColor *)color;
- (NSColor *)backgroundColor;
- (void)setClearsColorBuffer:(BOOL)yesno;
- (BOOL)clearsColorBuffer;
- (void)setClearsDepthBuffer:(BOOL)yesno;
- (BOOL)clearsDepthBuffer;

/*" Event handling "*/
- (BOOL)handleEvent:(NSEvent *)event;
- (void)setEventHandler:(SCEventHandler *)handler;
- (SCEventHandler *)eventHandler;
@end

// --------------------- Notifications ------------------------

/*" 
  Posted when the scenegraph is changed through !{setSceneGraph:} 
"*/

SC21_EXTERN NSString * SCSceneGraphChangedNotification;
