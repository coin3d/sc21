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
