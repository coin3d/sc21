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
#import <OpenGL/gl.h>

#import <Inventor/events/SoKeyboardEvent.h>
#import <Inventor/events/SoMouseButtonEvent.h>
#import <Inventor/events/SoEvent.h>

@class SCController;

@interface SCView : NSOpenGLView <NSCoding>
{
  IBOutlet SCController * controller; 
  int _colorbits; // color depth
  int _depthbits; // z buffer resolution
}

/*" Initializing an SCView "*/
- (id) initWithFrame:(NSRect)rect;
- (void) commonInit;
- (void) awakeFromNib;

/*" Accessing the SCController. "*/
- (SCController *) controller;
- (void) setController:(SCController *) controller;

/*" Drawing, viewing, and view-dependant calculations "*/
- (void) drawRect:(NSRect)rect;
- (void) reshape;

/*" OpenGL setup "*/
- (BOOL) recreateOpenGLContext;
- (void) setColorBits:(int)n;
- (void) setColorBitsNoRecreate:(int)n;
- (int) colorBits;
- (void) setDepthBits:(int)n;
- (void) setDepthBitsNoRecreate:(int)n;
- (int) depthBits;
- (NSOpenGLPixelFormat *) createPixelFormat:(NSRect)frame;

/*" Event handling "*/
- (void) rightMouseDown:(NSEvent *)event;
- (void) mouseDown:(NSEvent *)event;
- (void) mouseUp:(NSEvent *)event;
- (void) mouseDragged:(NSEvent *)event;
- (void) otherMouseDown:(NSEvent *)event;
- (void) otherMouseDragged:(NSEvent *)event;
- (void) scrollWheel:(NSEvent *)event;
- (void) keyDown:(NSEvent *)event;
- (BOOL) becomeFirstResponder;
- (BOOL) acceptsFirstResponder;

/*" Convenience methods and shortcuts "*/
- (float) aspectRatio;
- (NSPoint) normalizePoint:(NSPoint)point;

/*" NSCoding conformance "*/
- (void) encodeWithCoder:(NSCoder *)coder;
- (id) initWithCoder:(NSCoder *)coder;

@end

/*" Posted if no valid pixel format could be created. Typically, this
    would happen in #initWithFrame:, in which case !{nil} is returned
    by the initializer. You can use this notification as some kind of
    informal error reporting, and try to recreate a view with a
    different pixel format when this happens.
 "*/

extern NSString * SCCouldNotCreateValidPixelFormatNotification;

