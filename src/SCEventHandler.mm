#import <Sc21/SCEventHandler.h>
#import <Sc21/SCCamera.h>
#import <Sc21/SCController.h>
#import "SCUtil.h"
#import "SCMouseLog.h"
#import "SCMode.h"

#import "SCEventHandlerP.h"

@implementation SCEventHandlerP
@end

#define PRIVATE(p) ((p)->_sc_eventhandler)
#define SELF PRIVATE(self)

@implementation SCEventHandler

- (id)init
{
  if (self = [super init]) {
    [self _SC_commonInit];
  }
  return self;
}

- (void)dealloc
{
  [super dealloc];
}

#pragma mark --- operation bindings ---

- (void)enableOperation:(SCOperation)operation 
        forButton:(int)buttonNumber
        withModifier:(unsigned int)modifierFlags
{
  [SELF->buttondict 
       setObject:[NSNumber numberWithInt:buttonNumber]
       forKey:[NSNumber numberWithInt:operation]];
  [SELF->modifierdict 
       setObject:[NSNumber numberWithUnsignedInt:modifierFlags]
       forKey:[NSNumber numberWithInt:operation]];
}

- (void)getButton:(int *)buttonbuffer andModifier:(unsigned int *)modifierbuffer forOperation:(SCOperation)operation
{
  if (buttonbuffer) {
    NSNumber * buttonvalue = 
      [SELF->buttondict objectForKey:[NSNumber numberWithInt:operation]];
    if (buttonvalue) *buttonbuffer = [buttonvalue intValue];
  }
  if (modifierbuffer) {
    NSNumber * modifiervalue = 
      [SELF->modifierdict objectForKey:[NSNumber numberWithInt:operation]];
    if (modifiervalue) *modifierbuffer = [modifiervalue intValue];
  }
}

- (SCOperation)operationForButton:(int)buttonNumber andModifier:(unsigned int)modifierFlags
{
  NSEnumerator * keys = [SELF->buttondict keyEnumerator];
  NSNumber * key;
  unsigned int matchedflags = 0;
  int matchedoperation = SCNoOperation;
  while ((key = [keys nextObject])) {
    NSNumber * buttonvalue = [SELF->buttondict objectForKey:key];
    NSNumber * modifiervalue = [SELF->modifierdict objectForKey:key];
    int button = [buttonvalue intValue];
    unsigned int flags = [modifiervalue unsignedIntValue];
    if (button == buttonNumber &&
        (flags & modifierFlags) == flags &&
        flags >= matchedflags) {
      matchedflags = flags;
      matchedoperation = (SCOperation)[key intValue];
    }
  }
  return matchedoperation;
}

#pragma mark --- mouse button emulation ---

- (void)emulateButton:(int)buttonNumber usingModifier:(unsigned int)modifierFlags;
{
  [SELF->emulationdict setObject:[NSNumber numberWithUnsignedInt:modifierFlags]
        forKey:[NSNumber numberWithInt:buttonNumber]];
}

- (unsigned int)modifierForEmulatedButton:(int)buttonNumber
{
  NSNumber * modifiervalue = 
    [SELF->emulationdict objectForKey:[NSNumber numberWithInt:buttonNumber]];
  if (modifiervalue) return [modifiervalue unsignedIntValue];
  else return 0;
}


#pragma mark --- SCEventHandler protocol ---

#if 0
- (void)updateCamera:(SCCamera *)camera
{
  NSTimeInterval currtime = [NSDate timeIntervalSinceReferenceDate];
  [SELF->currentmode modifyCamera:camera withTimeInterval:currtime];
}

- (BOOL)handleEvent:(NSEvent *)event inView:(NSView *)view camera:(SCCamera *)camera
{
  return NO;
}
#endif

- (void)update
{
  NSTimeInterval currtime = [NSDate timeIntervalSinceReferenceDate];
  [SELF->currentmode modifyCamera:SELF->currentcamera withTimeInterval:currtime];
}

- (BOOL)handleEvent:(NSEvent *)event
{
  return NO;
}

- (void)drawableDidChange:(NSNotification *)notification
{
  SCController * controller = (SCController *)[notification object];
  SELF->currentdrawable = [controller drawable];
}

- (void)sceneGraphDidChange:(NSNotification *)notification
{
  SCController * controller = (SCController *)[notification object];
  SELF->currentcamera = [[controller sceneGraph] camera];
}

#pragma mark --- NSCoding conformance ---

- (void)encodeWithCoder:(NSCoder *)coder
{
  if ([coder allowsKeyedCoding]) {
    [coder encodeObject:SELF->emulationdict forKey:@"SC_emulationdict"];
    [coder encodeObject:SELF->buttondict forKey:@"SC_buttondict"];
    [coder encodeObject:SELF->modifierdict forKey:@"SC_modifierdict"];
  }
}

- (id)initWithCoder:(NSCoder *)coder
{
  if (self = [super init]) {
    [self _SC_commonInit];
    if ([coder allowsKeyedCoding]) {
      SELF->emulationdict = [[coder decodeObjectForKey:@"SC_emulationdict"] retain];
      SELF->buttondict = [[coder decodeObjectForKey:@"SC_buttondict"] retain];
      SELF->modifierdict = [[coder decodeObjectForKey:@"SC_modifierdict"] retain];
    }
  }
  return self;
}

@end

@implementation SCEventHandler (InternalAPI)

- (void)_SC_commonInit
{
  SELF = [[SCEventHandlerP alloc] init];
  SELF->emulationdict = [[NSMutableDictionary alloc] init];
  SELF->buttondict = [[NSMutableDictionary alloc] init];
  SELF->modifierdict = [[NSMutableDictionary alloc] init];
}

- (void)_SC_setCurrentMode:(SCMode *)mode
{
  [mode retain];
  [SELF->currentmode release];
  SELF->currentmode = mode;
}

- (SCMode *)_SC_currentMode
{
  return SELF->currentmode;
}

- (SCOperation)_SC_currentOperation
{
  return SELF->currentoperation;
}

- (void)_SC_setCurrentOperation:(SCOperation)operation
{
  SELF->currentoperation = operation;
}

- (int)_SC_emulatedButton:(int)buttonNumber forModifier:(unsigned int)modifierFlags
{
  int effectivebutton = buttonNumber;
  if (effectivebutton == 0) {
    NSEnumerator * keys = [SELF->emulationdict keyEnumerator];
    NSNumber * key;
    unsigned int matchedflags = 0;
    while ((key = [keys nextObject])) {
      NSNumber * value = [SELF->emulationdict objectForKey:key];
      unsigned int flags = [value unsignedIntValue];
      if ((flags & modifierFlags) == flags &&
          flags >= matchedflags) {
        matchedflags = flags;
        effectivebutton = [key intValue];
      }
    }
  }
  return effectivebutton;
}

- (void)_SC_activateMode:(SCMode *)newmode event:(NSEvent *)event
                   point:(NSPoint *)pn
{
  [newmode activate:event point:pn camera:SELF->currentcamera];
  [[SCMouseLog defaultMouseLog] setStartPoint:pn timestamp:[event timestamp]];
  [[newmode cursor] set];
  [[NSNotificationCenter defaultCenter]
    postNotificationName:SCCursorChangedNotification object:self];  
}

@end
