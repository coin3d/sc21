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

#import "SCSpinMode.h"
#import "SCCursors.h"
#import "SCCamera.h"
#import "SCUtil.h"
#import "SCMouseLog.h"

#include <Inventor/SbLinear.h>
#include <Inventor/projectors/SbSphereSheetProjector.h>
#include <Inventor/nodes/SoCamera.h>

@implementation SCSpinMode


- (void)dealloc
{
  SC21_LOG_METHOD;
  delete _spinrotation;
  [super dealloc];
}

- (void)activate:(NSEvent *)event point:(NSPoint *)point camera:(SCCamera *)camera
{
  SC21_DEBUG(@"SCSpinMode.activate:(%.2f,%.2f)", point->x, point->y);
  
  [super activate];
  if (!_spinrotation) {
    _spinrotation = new SbRotation;
  }
  _prevtime = [NSDate timeIntervalSinceReferenceDate];

  SCMouseLog * oldmouselog = [SCMouseLog defaultMouseLog];
  double lastdelta = [event timestamp] - [oldmouselog timestamp:0];
  SC21_DEBUG(@"  lastdelta: %.2f", lastdelta);
  if (lastdelta < 0.1) {
    SbViewVolume volume;
    volume.ortho(-1, 1, -1, 1, -1, 1);
    SbSphere s(SbVec3f(0.0f, 0.0f, 0.0f), 0.8f);
    SbSphereSheetProjector projector(s);
    projector.setViewVolume(volume);
    NSPoint *fromp = [oldmouselog point:2];
    SbVec3f from = projector.project(SbVec2f(fromp->x, fromp->y));
    SbVec3f to = projector.project(SbVec2f(point->x, point->y));
    SbRotation rot = projector.getRotation(from, to);
    double dt = [event timestamp] - [oldmouselog timestamp:2];
    rot.invert();
    
    //FIXME: debug
    SbVec3f axis;
    float radians;
    rot.getValue(axis, radians);
    SC21_DEBUG(@"  axis: (%.2f %.2f %.2f) radians: %.2f", 
          axis[0], axis[1], axis[2], radians);

    rot.scaleAngle(float(0.2 / dt));
    _spinrotation->setValue(rot.getValue());

    SoCamera * socamera = [camera soCamera];
    if (socamera) {
      socamera->touch();
    }
  }
  else _spinrotation->setValue(SbVec3f(1.0f, 0.0f, 0.0f), 0.0f);
}

- (void)modifyCamera:(SCCamera *)camera withTimeInterval:(NSTimeInterval)currtime
{
  NSTimeInterval dt = currtime - _prevtime;
  _prevtime = currtime;

  SbRotation deltaRotation = *_spinrotation;
  deltaRotation.scaleAngle(float(dt * 5.0f));
  [camera reorient:deltaRotation];
}

@end
