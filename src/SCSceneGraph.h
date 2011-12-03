/**************************************************************************\
 * Copyright (c) Kongsberg Oil & Gas Technologies AS
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the copyright holder nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
\**************************************************************************/

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
