/* ============================================================== *
 |                                                                |
 | This file is part of SC21, a Cocoa user interface binding for  |
 | the Coin 3D visualization library.                             |
 |                                                                |
 | Copyright (c) 2003 Systems in Motion. All rights reserved.     |
 |                                                                |
 | SC21 is free software; you can redistribute it and/or          |
 | modify it under the terms of the GNU General Public License    |
 | ("GPL") version 2 as published by the Free Software            |
 | Foundation.                                                    |
 |                                                                |
 | A copy of the GNU General Public License can be found in the   |
 | source distribution of SC21. You can also read it online at    |
 | http://www.gnu.org/licenses/gpl.txt.                           |
 |                                                                |
 | For using Coin with software that can not be combined with the |
 | GNU GPL, and for taking advantage of the additional benefits   |
 | of our support services, please contact Systems in Motion      |
 | about acquiring a Coin Professional Edition License.           |
 |                                                                |
 | See http://www.coin3d.org/mac/SC21 for more information.       |
 |                                                                |
 | Systems in Motion, Bygdoy Alle 5, 0257 Oslo, Norway.           |
 |                                                                |
 * ============================================================== */
 

#import <SC21/SCEventConverter.h>
#import <SC21/SCController.h>
#import <SC21/SCView.h>

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
  // Now it gets really ugly :( -- the original OpenInventor
  // never considered the concept of having non-US keyboards.
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

/*" An SCEventConvert converts native Cocoa events (NSEvents) into Coin
    events (SoEvents).
 "*/


// ---------------- Initialisation and cleanup -------------------------

/*" Initializes a newly allocated SCEventConverter. 

    This method is the designated initializer for the SCEventConverter
    class. Returns !{self}.
 "*/

- (id) initWithController:(SCController *)controller
{
  if (self = [super init]) {
    _controller = controller;
    _keydict = new SbDict;
    _printabledict = new SbDict;
    int i=0;
    while (KeyMap[i].nsvalue != 0) {
      _keydict->enter((unsigned long)KeyMap[i].nsvalue,
                     (void *)KeyMap[i].sovalue);
      _printabledict->enter((unsigned long)KeyMap[i].nsvalue,
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
  delete _keydict;
  delete _printabledict;
  [super dealloc];
}


// ------------------ Event conversion ---------------------------


/*" Creates an SoEvent from the NSEvent event, setting the mouse button and
    mouse state (for mouse events) or key information (for keyboard events), and
     position, modifier keys, and time when the event occurred.
  "*/
  
- (SoEvent *) createSoEvent:(NSEvent *)event
{
  NSPoint q = [[_controller view] convertPoint:[event locationInWindow] fromView:nil];
  unsigned int flags = [event modifierFlags];
  NSEventType type = [event type];
  SoEvent * se = NULL;
  SoMouseButtonEvent * smbe = NULL;
  SoLocation2Event* sle = NULL;
  float delta;

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
    
  case NSRightMouseDown:
    smbe = new SoMouseButtonEvent;
    smbe->setButton(SoMouseButtonEvent::BUTTON2);
    smbe->setState(SoButtonEvent::DOWN);
    se = smbe;
    break;
    
  case NSRightMouseUp:
    smbe = new SoMouseButtonEvent;
    smbe->setButton(SoMouseButtonEvent::BUTTON2);
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
  case NSRightMouseDragged:
  case NSOtherMouseDragged:
    sle = new SoLocation2Event;
    se = sle;
    break;
    
  case NSScrollWheel:
    delta = [event deltaY];
    if (delta == 0.0f) break; // some other scroll wheel axis -> ignore
    smbe = new SoMouseButtonEvent;
    if (delta > 0) smbe->setButton(SoMouseButtonEvent::BUTTON4);
    else smbe->setButton(SoMouseButtonEvent::BUTTON5);
    smbe->setState(SoButtonEvent::DOWN); // wheel gives only DOWN events
    se = smbe;
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
  if (_keydict->find(c, sokey) && _printabledict->find(c, printable)) {
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

- (void) setController:(SCController *)controller
{
  // We intentionally do not retain controller here, to avoid
  // circular references.
  _controller = controller;
}

/*" Returns the SCEventConverter's controller component. "*/

- (SCController *) controller
{
  return _controller;
}

@end
