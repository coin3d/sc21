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

#import <Sc21/SCCursors.h>
#import <Sc21/SCView.h>
#import "SCUtil.h"

@implementation NSCursor (SCCursors)


/*" 
  Custom cursors used in Sc21. 

  These cursors can be used in exactly the same way as other
  NSCursors, so for instance to set a cursor indicating rotation, you
  would use !{[[NSCursor arrowCursor] set];}
"*/

/*" 
  Returns a cursor that looks like two arrows forming a circle, as is
  commonly used to indicate rotation.
"*/

// FIXME: factory methods should autorelease the instance they return.
// In our case here - who will ever release the cursor? kyrah 20040722.
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
