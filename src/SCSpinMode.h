#import "SCMode.h"
#include <Inventor/SbRotation.h>

@interface SCSpinMode : SCMode
{
  SbRotation * _spinrotation;
  NSTimeInterval _prevtime;
}

@end
