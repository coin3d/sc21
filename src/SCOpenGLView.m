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

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <Sc21/SCOpenGLView.h>
#import <Sc21/SCOpenGLPixelFormat.h>

#define PRIVATE(p) ((p)->scopenglviewpriv)
#define SELF PRIVATE(self)

@interface _SCOpenGLViewP : NSObject
{
 @public
  NSOpenGLContext * openGLContext;
  SCOpenGLPixelFormat * pixelformat;
}
@end

@implementation _SCOpenGLViewP
@end

 @interface SCOpenGLView(InternalAPI)
 - (void)_SC_commonInit;
 - (void)_SC_updateNeeded:(NSNotification *)notification;
 - (void)_SC_reshapeNeeded:(NSNotification *)notification;
 @end

 @implementation SCOpenGLView

 /*"  
   Designated initializer.

   Initializes a newly allocated NSOpenGLView with frameRect as its
   frame rectangle and format as its pixel format.
 "*/
 - (id)initWithFrame:(NSRect)frameRect pixelFormat:(SCOpenGLPixelFormat *)format
 {
   NSLog(@"SCOpenGLView.initWithFrame:pixelFormat");

   self = [super initWithFrame:frameRect];
   if (self) {
     [self _SC_commonInit];
     SELF->pixelformat = [format retain];
   }
   return self;
 }

 - (id)initWithFrame:(NSRect)frameRect
 {  
   NSLog(@"SCOpenGLView.initWithFrame:");

   return [self initWithFrame:frameRect pixelFormat:nil];
 }

 - (void)dealloc
 {
   NSLog(@"SCOpenGLView.dealloc");

   [[NSNotificationCenter defaultCenter] removeObserver:self];

   [self clearGLContext];
   [self setPixelFormat:nil];
   [SELF release];
   [super dealloc];
 }


 /*"
   Returns a default #SCOpenGLPixelFormat.
   Loops through an internal prioritized list of pixel format requirements
   and selects the first valid pixelformat found.
 "*/
 + (SCOpenGLPixelFormat *)defaultPixelFormat
 {
   NSLog(@"SCOpenGLView.defaultPixelFormat");

   SCOpenGLPixelFormat * pixelFormat = [[SCOpenGLPixelFormat alloc] init];
   [pixelFormat setAttribute:NSOpenGLPFADoubleBuffer];
   [pixelFormat setAttribute:NSOpenGLPFAAccelerated];
   [pixelFormat setAttribute:NSOpenGLPFAColorSize toValue:24];
   [pixelFormat setAttribute:NSOpenGLPFAAlphaSize toValue:8];
   [pixelFormat setAttribute:NSOpenGLPFADepthSize toValue:32];
   [pixelFormat autorelease];
   return pixelFormat;

 #if 0
   NSOpenGLPFAAllRenderers
   NSOpenGLPFADoubleBuffer
   NSOpenGLPFAStereo      
   NSOpenGLPFAMinimumPolicy
   NSOpenGLPFAMaximumPolicy
   NSOpenGLPFAOffScreen    
   NSOpenGLPFAFullScreen   
   NSOpenGLPFASingleRenderer 
   NSOpenGLPFANoRecovery     
   NSOpenGLPFAAccelerated    
   NSOpenGLPFAClosestPolicy  
   NSOpenGLPFARobust         
   NSOpenGLPFABackingStore   
   NSOpenGLPFAMPSafe         
   NSOpenGLPFAWindow         
   NSOpenGLPFAMultiScreen    
   NSOpenGLPFACompliant      
   NSOpenGLPFAPixelBuffer    

   NSOpenGLPFAAuxBuffers  
   NSOpenGLPFAColorSize   
   NSOpenGLPFAAlphaSize   
   NSOpenGLPFADepthSize   
   NSOpenGLPFAStencilSize 
   NSOpenGLPFAAccumSize   
   NSOpenGLPFARendererID     
   NSOpenGLPFAScreenMask     
   NSOpenGLPFASampleBuffers
   NSOpenGLPFASamples      

   NSOpenGLPFAAuxDepthStencil
 #endif
 }

/*"
  Sets the receiver's #SCOpenGLPixelFormat to pixelFormat
  
  FIXME: Should we force a recreation of our OpenGL context?
  Test how NSOpenGLView behaves and document this
  (kintel 20040456)
"*/
- (void)setPixelFormat:(SCOpenGLPixelFormat *)pixelFormat
{
  NSLog(@"SCOpenGLView.setPixelFormat");

  [pixelFormat retain];
  [SELF->pixelformat release];
  SELF->pixelformat = pixelFormat;
}

/*"
  Returns the #SCOpenGLPixelFormat associated with the receiver.
"*/
- (SCOpenGLPixelFormat *)pixelFormat
{
  NSLog(@"SCOpenGLView.pixelFormat");

  return SELF->pixelformat;
}

/*"
  Used by subclassers to initialize OpenGL state. This function is called
  once after an OpenGL context is created and the drawable is attached.
  
  FIXME: This is just the current suggestion. Update when finished:
  Under Panther, NSOpenGLContext will automatically send this message to
  its view from its makeCurrentContext method.
  Under Jaguar, this function is called explicitly from our
  -openGLContext method, emulating Panther's behavior.
"*/
- (void)prepareOpenGL
{
  NSLog(@"SCOpenGLView.prepareOpenGL");
  glEnable(GL_DEPTH_TEST);
  glClearColor(0.0, 0.0, 0.0, 0.0);
  glClear(GL_COLOR_BUFFER_BIT);
}

/*"
  Releases the NSOpenGLContext associated with the receiver. If
  necessary, this method calls clearDrawable on the context before
  releasing it.
"*/
- (void)clearGLContext
{
  NSLog(@"SCOpenGLView.clearGLContext");

  if (SELF->openGLContext) {
    if ([SELF->openGLContext view] == self) [SELF->openGLContext clearDrawable];
    [SELF->openGLContext autorelease];
    SELF->openGLContext = nil;
  }
}

/*"
  Returns the NSOpenGLContext associated with the receiver. If the
  receiver has no associated context, a new NSOpenGLContext is created
  and returned. The new NSOpenGLContext is initialized with the
  receiver's -pixelFormat. If this function returns nil,
  a new pixelformat is created using +defaultPixelFormat.
"*/
- (NSOpenGLContext *)openGLContext
{
  if (!SELF->openGLContext) {
    NSLog(@"SCOpenGLView.openGLContext: Creating new context");
    
    SCOpenGLPixelFormat * format = [self pixelFormat];
    if (!format) {
      format = [SCOpenGLView defaultPixelFormat];
      [self setPixelFormat:format];
    }
    SELF->openGLContext = 
      [[NSOpenGLContext alloc] initWithFormat:[format pixelFormat]
                               shareContext:nil];

    //FIXME: Decide how to handle OpenGL initialization under Jaguar.
    // Take this into account:
    // o The code below should _only_ be run under Jaguar since Panther
    //   will run prepareOpenGL directly.
    // o We can check run-time what OS/AppKit version we have
    //   (NSAppKitVersionNumber).
    // o Is it OK to assume that prepareOpenGL will work when compiling
    //   under Jaguar and running under Panther? If not, we should
    //   probably not use prepareOpenGL at all, but a similar method
    //   that will work with both OS versions.
    [SELF->openGLContext setView:self];
    [SELF->openGLContext makeCurrentContext];
    [self prepareOpenGL];
  }
  return SELF->openGLContext;
}


/*"
  Sets the NSOpenGLContext used by the receiver to allow sharing the
  same context on a per view basis. Replaces the existing context if
  one was already created. You must call setView: on the context to
  sync the context with the view.
"*/
- (void)setOpenGLContext:(NSOpenGLContext *)context
{
  NSLog(@"SCOpenGLView.setOpenGLContext");

  [context retain];
  if (SELF->openGLContext) {
    if ([SELF->openGLContext view] == self) [SELF->openGLContext clearDrawable];
    [SELF->openGLContext release];
  }
  SELF->openGLContext = context;
}

/*"
  Called if the visible rectangle or bounds of the receiver change
  (for scrolling or resize). The default implementation does
  nothing. Override this method if you need to adjust the viewport and
  display frustum.

  -reshape is called when:
  o after init (FIXME: Is this correct? kintel 20040505)
  o window size changes (i.e. after an NSViewFrameDidChangeNotification)

  FIXME: Using NSOpenGLView, reshape is called when a scrollview is
  scrolled. This does not happen with SCOpenGLView. The reason seems to
  be that for our view, NSView.translateOriginToPoint: is not called.
  Test this with "OpenGL scroller"/"NSOpenGL scroller". (kintel 20040505)

  FIXME: Should we make sure that we have a valid context before calling reshape?
  FIXME: Should we call reshape after creating a context (i.e. after prepareOpenGL) ?
"*/
- (void)reshape
{
}

/*"
  Called if the view's context needs to be updated because the window
  moves, or if the view moves or is resized. This method simply calls
  NSOpenGLContext's update. Override this method if you need to add
  locks for multithreaded access to multiple contexts.

  -update is called whenever the view changes size or location.
"*/
- (void)update
{
  if ([SELF->openGLContext view] == self) [SELF->openGLContext update];
}

// Overridden methods from parent

/*"
  Overridden from NSView: we are always drawing every pixel.
"*/
- (BOOL)isOpaque
{
  return YES;
}

/*"
  Overridden from NSView to ensure that we have a valid context
  bound to this view.
"*/
- (void)lockFocus
{
  // NSLog(@"SCOpenGLView.lockFocus");

  NSOpenGLContext * context = [self openGLContext];
  [super lockFocus];
  
  if ([context view] != self) {
    [context setView:self];
  }
  [context makeCurrentContext];
}

// ----------------- NSCoding compliance --------------------

- (void)encodeWithCoder:(NSCoder *)coder 
{
  NSLog(@"SCOpenGLView.encodeWithCoder:");

  [super encodeWithCoder:coder];
  if (![coder allowsKeyedCoding]) {
    [coder encodeObject:SELF->pixelformat];
  } else {
    NSLog(@"  allowsKeyedCoding");
    [coder encodeObject:SELF->pixelformat forKey:@"SC_pixelformat"];
  }
}

- (id)initWithCoder:(NSCoder *)coder 
{
  NSLog(@"SCOpenGLView.initWithCoder:");

  if (self = [super initWithCoder:coder]) {
    [self _SC_commonInit];
    if (![coder allowsKeyedCoding]) {
      SELF->pixelformat = [[coder decodeObject] retain];
    } else {
      NSLog(@"  allowsKeyedCoding");
      SELF->pixelformat = [[coder decodeObjectForKey:@"SC_pixelformat"] retain];
    }
  }
  return self;
}

@end

// ----------------------- InternalAPI -------------------------

@implementation SCOpenGLView(InternalAPI)

- (void)_SC_commonInit
{
  SELF = [[_SCOpenGLViewP alloc] init];

  [[NSNotificationCenter defaultCenter] 
    addObserver:self 
    selector:@selector(_SC_updateNeeded:) 
    name:NSViewGlobalFrameDidChangeNotification 
    object:self];
  
  [[NSNotificationCenter defaultCenter] 
    addObserver:self 
    selector:@selector(_SC_reshapeNeeded:) 
    name:NSViewFrameDidChangeNotification 
    object:self];
  //  [self reshape]; //FIXME: Not sure if NSOpenGLView does this (kintel 20040505)
}

- (void)_SC_updateNeeded:(NSNotification *)notification
{
  NSLog(@"SCOpenGLView._SC_updateNeeded");
  [self update];
}

- (void)_SC_reshapeNeeded:(NSNotification *)notification
{
  NSLog(@"SCOpenGLView._SC_reshapeNeeded:");
  [self reshape];
}

@end
