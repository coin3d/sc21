#import <Cocoa/Cocoa.h>

@class SCMode;
@class SCCamera;
@class _SCEventHandlerP;

typedef int SCOperation;
#define SCNoOperation 0

@interface SCEventHandler : NSObject <NSCoding>
{
 @protected
  _SCEventHandlerP * _sc_eventhandler;
}

- (void)enableOperation:(SCOperation)operation forButton:(int)buttonNumber withModifier:(unsigned int)modifierFlags;
- (void)getButton:(int *)buttonbuffer andModifier:(unsigned int *)modifierbuffer forOperation:(SCOperation)operation;
- (SCOperation)operationForButton:(int)buttonNumber andModifier:(unsigned int)modifierFlags;

- (void)emulateButton:(int)button usingModifier:(unsigned int)modifierFlags;
- (unsigned int)modifierForEmulatedButton:(int)buttonNumber;

- (BOOL)handleEvent:(NSEvent *)event inView:(NSView *)view camera:(SCCamera *)camera;
- (void)updateCamera:(SCCamera *)camera;
- (void)activateMode:(SCMode *)mode event:(NSEvent *)event point:(NSPoint *)pn camera:(SCCamera *)camera view:(NSView *)view;
@end