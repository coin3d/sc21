#import <AppKit/NSView.h>

@class NSOpenGLContext, SCOpenGLPixelFormat;

@interface SCOpenGLView : NSView
{
 @private
  NSOpenGLContext * _openGLContext;
  SCOpenGLPixelFormat * _pixelFormat;
}

- (id)initWithFrame:(NSRect)rect;
- (id)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)format;

//FIXME: Add or rename to +defaultPixelFormat?
- (NSOpenGLPixelFormat *)createPixelFormat;
- (void)setPixelFormat:(NSOpenGLPixelFormat*)pixelFormat;
- (NSOpenGLPixelFormat*)pixelFormat;

- (void)prepareOpenGL;
- (void)clearGLContext;
- (NSOpenGLContext *)openGLContext;
- (void)setOpenGLContext:(NSOpenGLContext *)context;

- (void)reshape;
- (void)update;

@end
