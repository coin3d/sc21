#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import "SCOpenGLView.h"

@interface SCOpenGLView(InternalAPI)
- (void) _surfaceNeedsUpdate:(NSNotification *)notification;
- (void) _reshapeNeeded:(NSNotification *)notification;
@end

@implementation SCOpenGLView

/*!  
  Designated initializer.

  Initializes a newly allocated NSOpenGLView with frameRect as its
  frame rectangle and format as its pixel format.
  
  FIXME: Support both SC- and NSOpenGLPixelFormat?
*/
- (id)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)format
{
  NSLog(@"SCOpenGLView.initWithFrame:pixelFormat");

  self = [super initWithFrame:frameRect];
  if (self) {
    _pixelFormat = [format retain];
    //FIXME: What does this really do?
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(_surfaceNeedsUpdate:) 
                                                 name:NSViewGlobalFrameDidChangeNotification 
                                               object:self];

    [[NSNotificationCenter defaultCenter] addObserver:self 
                                          selector:@selector(_reshapeNeeded:) 
                                                 name:NSViewFrameDidChangeNotification 
                                               object:self];
    //FIXME: update?
    [self reshape];
  }
  return self;
}

// FIXME: Remove and let default pixel format be nil?
- (id)initWithFrame:(NSRect)frameRect
{  
  NSLog(@"SCOpenGLView.initWithFrame:");

  return [self initWithFrame: frameRect
                 pixelFormat: [self createPixelFormat]];
}

- (void)dealloc
{
  NSLog(@"SCOpenGLView.dealloc");

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [self clearGLContext];
  [_pixelFormat release];
  [super dealloc];
}


// Will create and return a default pixel format:
// 2) Loop through an internal prioritized list of pixel format requirements.
//   => Select the first valid pixelformat found.
- (NSOpenGLPixelFormat *)createPixelFormat
{
  NSLog(@"SCOpenGLView.createPixelFormat");

  NSOpenGLPixelFormat *pixelFormat = nil;
  NSOpenGLPixelFormatAttribute *attrs = nil;
  int numattrs = 0;
  if (!pixelFormat) {
    attrs = malloc(16*sizeof(NSOpenGLPixelFormatAttribute));
    int i = 0;
    attrs[i++] = NSOpenGLPFADoubleBuffer;
    attrs[i++] = NSOpenGLPFAAccelerated;
    attrs[i++] = NSOpenGLPFAAccumSize;
    attrs[i++] = (NSOpenGLPixelFormatAttribute)32;
    attrs[i++] = NSOpenGLPFAColorSize;
    attrs[i++] = (NSOpenGLPixelFormatAttribute)24;
    attrs[i++] = NSOpenGLPFADepthSize;
    attrs[i++] = (NSOpenGLPixelFormatAttribute)8;
    attrs[i++] = NSOpenGLPFAScreenMask;
    attrs[i++] = (NSOpenGLPixelFormatAttribute)
      CGDisplayIDToOpenGLDisplayMask(kCGDirectMainDisplay);
    attrs[i] = (NSOpenGLPixelFormatAttribute)0;
    pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
    [pixelFormat autorelease];
  }

  if (attrs) free(attrs);
  return pixelFormat;
}

- (void)setPixelFormat:(NSOpenGLPixelFormat *)pixelFormat
{
  NSLog(@"SCOpenGLView.setPixelFormat");

  [_pixelFormat release];
  _pixelFormat = [pixelFormat retain];
}

- (NSOpenGLPixelFormat *)pixelFormat
{
  NSLog(@"SCOpenGLView.pixelFormat");

  return _pixelFormat;
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
// FIXME: really do this? If pixelFormat is nil, create one using createPixelFormat before creating context.
- (NSOpenGLContext *)openGLContext
{
  if (!_openGLContext) {
    NSLog(@"SCOpenGLView.openGLContext: Creating new context");
  
    NSOpenGLPixelFormat *format = [self pixelFormat];
    if (!format) format = [self createPixelFormat];
    _openGLContext = [[NSOpenGLContext alloc] initWithFormat:format
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
}

- (id)initWithCoder:(NSCoder *)coder 
{
  NSLog(@"SCOpenGLView.initWithCoder:");

  if (self = [super initWithCoder:coder]) {
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(_surfaceNeedsUpdate:) 
                                                 name:NSViewGlobalFrameDidChangeNotification 
                                               object:self];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                          selector:@selector(_reshapeNeeded:) 
                                                 name:NSViewFrameDidChangeNotification 
                                               object:self];
    //FIXME: Update
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
  //FIXME: reshape?
}

- (void)_reshapeNeeded:(NSNotification *)notification
{
  NSLog(@"SCOpenGLView._reshapeNeeded:");

  [self reshape];
}

@end
  