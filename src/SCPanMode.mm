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
  cam = [camera soCamera];
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
