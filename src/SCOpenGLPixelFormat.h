#import <AppKit/NSOpenGL.h>

@interface SCOpenGLPixelFormat : NSOpenGLPixelFormat
{
  NSMutableDictionary *_attrDict;
}

- (void)setAttribute:(NSOpenGLPixelFormatAttribute)attr;
- (void)setAttribute:(NSOpenGLPixelFormatAttribute)attr toValue:(int)val;
- (void)removeAttribute:(NSOpenGLPixelFormatAttribute)attr;
- (int)getAttribute:(NSOpenGLPixelFormatAttribute)attr;
- (id)reinit;

@end
