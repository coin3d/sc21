#import <AppKit/NSOpenGL.h>

@interface SCOpenGLPixelFormat : NSObject <NSCoding>
{
  NSMutableDictionary * _attrdict;
  NSOpenGLPixelFormat * _nspixelformat;
}

- (void)setAttribute:(NSOpenGLPixelFormatAttribute)attr;
- (void)setAttribute:(NSOpenGLPixelFormatAttribute)attr toValue:(int)val;
- (void)removeAttribute:(NSOpenGLPixelFormatAttribute)attr;
- (BOOL)getValue:(int *)valptr forAttribute:(NSOpenGLPixelFormatAttribute)attr;
- (NSOpenGLPixelFormat *)pixelFormat;

@end
