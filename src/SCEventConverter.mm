
/* Just for reference, some doc regarding events:
these messages are valid for all events:
- (NSEventType)type;
- (NSPoint)locationInWindow;
- (unsigned int)modifierFlags;
- (NSTimeInterval)timestamp;
- (NSWindow *)window;
- (int)windowNumber;
- (NSGraphicsContext*)context;
*/

#import "SCEventConverter.h"
#import "SCController.h"
#import "SCView.h"


struct key1map {
  unichar nsvalue;
  char printable;
  SoKeyboardEvent::Key sovalue;
};

static struct key1map KeyMap[] = {
  { 'a', 'a', SoKeyboardEvent::A }, { 'A', 'A', SoKeyboardEvent::A },
  { 'b', 'b', SoKeyboardEvent::B }, { 'B', 'B', SoKeyboardEvent::B },
  { 'c', 'c', SoKeyboardEvent::C }, { 'C', 'C', SoKeyboardEvent::C },
  { 'd', 'd', SoKeyboardEvent::D }, { 'D', 'D', SoKeyboardEvent::D },
  { 'e', 'e', SoKeyboardEvent::E }, { 'E', 'E', SoKeyboardEvent::E },
  { 'f', 'f', SoKeyboardEvent::F }, { 'F', 'F', SoKeyboardEvent::F },
  { 'g', 'g', SoKeyboardEvent::G }, { 'G', 'G', SoKeyboardEvent::G },
  { 'h', 'h', SoKeyboardEvent::H }, { 'H', 'H', SoKeyboardEvent::H },
  { 'i', 'i', SoKeyboardEvent::I }, { 'I', 'I', SoKeyboardEvent::I },
  { 'j', 'j', SoKeyboardEvent::J }, { 'J', 'J', SoKeyboardEvent::J },
  { 'k', 'k', SoKeyboardEvent::K }, { 'K', 'K', SoKeyboardEvent::K },
  { 'l', 'l', SoKeyboardEvent::L }, { 'L', 'L', SoKeyboardEvent::L },
  { 'm', 'm', SoKeyboardEvent::M }, { 'M', 'M', SoKeyboardEvent::M },
  { 'n', 'n', SoKeyboardEvent::N }, { 'N', 'M', SoKeyboardEvent::N },
  { 'o', 'o', SoKeyboardEvent::O }, { 'O', 'O', SoKeyboardEvent::O },
  { 'p', 'p', SoKeyboardEvent::P }, { 'P', 'P', SoKeyboardEvent::P },
  { 'q', 'q', SoKeyboardEvent::Q }, { 'Q', 'Q', SoKeyboardEvent::Q },
  { 'r', 'r', SoKeyboardEvent::R }, { 'R', 'R', SoKeyboardEvent::R },
  { 's', 's', SoKeyboardEvent::S }, { 'S', 'S', SoKeyboardEvent::S },
  { 't', 't', SoKeyboardEvent::T }, { 'T', 'T', SoKeyboardEvent::T },
  { 'u', 'u', SoKeyboardEvent::U }, { 'U', 'U', SoKeyboardEvent::U },
  { 'v', 'v', SoKeyboardEvent::V }, { 'V', 'V', SoKeyboardEvent::V },
  { 'w', 'w', SoKeyboardEvent::W }, { 'W', 'W', SoKeyboardEvent::W },
  { 'x', 'x', SoKeyboardEvent::X }, { 'X', 'X', SoKeyboardEvent::X },
  { 'y', 'y', SoKeyboardEvent::Y }, { 'Y', 'Y', SoKeyboardEvent::Y },
  { 'z', 'z', SoKeyboardEvent::Z }, { 'Z', 'Z', SoKeyboardEvent::Z },
  {'0', '0',SoKeyboardEvent::NUMBER_0},
  {'0', '1',SoKeyboardEvent::NUMBER_1},
  {'2', '2',SoKeyboardEvent::NUMBER_2},
  {'3', '3',SoKeyboardEvent::NUMBER_3},
  {'4', '4',SoKeyboardEvent::NUMBER_4},
  {'5', '5',SoKeyboardEvent::NUMBER_5},
  {'6', '6',SoKeyboardEvent::NUMBER_6},
  {'7', '7',SoKeyboardEvent::NUMBER_7},
  {'8', '8',SoKeyboardEvent::NUMBER_8},
  {'9', '9',SoKeyboardEvent::NUMBER_9},
  { ' ', ' ', SoKeyboardEvent::SPACE },
  { '\'', '\'', SoKeyboardEvent::APOSTROPHE },
  { ',', ',', SoKeyboardEvent::COMMA },
  { '-', '-', SoKeyboardEvent::MINUS },
  { '.', '.', SoKeyboardEvent::PERIOD },
  { '/', '/', SoKeyboardEvent::SLASH },
  { '\\', '\\',SoKeyboardEvent::BACKSLASH },
  { ';', ';', SoKeyboardEvent::SEMICOLON },
  { '=', '=', SoKeyboardEvent::EQUAL },
  { '[', '[', SoKeyboardEvent::BRACKETLEFT },
  { ']', ']', SoKeyboardEvent::BRACKETRIGHT },
  { '`', '`', SoKeyboardEvent::GRAVE },
  // ---------------- now it gets really ugly :( -----------------------
  { ')', ')', SoKeyboardEvent::NUMBER_0 },
  { '!', '!', SoKeyboardEvent::NUMBER_1 },
  { '@', '@', SoKeyboardEvent::NUMBER_2 },
  { '#', '#', SoKeyboardEvent::NUMBER_3 },
  { '$', '$', SoKeyboardEvent::NUMBER_4 },
  { '%', '%', SoKeyboardEvent::NUMBER_5 },
  { '^', '^', SoKeyboardEvent::NUMBER_6 },
  { '&', '&', SoKeyboardEvent::NUMBER_7 },
  { '*', '*', SoKeyboardEvent::NUMBER_8 },
  { '(', '(', SoKeyboardEvent::NUMBER_9 },
  { '\"', '\"', SoKeyboardEvent::APOSTROPHE },
  { '<', '<', SoKeyboardEvent::COMMA },
  { '_', '_', SoKeyboardEvent::MINUS },
  { '>', '>', SoKeyboardEvent::PERIOD },
  { '?', '?', SoKeyboardEvent::SLASH },
  { ':', ':', SoKeyboardEvent::SEMICOLON },
  { '+', '+', SoKeyboardEvent::EQUAL },
  { '{', '{', SoKeyboardEvent::BRACKETLEFT },
  { '}', '}', SoKeyboardEvent::BRACKETRIGHT },
  { '|', '|', SoKeyboardEvent::BACKSLASH },
  { '~', '~', SoKeyboardEvent::GRAVE },
    // --------- and back to just normally ugly: -------------------
  { NSUpArrowFunctionKey, '.', SoKeyboardEvent::UP_ARROW },
  { NSDownArrowFunctionKey, '.', SoKeyboardEvent::DOWN_ARROW },
  { NSLeftArrowFunctionKey, '.', SoKeyboardEvent::LEFT_ARROW },
  { NSRightArrowFunctionKey, '.', SoKeyboardEvent::RIGHT_ARROW },
  { NSTabCharacter, '.', SoKeyboardEvent::TAB },
  { NSCarriageReturnCharacter, '.', SoKeyboardEvent::RETURN },
  { NSEnterCharacter, '.', SoKeyboardEvent::ENTER },
  { NSBackspaceCharacter,  '.', SoKeyboardEvent::BACKSPACE },
  { NSDeleteCharacter, '.', SoKeyboardEvent::KEY_DELETE },
  // Note: Ctrl, Alt, Shift and Command are interpreted as
  // modifiers, so we need to check [event flags] for that.
  { NSF1FunctionKey, '.', SoKeyboardEvent::F1 },
  { NSF2FunctionKey, '.', SoKeyboardEvent::F2 },
  { NSF3FunctionKey, '.', SoKeyboardEvent::F3 },
  { NSF4FunctionKey, '.', SoKeyboardEvent::F4 },
  { NSF5FunctionKey, '.', SoKeyboardEvent::F5 },
  { NSF6FunctionKey, '.', SoKeyboardEvent::F6 },
  { NSF7FunctionKey, '.', SoKeyboardEvent::F7 },
  { NSF8FunctionKey, '.', SoKeyboardEvent::F8 },
  { NSF9FunctionKey, '.', SoKeyboardEvent::F9 },
  { NSF10FunctionKey, '.', SoKeyboardEvent::F10 },
  { NSF11FunctionKey, '.', SoKeyboardEvent::F11 },
  { NSF12FunctionKey, '.', SoKeyboardEvent::F12 },
  // Note: NSF13FunctionKey to NSF35FunctionKey and all other
  // function key constants (see NSEvent.h) are not defined
  // by SoKeyboardEvent.
  { NSInsertFunctionKey, '.', SoKeyboardEvent::INSERT },
  { NSDeleteFunctionKey, '.', SoKeyboardEvent::DELETE },
  { NSHomeFunctionKey, '.', SoKeyboardEvent::HOME },
  { NSEndFunctionKey, '.', SoKeyboardEvent::END },
  { NSPageUpFunctionKey, '.', SoKeyboardEvent::PAGE_UP },
  { NSPageDownFunctionKey, '.', SoKeyboardEvent::PAGE_DOWN },
  { NSPrintScreenFunctionKey, '.', SoKeyboardEvent::PRINT },
  { NSClearLineFunctionKey, '.', SoKeyboardEvent::NUM_LOCK },  
  { 0x00, '.', SoKeyboardEvent::ANY },
};


@implementation SCEventConverter

// ---------------- Initialisation and cleanup -------------------------

/*" Initializes a newly allocated SCEventConverter. 

    This method is the designated initializer for the SCEventConverter
    class. Returns !{self}.
 "*/

- (id) initWithController:(SCController *)ctrl
{
  if (self = [super init]) {
    _controller = ctrl;
    keydict = new SbDict;
    printabledict = new SbDict;
    int i=0;
    while (KeyMap[i].nsvalue != 0) {
      keydict->enter((unsigned long)KeyMap[i].nsvalue,
                     (void *)KeyMap[i].sovalue);
      printabledict->enter((unsigned long)KeyMap[i].nsvalue,
                           (void *)(int)KeyMap[i].printable);
      i++;
    }    
  }
  return self;
}

/*" Initializes a newly allocated SCEventConverter. Note that you 
    must set the SCController component for Coin handling explicitly 
    using #setController: before being able to use the camera.
    
    This method is the designated initializer for the SCEventConverter
    class. Returns !{self}.
 "*/

- (id) init
{
  return [self initWithController:nil];
}


/* Clean up after ourselves. */
- (void) dealloc
{
  delete keydict;
  delete printabledict;
}


// ------------------ Event conversion ---------------------------


/*" Creates an SoEvent from the NSEvent event, setting the mouse button and
    mouse state (for mouse events) or key information (for keyboard events), and
     position, modifier keys, and time when the event occurred.
  "*/
  
- (SoEvent *) createSoEvent:(NSEvent *) event
{
  NSPoint q = [[_controller view] convertPoint:[event locationInWindow] fromView:nil];
  unsigned int flags = [event modifierFlags];
  NSEventType type = [event type];
  SoEvent * se = NULL;
  SoMouseButtonEvent * smbe = NULL;
  SoLocation2Event* sle = NULL;
  switch (type) {
    
    case NSLeftMouseDown:
      smbe = new SoMouseButtonEvent;
      smbe->setButton(SoMouseButtonEvent::BUTTON1);
      smbe->setState(SoButtonEvent::DOWN);
      se = smbe;
      break;
      
    case NSLeftMouseUp:
      smbe = new SoMouseButtonEvent;
      smbe->setButton(SoMouseButtonEvent::BUTTON1);
      smbe->setState(SoButtonEvent::UP);
      se = smbe;
      break;
      
    case NSOtherMouseDown:
      smbe = new SoMouseButtonEvent;
      smbe->setButton(SoMouseButtonEvent::BUTTON3);
      smbe->setState(SoButtonEvent::DOWN);
      se = smbe;
      break;
      
    case NSOtherMouseUp:
      smbe = new SoMouseButtonEvent;
      smbe->setButton(SoMouseButtonEvent::BUTTON3);
      smbe->setState(SoButtonEvent::UP);
      se = smbe;
      break;
      
    case NSLeftMouseDragged:
      sle = new SoLocation2Event;
      se = sle;
      break;
      
    case NSKeyDown:
      se = [self createSoKeyboardEventWithString:[event characters]];
      break;
      
    default:
      NSLog(@"Warning: Unknown event: %d", type);
      break;
  }

  if (se) {
    se->setPosition(SbVec2s((int) q.x, (int) q.y));
    se->setShiftDown(flags & NSShiftKeyMask);
    se->setAltDown(flags & NSAlternateKeyMask);
    se->setCtrlDown(flags & NSControlKeyMask);

    // FIXME: This is not really correct--should rather be the
    // time the event occured. kyrah 20030519
    se->setTime(SbTime::getTimeOfDay());
  }
  return se;
}

/*" Creates an SoKeyboardEvent from an NSString, setting both the key and
    printable character. Note: Currently only the
    first character of s is taken into account.
 "*/
 
- (SoKeyboardEvent *) createSoKeyboardEventWithString:(NSString *)s
{
  unsigned long c = [s characterAtIndex:0];
  void * sokey, * printable;
  SoKeyboardEvent * ke = new SoKeyboardEvent;
  if (keydict->find(c, sokey) && printabledict->find(c, printable)) {
    ke->setKey((SoKeyboardEvent::Key)(int)sokey);
    ke->setPrintableCharacter((char)(int)printable);
  }
  else {
    ke->setKey(SoKeyboardEvent::UNDEFINED);
  }
  return ke;
}


// ------------ Setting the controller component -------------------------


/*" Sets the SCEventConverter's SCController component to controller. "*/

- (void) setController:(SCController *) controller
{
  [controller retain];
  [_controller release];
  _controller = controller;
}

/*" Returns the SCEventConverter's controller component. "*/

- (SCController *) controller
{
  return _controller;
}


@end
