#import "SCZoomMode.h"
#import "SCCursors.h"
#import "SCCamera.h"
#import "SCUtil.h"
#import "SCMouseLog.h"

#include <Inventor/SbLinear.h>
#include <Inventor/nodes/SoCamera.h>

@implementation SCZoomMode

- (void)activate:(NSEvent *)event point:(NSPoint *)point camera:(SCCamera *)camera
{
  SC21_DEBUG(@"SCZoomMode.activate:point: (%.2f,%.2f)", point->x, point->y);
  [super activate];
}

- (id)valueForEvent:(NSEvent *)event
{
  NSPoint *p = [[SCMouseLog defaultMouseLog] point:0];
  return [NSValue valueWithPoint:*p];
}

- (BOOL)modifyCamera:(SCCamera *)camera withValue:(id)value
{
  NSPoint *lastp, *currp;
  
  SCMouseLog * mouselog = [SCMouseLog defaultMouseLog];
  lastp = [mouselog point:1];
  currp = [mouselog point:0];
  [camera zoom:(currp->y - lastp->y)];

  return YES;
}


- (NSCursor *)cursor
{
  SC21_LOG_METHOD;
  return [NSCursor zoomCursor];
}

@end
