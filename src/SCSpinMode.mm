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

  // prevent continuous scene updates when rotation angle is zero
  const float * val = _spinrotation->getValue();
  if (val && val[3] == 1) return;

  SbRotation deltaRotation = *_spinrotation;
  deltaRotation.scaleAngle(float(dt * 5.0f));
  [camera reorient:deltaRotation];
}

@end
