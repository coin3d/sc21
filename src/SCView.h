#import <Cocoa/Cocoa.h>
#import <OpenGL/gl.h>

#import <Inventor/events/SoKeyboardEvent.h>
#import <Inventor/events/SoMouseButtonEvent.h>
#import <Inventor/events/SoEvent.h>

@class SCController;

@interface SCView : NSOpenGLView <NSCoding>
{
  IBOutlet SCController * controller; /*" handles the actual Coin interaction."*/
  int _colorbits; /*" specifies the color depth. "*/
  int _depthbits;  /*" specifies the z buffer resolution. "*/
}

/*" Actions "*/
- (IBAction) debugInfo:(id)sender;

/*" Initializing an SCView "*/
- (id) initWithFrame:(NSRect)rect;
- (void) awakeFromNib;

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
- (void) scrollWheel:(NSEvent *) event;
- (void) keyDown:(NSEvent *) event;
- (BOOL)becomeFirstResponder;
- (BOOL)acceptsFirstResponder;

/*" Information and error message display "*/
- (void) displayInfo: (NSString *)msg;
- (void) displayError: (NSString *)msg;
- (void) displayErrorAndExit: (NSString *)msg;

/*" Convenience methods and shortcuts "*/
- (void) addMenuEntry:(NSString *) title target:(id) target action:(SEL) selector;
- (NSSize) size;
- (float) width;
- (float) height;
- (float) aspectRatio;
- (NSPoint) normalizePoint:(NSPoint)p;

/*" NSCoding conformance "*/
- (void) encodeWithCoder:(NSCoder *) coder;
- (id) initWithCoder:(NSCoder *) coder;

@end
