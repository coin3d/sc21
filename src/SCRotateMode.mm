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
