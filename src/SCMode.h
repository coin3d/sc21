#import <Cocoa/Cocoa.h>

@class SCCamera;

@interface SCMode : NSObject
{
  //FIXME: Pimplify?
 @private
  BOOL active;
}

- (BOOL)isActive;
- (void)activate;
- (void)activate:(NSEvent *)event point:(NSPoint *)point camera:(SCCamera *)camera;
- (void)deactivate;
- (NSCursor *)cursor;

- (id)valueForEvent:(NSEvent *)event;
- (BOOL)modifyCamera:(SCCamera *)camera withValue:(id)value;
- (void)modifyCamera:(SCCamera *)camera withTimeInterval:(NSTimeInterval)currtime;
@end
