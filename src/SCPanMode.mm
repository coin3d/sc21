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

#import "SCPanMode.h"
#import "SCCursors.h"
#import "SCCamera.h"
#import "SCUtil.h"
#import "SCMouseLog.h"

#include <Inventor/SbLinear.h>
#include <Inventor/nodes/SoCamera.h>

@implementation SCPanMode

- (void)activate:(NSEvent *)event point:(NSPoint *)point camera:(SCCamera *)camera
{
  SC21_DEBUG(@"SCPanMode.activate:point: (%.2f,%.2f)", point->x, point->y);
  [super activate];
}

- (id)valueForEvent:(NSEvent *)event
{
  NSPoint *p = [[SCMouseLog defaultMouseLog] point:0];
  return [NSValue valueWithPoint:*p];
}

- (BOOL)modifyCamera:(SCCamera *)camera withValue:(id)value
{
  SbViewVolume vv;
  SbPlane panplane;
  SbVec3f curplanepoint, prevplanepoint;
  SbLine line;
  SoCamera *cam;
  NSPoint *lastp, *currp;
  
  SCMouseLog * mouselog = [SCMouseLog defaultMouseLog];
  lastp = [mouselog point:1];
  currp = [mouselog point:0];
  if ((cam = [camera soCamera]) == nil) return NO;
    // Find projection points for the last and current mouse coordinates.
    //FIXME: Support diff. viewportmappings? (kintel 20040412)
    //     SbViewVolume vv = cam->getViewVolume([view aspectRatio]);
  vv = cam->getViewVolume();
  panplane = vv.getPlane(cam->focalDistance.getValue());
  vv.projectPointToLine(SbVec2f(currp->x, currp->y), line);
  panplane.intersect(line, curplanepoint);
  vv.projectPointToLine(SbVec2f(lastp->x, lastp->y), line);
  panplane.intersect(line, prevplanepoint);
    
  // Reposition camera according to the vector difference between the
  // projected points.
  cam->position = cam->position.getValue() - (curplanepoint - prevplanepoint);    
  return YES;
}


- (NSCursor *)cursor
{
  SC21_LOG_METHOD;
  return [NSCursor panCursor];
}

@end
