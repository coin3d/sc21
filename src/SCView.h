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
- (NSMenuItem *) addMenuEntry:(NSString *)title target:(id)target action:(SEL)selector;
- (float) aspectRatio;
- (NSPoint) normalizePoint:(NSPoint)point;

/*" NSCoding conformance "*/
- (void) encodeWithCoder:(NSCoder *)coder;
- (id) initWithCoder:(NSCoder *)coder;

@end

/*" Notifications posted by SCView. "*/

extern NSString * SCCouldNotCreateValidPixelFormatNotification;

