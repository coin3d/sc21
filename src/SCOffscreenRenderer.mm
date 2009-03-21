/* =============================================================== *
|                                                                 |
| This file is part of Sc21, a Cocoa user interface binding for   |
| the Coin 3D visualization library.                              |
|                                                                 |
| Copyright (c) 2003-2006 Systems in Motion. All rights reserved. |
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


#import "SCOffscreenRenderer.h"

#import <OpenGL/OpenGL.h>
#import <OpenGL/CGLTypes.h>
#import <OpenGL/CGLContext.h>

#import <Inventor/C/glue/gl.h>
#import <Inventor/errors/SoDebugError.h>

struct ctx_data 
{
  CGLContextObj storedcontext;
  NSOpenGLContext *glcontext;
  NSOpenGLView *glview;
  NSWindow *window;
  NSOpenGLPixelFormat *pixelformat;
  unsigned int width, height;  
};

static struct ctx_data *
contextdata_init(unsigned int width, unsigned int height)
{
  struct ctx_data * ctx = (struct ctx_data *)malloc(sizeof(struct ctx_data));
  ctx->glcontext = NULL;
  ctx->glview = NULL;
  ctx->storedcontext = NULL;
  ctx->pixelformat = NULL;
  ctx->width = width;
  ctx->height = height;
  return ctx;
}

static void
contextdata_cleanup(struct ctx_data * ctx)
{
  [ctx->glview release];
  [ctx->window release];
  [ctx->glcontext release];
  [ctx->pixelformat release];
  free(ctx);
}

static SbBool
context_create_software(struct ctx_data * ctx)
{
  // FIXME: Should this be configurable && how? kyrah 20051102
  NSOpenGLPixelFormatAttribute attrib[] = {
    NSOpenGLPFAWindow,
    NSOpenGLPFAAlphaSize, (NSOpenGLPixelFormatAttribute)8, 
    NSOpenGLPFAColorSize, (NSOpenGLPixelFormatAttribute)24,
    NSOpenGLPFADoubleBuffer,
    NSOpenGLPFAAccelerated,
    NSOpenGLPFADepthSize, (NSOpenGLPixelFormatAttribute)16,
    NSOpenGLPFANoRecovery,  
    (NSOpenGLPixelFormatAttribute)nil
  };

  ctx->pixelformat = [(NSOpenGLPixelFormat*)[NSOpenGLPixelFormat alloc] 
                      initWithAttributes:attrib];
    
  if (!ctx->pixelformat) {
    SoDebugError::postWarning("context_create_software", 
                              "Couldn't get RGBA CGL pixelformat.");
    return FALSE;
  }
  
  // FIXME: Allow context sharing? kyrah 20051102.
  ctx->glcontext = [[NSOpenGLContext alloc] 
                    initWithFormat:ctx->pixelformat 
                    shareContext:nil];

  if (!ctx->glcontext) {
    SoDebugError::postWarning("context_create_software", 
                              "Couldn't create CGL context.");
    contextdata_cleanup(ctx);
    return FALSE;
  } 
  
  // prevent tearing artifacts by swapping buffers during vertical retrace
  GLint swapInt = 1;
  [ctx->glcontext setValues:&swapInt forParameter:NSOpenGLCPSwapInterval];
  
  GLint opaque = 0; // transparent background (set to 1 for opaque)
  [ctx->glcontext setValues:&opaque forParameter:NSOpenGLCPSurfaceOpacity];
  GLint surfaceOrder = 1;
  [ctx->glcontext setValues:&surfaceOrder forParameter:NSOpenGLCPSurfaceOrder];
  
  NSRect bounds = NSMakeRect(0, 0, ctx->width, ctx->height);
  ctx->glview = [[NSOpenGLView alloc] initWithFrame:bounds];      
  ctx->window = [[NSWindow alloc] initWithContentRect:bounds
                 styleMask:NSBorderlessWindowMask
                 backing:NSBackingStoreNonretained
                 defer:NO];
  [ctx->window setContentView:ctx->glview];
  [ctx->window setReleasedWhenClosed:NO];
  [ctx->glcontext setView:ctx->glview];
          
  if (!ctx->glview || ![ctx->glcontext view] || !ctx->window) {
    SoDebugError::postWarning("context_create_software", 
                              "Couldn't create CGL view and window.");
    return FALSE;
  }
  
  return TRUE;
}


static void *
context_create_offscreen(unsigned int width, unsigned int height)
{
  struct ctx_data * context;
    
  context = contextdata_init(width, height);
  if (!context) { return NULL; }
  
#if 0 // DEBUG
  SoDebugError::postInfo("context_create_offscreen", 
                            "Creating NSOpenGL offscreen context.");
#endif
  
  if (context_create_software(context)) { return context; } 

  contextdata_cleanup(context);
  return NULL;
}


static SbBool
context_make_current(void * ctx)
{
  struct ctx_data * context = (struct ctx_data *)ctx;
  
  if (context->glcontext) {
    context->storedcontext = CGLGetCurrentContext();
  }

  [context->glcontext makeCurrentContext];
  return TRUE;
}

static void
context_reinstate_previous(void * ctx)
{
  struct ctx_data * context = (struct ctx_data *)ctx;

  if (context->storedcontext ) {
    CGLSetCurrentContext(context->storedcontext);
  }
}

static void
context_destruct(void * ctx) 
{
  struct ctx_data * context = (struct ctx_data *)ctx;
  contextdata_cleanup(context);
}


@implementation SCOffscreenRenderer

+ (void)initialize
{
  static cc_glglue_offscreen_cb_functions cb =
    {
      context_create_offscreen,
      context_make_current,
      context_reinstate_previous,
      context_destruct
    };

  cc_glglue_context_set_offscreen_cb_functions(&cb);
}

@end
