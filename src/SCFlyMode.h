#import "SCMode.h"

@interface SCFlyMode : SCMode
{
  float vflaps;
  float hflaps;
  float speed;
  float throttle;
  NSTimeInterval prevtime;
}

- (float)throttle;
- (void)setThrottle:(float)throttle;
- (float)speed;
- (void)setSpeed:(float)speed;
- (float)vFlaps;
- (void)setVFlaps:(float)vflaps;
- (float)hFlaps;
- (void)setHFlaps:(float)hflaps;

@end
