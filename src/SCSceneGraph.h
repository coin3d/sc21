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

@class SCCamera;
@class SCSceneGraphP;
class SoSceneManager;
class SoGroup;
class SoDirectionalLight;

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

/*" File I/O "*/
- (BOOL)readFromFile:(NSString *)filename;
- (BOOL)readFromURL:(NSURL *)URL;
- (BOOL)loadDataRepresentation:(NSData *)data;

/*" Automatic headlight configuration "*/
- (SoDirectionalLight *)headlight;

/*" Camera handling. "*/
- (SCCamera *)camera;
- (void)viewAll;

/*" Accessing the actual Coin scenegraph. "*/
- (SoGroup *)root;
- (void)setRoot:(SoGroup *)root;

  /*" Delegate handling. "*/
- (void)setDelegate:(id)newdelegate;
- (id)delegate;

@end

@interface NSObject (SCSceneGraphDelegate)
/*" Turning off default superscenegraph creation "*/
- (BOOL)shouldCreateDefaultSuperSceneGraph;
/*" Supplying your own code for superscenegraph creation "*/
- (SoGroup *)createSuperSceneGraph:(SoGroup *)scenegraph;
/*" Postprocessing "*/
- (void)didCreateSuperSceneGraph:(SoGroup *)superscenegraph;
@end

// ------------------ Notifications -----------------------

/*" Posted if opening a requested file for reading failed, either
    because the file does not exist or cannot be read  (i.e. 
    !{SoInput::openFile()} failed), or because no valid scenegraph 
    could be read from the file (i.e. !{SoDB::readAll()} returned NULL).                                             
"*/
SC21_EXTERN NSString * SCCouldNotReadFileNotification;

/*" Posted if !{setSceneGraph:} is called with a scenegraph that
    does not contain a camera. Register for this notification if
    you want to issue a warning to your users that they will not
    be able to see anything. 
"*/
SC21_EXTERN NSString * SCNoCameraFoundInSceneNotification;

/*" Posted if !{setSceneGraph:} is called with a scenegraph that
    does not contain a light. Register for this notification if
    you want to issue a warning to your users that they will not
    be able to see much in the scene (since only ambient light
    will be used.)
"*/
SC21_EXTERN NSString * SCNoLightFoundInSceneNotification;

/*" Posted when the scenegraph is changed through !{setRoot:} "*/
SC21_EXTERN NSString * SCSceneGraphChangedNotification;
