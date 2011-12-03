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
 
#import "SCOpenGLViewInspector.h"
#import <Sc21/SCOpenGLView.h>
#import <Sc21/SCOpenGLPixelFormat.h>
#import "SCUtil.h"
#import "SCView.h"

@implementation SCOpenGLViewInspector

- (NSString *)viewNibName {
	return @"SCOpenGLViewInspector";
}

- (void)ok:(id)sender
{
  SC21_DEBUG(@"SCOpenGLViewInspector.ok:");
  SCOpenGLView *scview = [[self inspectedObjects] lastObject];
  SCOpenGLPixelFormat *pixelformat = [scview pixelFormat];
  //FIXME: only set later if values != default?
  if (!pixelformat) {
    pixelformat = [[SCOpenGLPixelFormat alloc] init];
    [scview setPixelFormat:pixelformat];
  }
  
  //FIXME: Reconsider this
  [pixelformat setAttribute:NSOpenGLPFADoubleBuffer];

  // Undo support
//  [self beginUndoGrouping];
  //[self noteAttributesWillChangeForObject:scview];
  
  // Renderer handling
  if ([renderer selectedRow] == 1)
    [pixelformat setAttribute:NSOpenGLPFAAccelerated];
  else
    [pixelformat removeAttribute:NSOpenGLPFAAccelerated];

  // Color and alpha handling
  int colorsize = -1;
  int alphasize = -1;
  switch ([coloralpha indexOfSelectedItem]) {
  case 1:
    colorsize = 15;
    alphasize = 0;
  break;
  case 2:
    colorsize = 15;
    alphasize = 1;
    break;
  case 3:
    colorsize = 15;
    alphasize = 8;
    break;
  case 4:
    colorsize = 24;
    alphasize = 0;
    break;
  case 5:
    colorsize = 24;
    alphasize = 8;
    break;
  }
  if (colorsize >= 0)
    [pixelformat setAttribute:NSOpenGLPFAColorSize toValue:colorsize]; 
  else
    [pixelformat removeAttribute:NSOpenGLPFAColorSize];

  if (alphasize >= 0)
    [pixelformat setAttribute:NSOpenGLPFAAlphaSize toValue:alphasize];
  else
    [pixelformat removeAttribute:NSOpenGLPFAAlphaSize];

  // Depth handling
  int depthsize = -1;
  switch ([depth indexOfSelectedItem]) {
  case 0:
    depthsize = 0;
    break;
  case 1:
    depthsize = 8; //FIXME: What is the real min? (kintel 20040402)
    break;
  case 2:
    depthsize = 16;
    break;
  case 3:
    depthsize = 24;
    break;
  case 4:
    depthsize = 32;
    break;
  case 5:
    depthsize = 64; //FIXME: What is the real max? (kintel 20040402)
    break;
  }
  if (depthsize >= 0) 
    [pixelformat setAttribute:NSOpenGLPFADepthSize toValue:depthsize];
  else
    [pixelformat removeAttribute:NSOpenGLPFADepthSize];
      
  // Stencil handling
  int stencilsize = -1;
  switch ([stencil indexOfSelectedItem]) {
  case 0:
    stencilsize = 0;
    break;
  case 1:
    stencilsize = 1; //FIXME: What is the real min? (kintel 20040402)
    break;
  case 2:
    stencilsize = 8;
    break;
  case 3:
    stencilsize = 16;
    break;
  case 4:
    stencilsize = 32; //FIXME: What is the real max? (kintel 20040402)
    break;
  }
  if (stencilsize >= 0) 
    [pixelformat setAttribute:NSOpenGLPFAStencilSize toValue:stencilsize];
  else
    [pixelformat removeAttribute:NSOpenGLPFAStencilSize];

  // Accumulation handling
  int accumsize = -1;
  switch ([accum indexOfSelectedItem]) {
  case 0:
    accumsize = 0;
    break;
  case 1:
    accumsize = 24; // 888 RGB
    break;
  case 2:
    accumsize = 32; // 8888 ARGB
    break;
  case 3:
    accumsize = 48; // 16x3 RGB
    break;
  case 4:
    accumsize = 64; // 16x4 ARGB
    break;
  }
  if (accumsize >= 0) 
    [pixelformat setAttribute:NSOpenGLPFAAccumSize toValue:accumsize];
  else
    [pixelformat removeAttribute:NSOpenGLPFAAccumSize];
}

- (void)refresh
{
  SC21_DEBUG(@"SCOpenGLViewInspector.refresh");
  
  SCOpenGLView *scview = [[self inspectedObjects] lastObject];
  SCOpenGLPixelFormat *pixelformat = [scview pixelFormat];
  if (pixelformat) {
    // Renderer handling
    int accel;
    [pixelformat getValue:&accel forAttribute:NSOpenGLPFAAccelerated];
    [renderer selectCellAtRow:accel column:0];

    // Color and alpha handling
    int colorsize = -1;
    int alphasize = -1;
    [pixelformat getValue:&colorsize forAttribute:NSOpenGLPFAColorSize];
    [pixelformat getValue:&alphasize forAttribute:NSOpenGLPFAAlphaSize];

    int idx = 0;
    switch (colorsize) {
    case 15:
      if (alphasize == 0) idx = 1;
      else if (alphasize == 1) idx = 2;
      else idx = 3;
      break;
    case 24:
      if (alphasize == 0) idx = 4;
      else idx = 5;
      break;
    }
    [coloralpha selectItemAtIndex:idx];

    // Depth handling
    int depthsize = -1;
    [pixelformat getValue:&depthsize forAttribute:NSOpenGLPFADepthSize];
    idx = 0;
    switch (depthsize) {
    case 8:
      idx = 1; 
      break;
    case 16:
      idx = 2; 
      break;
    case 24:
      idx = 3; 
      break;
    case 32:
      idx = 4; 
      break;
    case 64:
      idx = 5; 
      break;
    }
    [depth selectItemAtIndex:idx];

    // Stencil handling
    int stencilsize = -1;
    [pixelformat getValue:&stencilsize forAttribute:NSOpenGLPFAStencilSize];
    idx = 0;
    switch (stencilsize) {
    case 1:
      idx = 1;
      break;
    case 8:
      idx = 2;
      break;
    case 16:
      idx = 3;
      break;
    case 32:
      idx = 4;
      break;
    }
    [stencil selectItemAtIndex:idx];

    // Accum handling
    int accumsize = -1;
    [pixelformat getValue:&accumsize forAttribute:NSOpenGLPFAAccumSize];
    idx = 0;
    switch (accumsize) {
    case 24:
      idx = 1;
      break;
    case 32:
      idx = 2;
      break;
    case 48:
      idx = 3;
      break;
    case 64:
      idx = 4;
      break;
    }
    [accum selectItemAtIndex:idx];
  }
  //FIXME: else default values? (kintel 20040405)

  [super refresh];
}

@end
