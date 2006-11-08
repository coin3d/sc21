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

#import "SCRotateMode.h"
#import "SCCursors.h"
#import "SCCamera.h"
#import "SCUtil.h"
#import "SCMouseLog.h"

#include <Inventor/SbLinear.h>
#include <Inventor/projectors/SbSphereSheetProjector.h>

@implementation SCRotateMode

- (void)dealloc
{
  SC21_LOG_METHOD;
  delete _projector;
  [super dealloc];
}

- (void)activate:(NSEvent *)event point:(NSPoint *)point camera:(SCCamera *)camera
{
  SC21_DEBUG(@"SCRotateMode.activate:point: (%.2f,%.2f)", point->x, point->y);

  [super activate];
  if (!_projector) {
    SbViewVolume volume;
    volume.ortho(-1, 1, -1, 1, -1, 1);

    //FIXME: How does the sphere radius affect rotation?
    // (kintel 20040412)
    _projector = 
      new SbSphereSheetProjector(SbSphere(SbVec3f(0.0f, 0.0f ,0.0f), 0.8f));
    _projector->setViewVolume(volume);
  }

  _projector->project(SbVec2f(point->x, point->y));
}

- (id)valueForEvent:(NSEvent *)event
{
  NSPoint * p = [[SCMouseLog defaultMouseLog] point:0];
  return [NSValue valueWithPoint:*p];
}

- (BOOL)modifyCamera:(SCCamera *)camera withValue:(id)value
{
  NSPoint p = [(NSValue *)value pointValue];
  SbRotation r;
  _projector->projectAndGetRotation(SbVec2f(p.x, p.y), r);
  r.invert();
  [camera reorient:r];
  return YES;
}


- (NSCursor *)cursor
{
  SC21_LOG_METHOD;
  return [NSCursor rotateCursor];
}

@end
