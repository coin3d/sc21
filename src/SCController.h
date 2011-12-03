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
