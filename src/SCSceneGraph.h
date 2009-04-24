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

#import <Sc21/SCDefines.h>
#import <Sc21/SCCamera.h>

#import <Inventor/SoSceneManager.h>
#import <Inventor/nodes/SoDirectionalLight.h>
#import <Inventor/nodes/SoSeparator.h>

@class SCSceneGraphP;

@interface SCSceneGraph : NSObject <NSCoding>
{
 @protected
  SCSceneGraphP * _sc_scenegraph;
 @private
  id delegate;
}

/*" Initialization "*/
- (id)initWithContentsOfFile:(NSString *)filename;
- (id)initWithContentsOfURL:(NSURL *)URL;

/*" Reading from files and URLS and loading data "*/
- (BOOL)readFromFile:(NSString *)filename;
- (BOOL)readFromURL:(NSURL *)URL;
- (BOOL)loadDataRepresentation:(NSData *)data;

/*" Automatic headlight configuration "*/
// FIXME: -> property?
- (SoDirectionalLight *)headlight;

/*" Camera handling. "*/
// FIXME: -> property?
- (SCCamera *)camera;
- (void)viewAll;

/*" Accessing the actual Coin scenegraph "*/
// FIXME: -> property?
- (SoGroup *)root;
- (BOOL)setRoot:(SoGroup *)root;

  /*" Delegate handling "*/
// FIXME: ->property?
- (void)setDelegate:(id)newdelegate;
- (id)delegate;

@end

@interface NSObject (SCSceneGraphDelegate)

/*" Turning off default superscenegraph creation "*/
- (BOOL)shouldCreateDefaultSuperSceneGraph;

/*" Supplying your own code for superscenegraph creation "*/
- (SoGroup *)createSuperSceneGraph:(SoGroup *)scenegraph;

@end

// ------------------ Notifications -----------------------

/*" 
  Posted if opening a requested file for reading failed because the
  file does not exist or cannot be read.
"*/

SC21_EXTERN NSString * SCCouldNotOpenFileNotification;


/*" 
  Posted if an error occured when reading a file or memory buffer.

  The actual error message reported by SoInput is stored in the
  notification's !{userInfo} dictionary (as value for the
  key %{description}).

  Note that this does not necessarily mean that reading the
  file/buffer failed. (For instance missing texture images are
  reported without aborting loading the file.) If you want to know
  whether reading failed, check the value returned by readFromFile:
"*/

SC21_EXTERN NSString * SCReadErrorNotification;


/*" 
  Posted if !{setSceneGraph:} is called with a scenegraph that does
  not contain a camera. (The check is done after superscenegraph
  creation.)

  Register for this notification if you want to issue a warning to
  your users that they will not be able to see anything. 
"*/

SC21_EXTERN NSString * SCNoCameraFoundInSceneNotification;


/*" 
  Posted if !{setSceneGraph:} is called with a scenegraph that does
  not contain a light. (The check is done after superscenegraph
  creation.)

  Register for this notification if you want to issue a warning to
  your users that they will not be able to see much in the scene
  (since only ambient light will be used.)
"*/

SC21_EXTERN NSString * SCNoLightFoundInSceneNotification;


/*" 
  Posted when the scenegraph is changed through !{setRoot:} 
"*/

SC21_EXTERN NSString * SCSceneGraphChangedNotification;
