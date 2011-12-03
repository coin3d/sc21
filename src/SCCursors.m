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

#import <Sc21/SCCursors.h>
#import <Sc21/SCView.h>
#import "SCUtil.h"

@implementation NSCursor (SCCursors)

/*" 
  Custom cursors used in Sc21. 

  These cursors can be used in exactly the same way as other
  NSCursors. Refer to the NSCursors documentation for information on
  cursor handling in Cocoa.
"*/


/*" 
  Returns a cursor that looks like two arrows forming a circle, as is
  commonly used to indicate rotation.
"*/

+ (NSCursor *)rotateCursor
{
  static NSCursor * rotateCursor = nil;
  if (!rotateCursor) {
    NSBundle * frameworkBundle = [NSBundle bundleForClass:[SCView class]];
    if (frameworkBundle) {
      NSString * imagePath = [frameworkBundle pathForResource:@"curs_rotate"
                                              ofType:@"tiff"];
      NSImage * img = [[NSImage alloc] initWithContentsOfFile:imagePath];
      NSPoint hotspot = {8, 8};
      rotateCursor = [[NSCursor alloc] initWithImage:img hotSpot:hotspot];
      if (rotateCursor) SC21_DEBUG(@"  rotateCursor created.");
      else SC21_DEBUG(@"  creation of rotateCursor failed.");
    }
  }
  return rotateCursor;
}


/*" 
  Returns a cursor that looks like an arrow with two arrowheads, one
  being slightly larger than the other, as is commonly used to
  indicate zooming.
"*/

+ (NSCursor *)zoomCursor
{
  static NSCursor * zoomCursor = nil;
  if (!zoomCursor) {
    NSBundle * frameworkBundle = [NSBundle bundleForClass:[SCView class]];
    if (frameworkBundle) {
      NSString * imagePath = [frameworkBundle pathForResource:@"curs_zoom"
                                              ofType:@"tiff"];
      NSImage * img = [[NSImage alloc] initWithContentsOfFile:imagePath];
      NSPoint hotspot = {8, 8};
      zoomCursor = [[NSCursor alloc] initWithImage:img hotSpot:hotspot];
      if (zoomCursor) SC21_DEBUG(@"  zoomCursor created.");
      else SC21_DEBUG(@"  creation of zoomCursor failed.");
    }
  }
  return zoomCursor;
}


/*"  
  Returns a cursor that consists of four arrows forming a cross,
  pointing outwards, as is commonly used to indicate movement.
"*/

+ (NSCursor *)panCursor
{
  static NSCursor * panCursor = nil;
  if (!panCursor) {
    NSBundle * frameworkBundle = [NSBundle bundleForClass:[SCView class]];
    if (frameworkBundle) {
      NSString * imagePath = [frameworkBundle pathForResource:@"curs_pan"
                                              ofType:@"tiff"];
      NSImage * img = [[NSImage alloc] initWithContentsOfFile:imagePath];
      NSPoint hotspot = {8, 8};
      panCursor = [[NSCursor alloc] initWithImage:img hotSpot:hotspot];
      if (panCursor) SC21_DEBUG(@"  panCursor created.");
      else SC21_DEBUG(@"  creation of panCursor failed.");
    }
  }
  return panCursor;
}

@end
