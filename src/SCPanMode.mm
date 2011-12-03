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
