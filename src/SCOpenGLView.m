#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import "SCOpenGLView.h"
#import "SCOpenGLPixelFormat.h"

@interface SCOpenGLView(InternalAPI)
- (void)_surfaceNeedsUpdate:(NSNotification *)notification;
- (void)_reshapeNeeded:(NSNotification *)notification;
@end

@implementation SCOpenGLView

/*!  
  Designated initializer.

  Initializes a newly allocated NSOpenGLView with frameRect as its
  frame rectangle and format as its pixel format.
*/
- (id)initWithFrame:(NSRect)frameRect pixelFormat:(SCOpenGLPixelFormat *)format
{
  NSLog(@"SCOpenGLView.initWithFrame:pixelFormat");

  self = [super initWithFrame:frameRect];
  if (self) {
    _pixelformat = [format retain];
    //FIXME: This is for context update (kintel 20040404)
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                          selector:@selector(_surfaceNeedsUpdate:) 
                                          name:NSViewGlobalFrameDidChangeNotification 
                                          object:self];
    
    //FIXME: This is for reshape => remove it (kintel 20040404)
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                          selector:@selector(_reshapeNeeded:) 
                                          name:NSViewFrameDidChangeNotification 
                                          object:self];
    //FIXME: update/reshape here? (kintel 20040404)
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
  [_pixelformat release];
  [super dealloc];
}


/*!
  Will create and return a default pixel format:
  Loops through an internal prioritized list of pixel format requirements
  and selects the first valid pixelformat found.
*/
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

- (void)setPixelFormat:(SCOpenGLPixelFormat *)pixelFormat
{
  NSLog(@"SCOpenGLView.setPixelFormat");

  [_pixelformat release];
  _pixelformat = [pixelFormat retain];
}

- (SCOpenGLPixelFormat *)pixelFormat
{
  NSLog(@"SCOpenGLView.pixelFormat");

  return _pixelformat;
}


/*!
  Used by subclassers to initialize OpenGL state. This function is called
  once after an OpenGL context is created and the drawable is attached.
  
  This function is called from within NSOpenGLContext.
*/
- (void)prepareOpenGL
{
  NSLog(@"SCOpenGLView.prepareOpenGL");

}

/*!
  Releases the NSOpenGLContext associated with the receiver. If
  necessary, this method calls clearDrawable on the context before
  releasing it.
*/
- (void)clearGLContext
{
  NSLog(@"SCOpenGLView.clearGLContext");

  if (_openGLContext) {
    if ([_openGLContext view] == self) [_openGLContext clearDrawable];
    [_openGLContext release];
    _openGLContext = nil;
  }
}

/*!
  Returns the NSOpenGLContext associated with the receiver. If the
  receiver has no associated context, a new NSOpenGLContext is created
  and returned. The new NSOpenGLContext is initialized with the
  receiver's pixelFormat.
*/
// FIXME: really do this? If pixelFormat is nil, create one using +defaultPixelFormat before creating context. Should we in case store the pixelformat?
- (NSOpenGLContext *)openGLContext
{
  if (!_openGLContext) {
    NSLog(@"SCOpenGLView.openGLContext: Creating new context");
    
    SCOpenGLPixelFormat * format = [self pixelFormat];
    if (!format) format = [SCOpenGLView defaultPixelFormat];
    _openGLContext = 
      [[NSOpenGLContext alloc] initWithFormat:[format pixelFormat]
                               shareContext:nil];
  }
  return _openGLContext;
}


/*!
  Sets the NSOpenGLContext used by the receiver to allow sharing the
  same context on a per view basis. Replaces the existing context if
  one was already created. You must call setView: on the context to
  sync the context with the view.
*/
- (void)setOpenGLContext:(NSOpenGLContext *)context
{
  NSLog(@"SCOpenGLView.setOpenGLContext");

  [self clearGLContext];
  _openGLContext = [context retain];
}

/*!
  Called if the visible rectangle or bounds of the receiver change
  (for scrolling or resize). The default implementation does
  nothing. Override this method if you need to adjust the viewport and
  display frustum.

  reshape is called when:
  - after init
  - window size changes (i.e. after an NSViewFrameDidChangeNotification)

  FIXME: What is really the difference between reshape and update?
  FIXME: Should we make sure that we have a valid context before calling reshape?
  FIXME: Should we call reshape after creating a context (i.e. after prepareOpenGL) ?
*/
- (void)reshape
{
  NSLog(@"SCOpenGLView.reshape");

}

/*!
  Called if the view's context needs to be updated because the window
  moves, or if the view moves or is resized. This method simply calls
  NSOpenGLContext's update. Override this method if you need to add
  locks for multithreaded access to multiple contexts.

  update is called whenever the view changes size or location
*/
- (void)update
{
  NSLog(@"SCOpenGLView.update");

  if ([_openGLContext view] == self) [_openGLContext update];
}

// NSCoding compliance

- (void)encodeWithCoder:(NSCoder *)coder 
{
  NSLog(@"SCOpenGLView.encodeWithCoder:");

  [super encodeWithCoder:coder];
  if (![coder allowsKeyedCoding]) {
    [coder encodeObject:_pixelformat];
  } else {
    NSLog(@"  allowsKeyedCoding");
    [coder encodeObject:_pixelformat forKey:@"SC_pixelformat"];
  }
}

- (id)initWithCoder:(NSCoder *)coder 
{
  NSLog(@"SCOpenGLView.initWithCoder:");

  if (self = [super initWithCoder:coder]) {
    if (![coder allowsKeyedCoding]) {
      _pixelformat = [[coder decodeObject] retain];
    } else {
      NSLog(@"  allowsKeyedCoding");
      _pixelformat = [[coder decodeObjectForKey:@"SC_pixelformat"] retain];
    }

    // FIXME: Move to a common initializer? (kintel 20040404) 
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                          selector:@selector(_surfaceNeedsUpdate:) 
                                          name:NSViewGlobalFrameDidChangeNotification 
                                          object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                          selector:@selector(_reshapeNeeded:) 
                                          name:NSViewFrameDidChangeNotification 
                                          object:self];
    //FIXME: Update? (kintel 20040404)
    [self reshape];
  }
  return self;
}

// Overridden methods from parent

- (BOOL)isOpaque
{
  NSLog(@"SCOpenGLView.isOpaque");

  return YES;
}

- (void)lockFocus
{
  NSLog(@"SCOpenGLView.lockFocus");

  // get context. will create if we don't have one yet
  NSOpenGLContext * context = [self openGLContext];
  
  // make sure we are ready to draw
  [super lockFocus];
  
  // when we are about to draw, make sure we are linked to the view
  if ([context view] != self) [context setView:self];
  
  // make us the current OpenGL context
  [context makeCurrentContext];
}

@end

// ----------------------- InternalAPI -------------------------

@implementation SCOpenGLView(InternalAPI)

- (void)_surfaceNeedsUpdate:(NSNotification *)notification
{
  NSLog(@"SCOpenGLView._surfaceNeedsUpdate");

  [self update];
  //FIXME: reshape? (kintel 20040404)
}

- (void)_reshapeNeeded:(NSNotification *)notification
{
  NSLog(@"SCOpenGLView._reshapeNeeded:");

  [self reshape];
}

@end
  
