#import <Sc21/SCExaminerHandler.h>
#import <Sc21/SCCamera.h>
#import "SCRotateMode.h"
#import "SCPanMode.h"
#import "SCZoomMode.h"
#import "SCMouseLog.h"
#import "SCUtil.h"
#import <Sc21/SCController.h>

#import <Sc21/SCExaminerHandlerP.h>

#define SELF self->_sc_examinerhandler

@implementation SCExaminerHandler

#pragma mark --- initialization and cleanup ---

- (id)init
{
  if (self = [super init]) {
    [self _SC_commonInit];
    [self setRotateButton:0 modifier:0];
    [self setPanButton:2 modifier:0];
    [self setZoomButton:0 modifier:NSShiftKeyMask];
    [self setSpinEnabled:YES];
    [self setScrollWheelZoomEnabled:YES];
  }
  return self;
}

- (void)dealloc
{
  [SELF->emulator release];
  [SELF release];
}

#pragma mark --- mouse- and keybindings --- 

- (void)setPanButton:(int)buttonNumber modifier:(unsigned int)modifierFlags
{
  SELF->panbutton = buttonNumber;
  SELF->panmodifier = modifierFlags;
}

- (void)setRotateButton:(int)buttonNumber modifier:(unsigned int)modifierFlags
{
  SELF->rotatebutton = buttonNumber;
  SELF->rotatemodifier = modifierFlags;
}

- (void)setZoomButton:(int)buttonNumber modifier:(unsigned int)modifierFlags
{
  SELF->zoombutton = buttonNumber;
  SELF->zoommodifier = modifierFlags;
}

- (void)getPanButton:(int*)button modifier:(unsigned int*)modifierFlags
{
  *button = SELF->panbutton;
  *modifierFlags = SELF->panmodifier;
}

- (void)getRotateButton:(int*)button modifier:(unsigned int*)modifierFlags
{
  *button = SELF->rotatebutton;
  *modifierFlags = SELF->rotatemodifier; 
}

- (void)getZoomButton:(int*)button modifier:(unsigned int*)modifierFlags
{
  *button = SELF->zoombutton;
  *modifierFlags = SELF->zoommodifier;  
}

#pragma mark --- additional settings ---

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

#pragma mark --- mouse button emulation ---

- (SCEmulator *)emulator
{
  return SELF->emulator;
}

- (void)setEmulator:(SCEmulator *)emulator
{
  if (emulator != SELF->emulator) [SELF->emulator release];
  SELF->emulator = [emulator retain];
}

#pragma mark --- SCEventHandler conformance ---

- (BOOL)handleEvent:(NSEvent *)event
{ 
  SC21_LOG_METHOD;
  NSRect frame = [SELF->currentdrawable frame];
  NSPoint p = [event locationInWindow];
  NSPoint pn;
  pn.x = (p.x - frame.origin.x) / frame.size.width;
  pn.y = (p.y - frame.origin.y) / frame.size.height;

  BOOL handled = NO;
  int eventtype = [event type];
  if (eventtype == NSLeftMouseDragged || 
      eventtype == NSRightMouseDragged ||
      eventtype == NSOtherMouseDragged) {
    SCMode * currentmode = [self _SC_currentMode];
    if (currentmode) {
      if (![currentmode isActive]) {
        [self _SC_activateMode:currentmode event:event point:&pn];
      } else {
        [[SCMouseLog defaultMouseLog] appendPoint:&pn 
                                      timestamp:[event timestamp]];
      }
      handled = [currentmode modifyCamera:SELF->currentcamera 
                                withValue:[currentmode valueForEvent:event]];
    }
    return handled;
  }
  
  unsigned int modifierflags = [event modifierFlags];
  
  Class mode = [[self _SC_currentMode] class];
  if (eventtype == NSLeftMouseUp ||
      eventtype == NSRightMouseUp ||
      eventtype == NSOtherMouseUp) {
    mode = Nil;
  } 

  else if (eventtype == NSLeftMouseDown ||
           eventtype == NSRightMouseDown ||
           eventtype == NSOtherMouseDown) {
    // Check for emulations
    int effectivebutton = [SELF->emulator emulatedButtonForButton:[event buttonNumber] 
                                                         modifier:modifierflags];
    
    Class newmode = [self _SC_modeForButton:effectivebutton 
                                   modifier:modifierflags];
    if (newmode != Nil) mode = newmode;
  }

  if (mode != [[self _SC_currentMode] class]) {
    [[self _SC_currentMode] deactivate];
    if (mode) {
      SCMode * newmode = [[[mode alloc] init] autorelease];
      [self _SC_setCurrentMode:newmode];
      [self _SC_activateMode:newmode event:event point:&pn];
    }
    else [self _SC_setCurrentMode:nil];
  }

  if (!handled) 
    return [self _SC_performActionForEvent:event camera:SELF->currentcamera];
}

- (void)update
{
  NSTimeInterval currtime = [NSDate timeIntervalSinceReferenceDate];
  [SELF->currentmode modifyCamera:SELF->currentcamera withTimeInterval:currtime];
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
    [coder encodeBool:SELF->spinenabled forKey:@"SC_spinenabled"];
    [coder encodeBool:SELF->scrollwheelzoomenabled forKey:@"SC_scrollwheelzoomenabled"];
  }
}

- (id)initWithCoder:(NSCoder *)coder
{
  if (self = [super init]) {
    if ([coder allowsKeyedCoding]) {
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
  SELF = [[SCExaminerHandlerP alloc] init];
  // FIXME: Archive emulator. kyrah 20040801.
  SELF->emulator = [[SCEmulator alloc] init];
  [SELF->emulator emulateButton:2 usingModifier:NSAlternateKeyMask];
}

- (BOOL)_SC_performActionForEvent:(NSEvent *)event camera:(SCCamera *)camera
{
  if ([event type] == NSScrollWheel && SELF->scrollwheelzoomenabled) {
    [camera zoom:[event deltaY]/500.0f];
    return YES;
  }
  return NO;
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

- (void)_SC_activateMode:(SCMode *)newmode event:(NSEvent *)event
                   point:(NSPoint *)pn
{
  [newmode activate:event point:pn camera:SELF->currentcamera];
  [[SCMouseLog defaultMouseLog] setStartPoint:pn timestamp:[event timestamp]];
  [[newmode cursor] set];
  [[NSNotificationCenter defaultCenter]
    postNotificationName:SCCursorChangedNotification object:self];  
}

- (Class)_SC_modeForButton:(int)buttonNumber modifier:(unsigned int)modifierFlags
{
  unsigned int matchedflags = 0;
  Class matchedmode = Nil;
  
  if (SELF->rotatebutton == buttonNumber && 
      (SELF->rotatemodifier & modifierFlags) == SELF->rotatemodifier &&
      SELF->rotatemodifier >= matchedflags) {
    matchedflags = SELF->rotatemodifier;
    matchedmode = [SCRotateMode class];    
  }
  
  if (SELF->zoombutton  == buttonNumber && 
      (SELF->zoommodifier & modifierFlags) == SELF->zoommodifier &&
      SELF->zoommodifier >= matchedflags) {
    matchedflags = SELF->zoommodifier;
    matchedmode = [SCZoomMode class];  
  }
  
  if (SELF->panbutton  == buttonNumber && 
      (SELF->panmodifier & modifierFlags) == SELF->panmodifier &&
      SELF->panmodifier >= matchedflags)  {
    matchedflags = SELF->panmodifier;
    matchedmode = [SCPanMode class];
  }
  
  return matchedmode;
}

@end
