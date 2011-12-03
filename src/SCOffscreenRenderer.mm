/**************************************************************************\
 * Copyright (c) Kongsberg Oil & Gas Technologies AS
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the copyright holder nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
\**************************************************************************/


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
