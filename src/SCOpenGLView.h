#import <AppKit/NSView.h>

@class NSOpenGLContext;
@class SCOpenGLPixelFormat;

@interface SCOpenGLView : NSView
{
 @private
  NSOpenGLContext * _openGLContext;
  SCOpenGLPixelFormat * _pixelformat;
}

- (id)initWithFrame:(NSRect)rect;
- (id)initWithFrame:(NSRect)frameRect pixelFormat:(SCOpenGLPixelFormat *)format;
+ (SCOpenGLPixelFormat *)defaultPixelFormat;
- (void)setPixelFormat:(SCOpenGLPixelFormat *)pixelFormat;
- (SCOpenGLPixelFormat *)pixelFormat;

- (void)prepareOpenGL;
- (void)clearGLContext;
- (NSOpenGLContext *)openGLContext;
- (void)setOpenGLContext:(NSOpenGLContext *)context;

- (void)reshape;
- (void)update;

@end
