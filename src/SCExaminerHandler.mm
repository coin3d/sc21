#import <Sc21/SCExaminerHandler.h>
#import <Sc21/SCCamera.h>
#import "SCRotateMode.h"
#import "SCPanMode.h"
#import "SCZoomMode.h"
#import "SCMouseLog.h"

#import <Sc21/SCEventHandlerP.h>

@interface _SCExaminerHandlerP : NSObject
{
  BOOL spinenabled;
  BOOL scrollwheelzoomenabled;
}
@end

@implementation _SCExaminerHandlerP
@end

@interface SCExaminerHandler (InternalAPI)
- (Class)_SC_modeForOperation:(SCOperation)operation;
- (BOOL)_SC_performActionForEvent:(NSEvent *)event camera:(SCCamera *)camera;
@end

#define PRIVATE(p) ((p)->_sc_examinerhandler)
#define SELF PRIVATE(self)

@implementation SCExaminerHandler

- (id)init
{
  self = [super init];

  [self enableOperation:SCRotate forButton:0 withModifier:0];
  [self enableOperation:SCPan forButton:2 withModifier:0];
  [self enableOperation:SCZoom forButton:0 withModifier:NSShiftKeyMask];
  [self emulateButton:2 usingModifier:NSAlternateKeyMask];
  [self setSpinEnabled:YES];
  [self setScrollWheelZoomEnabled:YES];

  return self;
}

- (void)dealloc
{
  [SELF release];
}

- (void)setSpinEnabled:(BOOL)enabled
{
  SELF->spinenabled = enabled;
}

- (BOOL)spinEnabled
{
  return SELF->spinenabled;
}

- (void)setScrollWheelZoomEnabled:(BOOL)enabled
{
  SELF->scrollwheelzoomenabled = enabled;
}

- (BOOL)scrollWheelZoomEnabled
{
  return SELF->scrollwheelzoomenabled;
}

- (BOOL)handleEvent:(NSEvent *)event inView:(NSView *)view camera:(SCCamera *)camera
{ 
  NSPoint p = [view convertPoint:[event locationInWindow] fromView:nil];
  NSPoint pn;
  NSSize size = [view visibleRect].size;
  pn.x = p.x / size.width;
  pn.y = p.y / size.height;

  BOOL handled = NO;
  int eventtype = [event type];
  if (eventtype == NSLeftMouseDragged || 
      eventtype == NSRightMouseDragged ||
      eventtype == NSOtherMouseDragged) {
    SCMode * currentmode = [self _SC_currentMode];
    if (currentmode) {
      if (![currentmode isActive]) {
        [self activateMode:currentmode event:event 
              point:&pn camera:camera view:view];
      } else {
        [[SCMouseLog defaultMouseLog] appendPoint:&pn 
                                      timestamp:[event timestamp]];
      }
      handled = [currentmode modifyCamera:camera withValue:[currentmode valueForEvent:event]];
    }
    return handled;
  }

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
    int effectivebutton = [self _SC_emulatedButton:[event buttonNumber] forModifier:modifierflags];
    
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
      [self activateMode:newmode event:event point:&pn camera:camera view:view];
    }
    else [self _SC_setCurrentMode:nil];
  }

  if (!handled) return [self _SC_performActionForEvent:event camera:camera];
}

// ---------------- NSCoding conformance -------------------------------

- (void)encodeWithCoder:(NSCoder *)coder
{
  if ([coder allowsKeyedCoding]) {
    [coder encodeBool:SELF->spinenabled forKey:@"SC_spinenabled"];
    [coder encodeBool:SELF->scrollwheelzoomenabled forKey:@"SC_scrollwheelzoomenabled"];
  }
}

- (id)initWithCoder:(NSCoder *)coder
{
  if (self = [super initWithCoder:coder]) {
    if ([coder allowsKeyedCoding]) {
      // We don't need to check for existence since these two keys
      // will always exist.
      SELF->spinenabled = [coder decodeBoolForKey:@"SC_spinenabled"];
      SELF->scrollwheelzoomenabled = [coder decodeBoolForKey:@"SC_scrollwheelzoomenabled"];
    }
  }
  return self;
}

@end

@implementation SCExaminerHandler (InternalAPI)

- (void)_SC_commonInit
{
  [super _SC_commonInit];
  SELF = [[_SCExaminerHandlerP alloc] init];
}

- (BOOL)_SC_performActionForEvent:(NSEvent *)event camera:(SCCamera *)camera
{
  if ([event type] == NSScrollWheel &&
      SELF->scrollwheelzoomenabled) {
    float deltay = [event deltaY];
    if (deltay > 0.0f) {
      [camera zoom:deltay];
      return YES;
    }
  }
  return NO;
}

- (Class)_SC_modeForOperation:(SCOperation)operation
{
  switch (operation) {
  case SCRotate: 
    return [SCRotateMode class];
    break;
  case SCPan: 
    return [SCPanMode class];
    break;
  case SCZoom:
    return [SCZoomMode class];
    break;
  case SCNoOperation: 
  default:
    return Nil;
    break;
  }
}

@end
