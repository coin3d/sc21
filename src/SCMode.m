#import "SCMode.h"
#import "SCUtil.h"

@implementation SCMode

- (BOOL)isActive
{
  return active;
}

- (void)activate
{
  SC21_LOG_METHOD;
  active = YES;
}

- (void)activate:(NSEvent *)event point:(NSPoint *)point camera:(SCCamera *)camera
{
  [self activate];
}

- (void)deactivate
{
  SC21_LOG_METHOD;
  active = NO;
}

- (NSCursor *)cursor
{
  SC21_LOG_METHOD;
  return nil;
}

- (id)valueForEvent:(NSEvent *)event
{
  return nil;
}

- (BOOL)modifyCamera:(SCCamera *)camera withValue:(id)value
{
  SC21_LOG_METHOD;
  return NO; 
}

- (void)modifyCamera:(SCCamera *)camera withTimeInterval:(NSTimeInterval)currtime
{
  SC21_LOG_METHOD;
}
@end
