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

#import <Sc21/SCCamera.h>
#import "SCFlyMode.h"
#import "SCCursors.h"
#import "SCUtil.h"
#import "SCMouseLog.h"

#include <Inventor/SbLinear.h>
#include <Inventor/projectors/SbSphereSheetProjector.h>

@implementation SCFlyMode

- (void)dealloc
{
  SC21_LOG_METHOD;
  [super dealloc];
}

- (float)throttle
{
  return self->throttle;
}

- (void)setThrottle:(float)newthrottle
{
  self->throttle = newthrottle;
}

- (float)speed
{
  return self->speed;
}

- (void)setSpeed:(float)newspeed
{
  self->speed = newspeed;
}

- (float)vFlaps
{
  return self->vflaps;
}

- (void)setVFlaps:(float)newvflaps
{
  self->vflaps = newvflaps;
}

- (float)hFlaps
{
  return self->hflaps;
}

- (void)setHFlaps:(float)newhflaps
{
  self->hflaps = newhflaps;
}

- (void)activate:(NSEvent *)event point:(NSPoint *)point camera:(SCCamera *)camera
{
  SC21_DEBUG(@"SCFlyMode.activate:point: (%.2f,%.2f)", point->x, point->y);

  [super activate];
}

- (id)valueForEvent:(NSEvent *)event
{
  NSPoint * p = [[SCMouseLog defaultMouseLog] point:0];
  return [NSValue valueWithPoint:*p];
}

- (BOOL)modifyCamera:(SCCamera *)camera withValue:(id)value
{
  SCMouseLog * mouselog = [SCMouseLog defaultMouseLog];
  NSPoint *lastp = [mouselog point:1];
  NSPoint *currp = [mouselog point:0];

  self->vflaps = (currp->y - lastp->y);
  self->hflaps = (currp->x - lastp->x);

  return YES;
}

- (void)modifyCamera:(SCCamera *)camera withTimeInterval:(NSTimeInterval)currtime
{
  SC21_LOG_METHOD;
  NSTimeInterval dt = currtime - self->prevtime;
  self->prevtime = currtime;

  self->speed += self->throttle*dt;

  SbVec3f v(0.0f, 0.0f, -self->speed*dt); 
  [camera translate:v];

  SbRotation rot(SbVec3f(0.0f, 1.0f, 0.0f), self->hflaps*dt);
  rot *= SbRotation(SbVec3f(1.0f, 0.0f, 0.0f), self->vflaps*dt);
  SoCamera * cam = [camera soCamera];
  if (cam) {
    cam->orientation = rot * cam->orientation.getValue();
  }
}

- (NSCursor *)cursor
{
  SC21_LOG_METHOD;
  return [NSCursor crosshairCursor];
}

@end
