#import <Sc21/SCFlyHandler.h>
#import <Sc21/SCCamera.h>
#import "SCFlyMode.h"
#import "SCMouseLog.h"
#import "SCUtil.h"
#import <Sc21/SCEventHandlerP.h>

@interface _SCFlyHandlerP : NSObject
{
  NSTimeInterval _prevtime;
  SCFlyMode * flymode;
  BOOL inversepitch;
  BOOL uparrow;
  BOOL downarrow;
  BOOL leftarrow;
  BOOL rightarrow;
}
@end

@implementation _SCFlyHandlerP
@end

@interface SCFlyHandler (InternalAPI)
- (Class)_SC_modeForOperation:(SCOperation)operation;
@end

#define PRIVATE(p) ((p)->_sc_flyhandler)
#define SELF PRIVATE(self)

@implementation SCFlyHandler

- (id)init
{
  self = [super init];
  SELF = [[_SCFlyHandlerP alloc] init];
  SELF->flymode = [[SCFlyMode alloc] init];
  return self;
}

- (void)dealloc
{
  [SELF->flymode release];
  [SELF release];
}

- (void)setInversePitch:(BOOL)yesno
{
  SELF->inversepitch = yesno;
}

- (BOOL)isInversePitch
{
  return SELF->inversepitch;
}

- (BOOL)handleEvent:(NSEvent *)event inView:(NSView *)view camera:(SCCamera *)camera
{ 
  SC21_LOG_METHOD;
  BOOL handled = NO;

  NSPoint p = [view convertPoint:[event locationInWindow] fromView:nil];
  NSPoint pn;
  NSSize size = [view visibleRect].size;
  pn.x = p.x / size.width;
  pn.y = p.y / size.height;

  int eventtype = [event type];
  if (eventtype == NSLeftMouseDragged || 
      eventtype == NSRightMouseDragged ||
      eventtype == NSOtherMouseDragged) {
    if (![SELF->flymode isActive]) {
      [self _SC_activateMode:SELF->flymode event:event 
            point:&pn camera:camera view:view];
    } else {
      [[SCMouseLog defaultMouseLog] appendPoint:&pn 
                                    timestamp:[event timestamp]];
    }
    handled = [SELF->flymode modifyCamera:camera withValue:[SELF->flymode valueForEvent:event]];
  }

#if 0
  unsigned int modifierflags = [event modifierFlags];
  // Check if this event will trigger an operation change
  SCOperation operation = [self _SC_currentOperation];
  if (eventtype == NSLeftMouseUp ||
      eventtype == NSRightMouseUp ||
      eventtype == NSOtherMouseUp) {
    operation = SCNoOperation;
  }
  else if (eventtype == NSLeftMouseDown ||
           eventtype == NSRightMouseDown ||
           eventtype == NSOtherMouseDown) {
    // Check for emulations
    int effectivebutton = [self _SC_emulatedButton:[event buttonNumber] 
                                forModifier:modifierflags];
    
    SCOperation newoperation = [self operationForButton:effectivebutton andModifier:modifierflags];
    if (newoperation != SCNoOperation) operation = newoperation;
  }

  if (operation != [self _SC_currentOperation]) {
    [self _SC_setCurrentOperation:operation];
    [[self _SC_currentMode] deactivate];
    Class modeclass = [self _SC_modeForOperation:operation];
    if (modeclass) {
      SCMode * newmode = [[[modeclass alloc] init] autorelease];
      [self _SC_setCurrentMode:newmode];
      [self _SC_activateMode:newmode event:event point:&pn camera:camera view:view];
    }
    else [self _SC_setCurrentMode:nil];
  }
#endif

  if (!handled) {
    NSEventType type = [event type];
    if ((type == NSKeyUp) || (type == NSKeyDown)) {
      BOOL keydown = NO;
      if (type == NSKeyDown) keydown = YES;
      switch ([[event characters] characterAtIndex:0]) {
      case NSUpArrowFunctionKey:
        SELF->uparrow = keydown;
        handled = YES;
        break;
      case NSDownArrowFunctionKey:
        SELF->downarrow = keydown;
        handled = YES;
        break;
      case NSLeftArrowFunctionKey:
        SELF->leftarrow = keydown;
        handled = YES;
        break;
      case NSRightArrowFunctionKey:
        SELF->rightarrow = keydown;
        handled = YES;
        break;
      default:
        break;
      }
    }
  }

  if (handled) {
    [camera soCamera]->touch();
  }
  return handled;
}

- (void)updateCamera:(SCCamera *)camera
{
  SC21_LOG_METHOD;
  NSTimeInterval currtime = [NSDate timeIntervalSinceReferenceDate];
  NSTimeInterval dt = currtime - SELF->_prevtime;
  SELF->_prevtime = currtime;

  float throttle = (SELF->uparrow)?1.0f:0.0f + (SELF->downarrow)?-1.0f:0.0f;
  [SELF->flymode setThrottle:throttle];

  [SELF->flymode modifyCamera:camera withTimeInterval:currtime];
}

@end

@implementation SCFlyHandler (InternalAPI)

- (Class)_SC_modeForOperation:(SCOperation)operation
{
//   switch (operation) {
//   case SCRotate: 
//     return [SCRotateMode class];
//     break;
//   case SCPan: 
//     return [SCPanMode class];
//     break;
//   case SCZoom:
//     return [SCZoomMode class];
//     break;
//   case SCNoOperation: 
//   default:
//     return Nil;
//     break;
//   }
  return Nil;
}

@end
