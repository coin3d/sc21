@class NSString;
@class NSOpenGLPixelFormat;
@class SCOpenGLPixelFormat;

NSString * SCRendererIdToString(int rendererID);
NSString * SCPixelFormatInfo(SCOpenGLPixelFormat * scpformat, 
                             NSOpenGLPixelFormat * nspformat);
NSString * SCOpenGLInfo(void);
