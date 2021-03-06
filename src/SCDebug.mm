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

#import <Sc21/SCDebug.h>
#import <Sc21/SCOpenGLPixelFormat.h>

#import <OpenGL/CGLRenderers.h>

#import <Inventor/SoOutput.h>
#import <Inventor/SbTime.h>
#import <Inventor/actions/SoWriteAction.h>


@interface SCDebug (InternalAPI)
+ (NSString *)infoForSCOpenGLPixelFormat:(SCOpenGLPixelFormat *)scpformat 
                     NSOpenGLPixelFormat:(NSOpenGLPixelFormat *)nspformat;
@end


@implementation SCDebug

/*" 
  Collection of useful debugging methods. 
"*/


/*" 
  Returns a human-readable description of the renderer rendererID. 
"*/

+ (NSString *)descriptionForRendererID:(int)rendererID
{
  NSString *renderer = nil;
  switch(rendererID) {
  case kCGLRendererGenericID:
    renderer = @"Generic";
    break;
  case kCGLRendererAppleSWID:
    renderer = @"Apple SW";
    break;
  case kCGLRendererATIRage128ID:
    renderer = @"ATI Rage 128";
    break;
  case kCGLRendererATIRadeonID:
    renderer = @"ATI Radeon";
    break;
  case kCGLRendererATIRageProID:
    renderer = @"ATI Rage Pro";
    break;
  case kCGLRendererATIRadeon8500ID:
    renderer = @"ATI Radeon 8500";
    break;
  case kCGLRendererATIRadeon9700ID:
    renderer = @"ATI Radeon 9700";
    break;
  case kCGLRendererGeForce2MXID:
    renderer = @"GeForce2 MX";
    break;
  case kCGLRendererGeForce3ID:
    renderer = @"GeForce3";
    break;
  case kCGLRendererGeForceFXID:
    renderer = @"GeForce FX";
    break;
  case kCGLRendererMesa3DFXID:
    renderer = @"Mesa3D FX";
    break;
  default:
    renderer = [NSString stringWithFormat:@"%x", rendererID];
    break;
  }
  return renderer;
}


/*" Returns a string describing the OpenGL capabilities of the current 
    OpenGL context. 
 "*/

+ (NSString *)openGLInfo
{
  GLint depth;
  GLint stencil;
  GLint colors[4];
  GLint accum[4];
  GLint maxviewportdims[2];
  GLint maxtexsize, maxlights, maxplanes;

  GLboolean doublebuffered;
  GLboolean stereo;

  const GLubyte * vendor = glGetString(GL_VENDOR);
  const GLubyte * renderer = glGetString(GL_RENDERER);
  const GLubyte * version = glGetString(GL_VERSION);

  glGetIntegerv(GL_DEPTH_BITS, &depth);
  glGetIntegerv(GL_RED_BITS, &colors[0]);
  glGetIntegerv(GL_GREEN_BITS, &colors[1]);
  glGetIntegerv(GL_BLUE_BITS, &colors[2]);
  glGetIntegerv(GL_ALPHA_BITS, &colors[3]);
  glGetIntegerv(GL_STENCIL_BITS, &stencil);
  glGetIntegerv(GL_ACCUM_RED_BITS, &accum[0]);
  glGetIntegerv(GL_ACCUM_GREEN_BITS, &accum[1]);
  glGetIntegerv(GL_ACCUM_BLUE_BITS, &accum[2]);
  glGetIntegerv(GL_ACCUM_ALPHA_BITS, &accum[3]);
  glGetIntegerv(GL_MAX_VIEWPORT_DIMS, maxviewportdims);
  glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxtexsize);
  glGetIntegerv(GL_MAX_LIGHTS, &maxlights);
  glGetIntegerv(GL_MAX_CLIP_PLANES, &maxplanes);

  glGetBooleanv(GL_DOUBLEBUFFER, &doublebuffered);
  glGetBooleanv(GL_STEREO, &stereo);


  NSMutableString * info = [NSMutableString stringWithCapacity:1000];
  [info appendFormat:@"OpenGL version: %s\n", (const char *)version];
  [info appendFormat:@"Vendor: %s\n", (const char *)vendor];
  [info appendFormat:@"Renderer: %s\n", (const char *)renderer];
  [info appendFormat:@"Color depth (RGBA): %d, %d, %d, %d\n",
    colors[0], colors[1], colors[2], colors[3]];
  [info appendFormat:@"Accumulation buffer depth (RGBA): %d, %d, %d, %d\n",
    accum[0], accum[1], accum[2], accum[3]];
  [info appendFormat:@"Depth buffer: %d\n", depth];
  [info appendFormat:@"Stencil buffer: %d\n", stencil];
  [info appendFormat:@"Doublebuffering: %s\n", doublebuffered ? "on" : "off"];
  [info appendFormat:@"Stereo: %s\n", stereo ? "on" : "off"];
  [info appendFormat:@"Maximum viewport dimensions: <%d, %d>\n",
    maxviewportdims[0], maxviewportdims[1]];
  [info appendFormat:@"Maximum texture size: %d\n", maxtexsize];
  [info appendFormat:@"Maximum number of lights: %d\n", maxlights];
  [info appendFormat:@"Maximum number of clipping planes: %d\n", maxplanes];

  return info;
}


/*" 
  Writes the given scenegraph to a file. The file will be stored in
  the current working directory. The filename will be XXX-dump.iv,
  where XXX is a number calculated based on the current time. Returns
  !{NO} if there was an error writing the file, !{YES} otherwise. 
"*/

+ (BOOL) dumpSceneGraph:(SoNode *)scenegraph
{
  SoOutput out;
  SbString filename = SbTime::getTimeOfDay().format();
  filename += "-dump.iv";
  SbBool ok = out.openFile(filename.getString());
  if (ok) {
    SoWriteAction wa(&out);
    wa.apply(scenegraph);
    return YES;
  }
  return NO;
}

@end


@implementation SCDebug (InternalAPI)

+ (NSString *)infoForSCOpenGLPixelFormat:(SCOpenGLPixelFormat *)scpformat 
                     NSOpenGLPixelFormat:(NSOpenGLPixelFormat *)nspformat
{
  NSMutableString * info = [NSMutableString stringWithCapacity:1000];
  int scvals[10];
  GLint nsvals[10];
  BOOL scvalid;
  [info appendFormat:@"-------- pixelformatattribute: sc -> ns --------\n"];
  [info appendFormat:@"Virtual screens: -> %d\n", 
   [nspformat numberOfVirtualScreens]];
  
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAAllRenderers 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAAllRenderers] 
             == YES);
  [info appendFormat:@"NSOpenGLPFAAllRenderers: %s -> %s\n", 
   scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFADoubleBuffer 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFADoubleBuffer] 
             == YES);
  [info appendFormat:@"NSOpenGLPFADoubleBuffer: %s -> %s\n", 
   scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAStereo 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAStereo] == YES);
  [info appendFormat:@"NSOpenGLPFAStereo: %s -> %s\n", 
   scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAMinimumPolicy 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAMinimumPolicy] 
             == YES);
  [info appendFormat:@"NSOpenGLPFAMinimumPolicy: %s -> %s\n", 
   scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAMaximumPolicy 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAMaximumPolicy] 
             == YES);
  [info appendFormat:@"NSOpenGLPFAMaximumPolicy: %s -> %s\n", 
   scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAOffScreen 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAOffScreen] 
             == YES);
  [info appendFormat:@"NSOpenGLPFAOffScreen: %s -> %s\n", 
   scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAFullScreen 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAFullScreen] 
             == YES);
  [info appendFormat:@"NSOpenGLPFAFullScreen: %s -> %s\n", 
   scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFASingleRenderer 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFASingleRenderer] 
             == YES);
  [info appendFormat:@"NSOpenGLPFASingleRenderer: %s -> %s\n", 
   scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFANoRecovery 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFANoRecovery] 
             == YES);
  [info appendFormat:@"NSOpenGLPFANoRecovery: %s -> %s\n", 
   scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAAccelerated 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAAccelerated] 
             == YES);
  [info appendFormat:@"NSOpenGLPFAAccelerated: %s -> %s\n", 
   scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAClosestPolicy 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAClosestPolicy] 
             == YES);
  [info appendFormat:@"NSOpenGLPFAClosestPolicy: %s -> %s\n", 
   scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFARobust 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFARobust] 
             == YES);
  [info appendFormat:@"NSOpenGLPFARobust: %s -> %s\n", 
   scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFABackingStore 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFABackingStore] 
             == YES);
  [info appendFormat:@"NSOpenGLPFABackingStore: %s -> %s\n", 
   scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAWindow 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAWindow] 
             == YES);
  [info appendFormat:@"NSOpenGLPFAWindow: %s -> %s\n", 
   scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAMultiScreen 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAMultiScreen] 
             == YES);
  [info appendFormat:@"NSOpenGLPFAMultiScreen: %s -> %s\n", 
   scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFACompliant 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFACompliant] 
             == YES);
  [info appendFormat:@"NSOpenGLPFACompliant: %s -> %s\n", 
   scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAPixelBuffer 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAPixelBuffer] 
             == YES);
  [info appendFormat:@"NSOpenGLPFAPixelBuffer: %s -> %s\n", 
   scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAMPSafe 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAMPSafe] 
             == YES);
  [info appendFormat:@"NSOpenGLPFAMPSafe: %s -> %s\n", 
   scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAAuxBuffers 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAAuxBuffers] 
             == YES);
  [info appendFormat:@"NSOpenGLPFAAuxBuffers: %d -> %d\n", 
   scvalid?scvals[0]:-1, nsvals[0]];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAColorSize 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAColorSize] 
             == YES);
  [info appendFormat:@"NSOpenGLPFAColorSize: %d -> %d\n", 
   scvalid?scvals[0]:-1, nsvals[0]];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAAlphaSize 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAAlphaSize] 
             == YES);
  [info appendFormat:@"NSOpenGLPFAAlphaSize: %d -> %d\n", 
   scvalid?scvals[0]:-1, nsvals[0]];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFADepthSize 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFADepthSize] 
             == YES);
  [info appendFormat:@"NSOpenGLPFADepthSize: %d -> %d\n", 
   scvalid?scvals[0]:-1, nsvals[0]];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAStencilSize 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAStencilSize] 
             == YES);
  [info appendFormat:@"NSOpenGLPFAStencilSize: %d -> %d\n", 
   scvalid?scvals[0]:-1, nsvals[0]];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAAccumSize 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAAccumSize] 
             == YES);
  [info appendFormat:@"NSOpenGLPFAAccumSize: %d -> %d\n", 
   scvalid?scvals[0]:-1, nsvals[0]];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAScreenMask 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAScreenMask] 
             == YES);
  [info appendFormat:@"NSOpenGLPFAScreenMask: %d -> %d\n", 
   scvalid?scvals[0]:-1, nsvals[0]];
  
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAVirtualScreenCount 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals 
              forAttribute:NSOpenGLPFAVirtualScreenCount] == YES);
  [info appendFormat:@"NSOpenGLPFAVirtualScreenCount: %d -> %d\n", 
   scvalid?scvals[0]:-1, nsvals[0]];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFASampleBuffers 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFASampleBuffers] 
             == YES);
  [info appendFormat:@"NSOpenGLPFASampleBuffers: %d -> %d\n", 
   scvalid?scvals[0]:-1, nsvals[0]];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFASamples 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFASamples] 
             == YES);
  [info appendFormat:@"NSOpenGLPFASamples: %d -> %d\n", 
   scvalid?scvals[0]:-1, nsvals[0]];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAAuxDepthStencil 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAAuxDepthStencil]
             == YES);
  [info appendFormat:@"NSOpenGLPFAAuxDepthStencil: %d -> %d\n", 
   scvalid?scvals[0]:-1, nsvals[0]];
  
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFARendererID 
   forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFARendererID] 
             == YES);
  
  NSString *screnderer = scvalid ? 
    [SCDebug descriptionForRendererID:scvals[0]] : @"N/A";
  NSString *nsrenderer = [SCDebug descriptionForRendererID:nsvals[0]];
  
  [info appendFormat:@"NSOpenGLPFARendererID: %@ -> %@\n", screnderer, 
   nsrenderer];  
  [info appendFormat:@"-----------------------------\n"];
  
  return info;
}

@end
