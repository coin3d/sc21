/* =============================================================== *
 |                                                                 |
 | This file is part of Sc21, a Cocoa user interface binding for   |
 | the Coin 3D visualization library.                              |
 |                                                                 |
 | Copyright (c) 2003-2004 Systems in Motion. All rights reserved. |
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

#import <Sc21/SCDebug.h>
#import <Sc21/SCOpenGLPixelFormat.h>
#import <Cocoa/Cocoa.h>
#import <OpenGL/CGLRenderers.h>
#import <Inventor/SoOutput.h>
#import <Inventor/SbTime.h>
#import <Inventor/actions/SoWriteAction.h>

NSString *SCRendererIdToString(int rendererID)
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

NSString * SCPixelFormatInfo(SCOpenGLPixelFormat * scpformat, 
                             NSOpenGLPixelFormat * nspformat)
{
  NSMutableString * info = [NSMutableString stringWithCapacity:1000];
  int scvals[10];
  long nsvals[10];
  BOOL scvalid;
  [info appendFormat:@"-------- pixelformatattribute: sc -> ns --------\n"];
  [info appendFormat:@"Virtual screens: -> %d\n", [nspformat numberOfVirtualScreens]];
  
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAAllRenderers forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAAllRenderers] == YES);
  [info appendFormat:@"NSOpenGLPFAAllRenderers: %s -> %s\n", scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFADoubleBuffer forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFADoubleBuffer] == YES);
  [info appendFormat:@"NSOpenGLPFADoubleBuffer: %s -> %s\n", scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAStereo forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAStereo] == YES);
  [info appendFormat:@"NSOpenGLPFAStereo: %s -> %s\n", scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAMinimumPolicy forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAMinimumPolicy] == YES);
  [info appendFormat:@"NSOpenGLPFAMinimumPolicy: %s -> %s\n", scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAMaximumPolicy forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAMaximumPolicy] == YES);
  [info appendFormat:@"NSOpenGLPFAMaximumPolicy: %s -> %s\n", scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAOffScreen forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAOffScreen] == YES);
  [info appendFormat:@"NSOpenGLPFAOffScreen: %s -> %s\n", scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAFullScreen forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAFullScreen] == YES);
  [info appendFormat:@"NSOpenGLPFAFullScreen: %s -> %s\n", scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFASingleRenderer forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFASingleRenderer] == YES);
  [info appendFormat:@"NSOpenGLPFASingleRenderer: %s -> %s\n", scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFANoRecovery forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFANoRecovery] == YES);
  [info appendFormat:@"NSOpenGLPFANoRecovery: %s -> %s\n", scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAAccelerated forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAAccelerated] == YES);
  [info appendFormat:@"NSOpenGLPFAAccelerated: %s -> %s\n", scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAClosestPolicy forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAClosestPolicy] == YES);
  [info appendFormat:@"NSOpenGLPFAClosestPolicy: %s -> %s\n", scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFARobust forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFARobust] == YES);
  [info appendFormat:@"NSOpenGLPFARobust: %s -> %s\n", scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFABackingStore forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFABackingStore] == YES);
  [info appendFormat:@"NSOpenGLPFABackingStore: %s -> %s\n", scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAWindow forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAWindow] == YES);
  [info appendFormat:@"NSOpenGLPFAWindow: %s -> %s\n", scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAMultiScreen forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAMultiScreen] == YES);
  [info appendFormat:@"NSOpenGLPFAMultiScreen: %s -> %s\n", scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFACompliant forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFACompliant] == YES);
  [info appendFormat:@"NSOpenGLPFACompliant: %s -> %s\n", scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAPixelBuffer forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAPixelBuffer] == YES);
  [info appendFormat:@"NSOpenGLPFAPixelBuffer: %s -> %s\n", scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAMPSafe forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAMPSafe] == YES);
  [info appendFormat:@"NSOpenGLPFAMPSafe: %s -> %s\n", scvalid?(scvals[0]?"YES":"NO"):"N/A", nsvals[0]?"YES":"NO"];

  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAAuxBuffers forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAAuxBuffers] == YES);
  [info appendFormat:@"NSOpenGLPFAAuxBuffers: %d -> %d\n", scvalid?scvals[0]:-1, nsvals[0]];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAColorSize forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAColorSize] == YES);
  [info appendFormat:@"NSOpenGLPFAColorSize: %d -> %d\n", scvalid?scvals[0]:-1, nsvals[0]];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAAlphaSize forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAAlphaSize] == YES);
  [info appendFormat:@"NSOpenGLPFAAlphaSize: %d -> %d\n", scvalid?scvals[0]:-1, nsvals[0]];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFADepthSize forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFADepthSize] == YES);
  [info appendFormat:@"NSOpenGLPFADepthSize: %d -> %d\n", scvalid?scvals[0]:-1, nsvals[0]];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAStencilSize forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAStencilSize] == YES);
  [info appendFormat:@"NSOpenGLPFAStencilSize: %d -> %d\n", scvalid?scvals[0]:-1, nsvals[0]];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAAccumSize forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAAccumSize] == YES);
  [info appendFormat:@"NSOpenGLPFAAccumSize: %d -> %d\n", scvalid?scvals[0]:-1, nsvals[0]];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAScreenMask forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAScreenMask] == YES);
  [info appendFormat:@"NSOpenGLPFAScreenMask: %d -> %d\n", scvalid?scvals[0]:-1, nsvals[0]];

  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAVirtualScreenCount forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAVirtualScreenCount] == YES);
  [info appendFormat:@"NSOpenGLPFAVirtualScreenCount: %d -> %d\n", scvalid?scvals[0]:-1, nsvals[0]];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFASampleBuffers forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFASampleBuffers] == YES);
  [info appendFormat:@"NSOpenGLPFASampleBuffers: %d -> %d\n", scvalid?scvals[0]:-1, nsvals[0]];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFASamples forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFASamples] == YES);
  [info appendFormat:@"NSOpenGLPFASamples: %d -> %d\n", scvalid?scvals[0]:-1, nsvals[0]];
  [nspformat getValues:nsvals forAttribute:NSOpenGLPFAAuxDepthStencil forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFAAuxDepthStencil] == YES);
  [info appendFormat:@"NSOpenGLPFAAuxDepthStencil: %d -> %d\n", scvalid?scvals[0]:-1, nsvals[0]];

  [nspformat getValues:nsvals forAttribute:NSOpenGLPFARendererID forVirtualScreen:0];
  scvalid = ([scpformat getValue:scvals forAttribute:NSOpenGLPFARendererID] == YES);
  NSString *screnderer = scvalid?SCRendererIdToString(scvals[0]):@"N/A";
  NSString *nsrenderer = SCRendererIdToString(nsvals[0]);
  [info appendFormat:@"NSOpenGLPFARendererID: %@ -> %@\n", screnderer, nsrenderer];

  [info appendFormat:@"-----------------------------\n"];

  return info;
}

NSString * SCOpenGLInfo(void)
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
  Writes the given scenegraph to a file. The filename will be
  XXX-dump.iv, where XXX is a number calculated based on the
  current time. The file will be stored in the current working
  directory. Returns !{NO} if there was an error writing the file,
  !{YES} otherwise.
  "*/

BOOL SCDumpSceneGraph(SoNode * scenegraph)
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
