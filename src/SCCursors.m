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

@implementation NSCursor (SCCursors)

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
      if (rotateCursor) NSLog(@"  rotateCursor created.");
      else NSLog(@"  creation of rotateCursor failed.");
    }
  }
  return rotateCursor;
}

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
      if (zoomCursor) NSLog(@"  zoomCursor created.");
      else NSLog(@"  creation of zoomCursor failed.");
    }
  }
  return zoomCursor;
}

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
      if (panCursor) NSLog(@"  panCursor created.");
      else NSLog(@"  creation of panCursor failed.");
    }
  }
  return panCursor;
}

@end
