/**************************************************************************\
 * Copyright (c) Kongsberg Oil & Gas Technologies AS
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * 
 * Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 * 
 * Neither the name of the copyright holder nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
\**************************************************************************/

#import <Sc21/SCEventConverter.h>
#import "SCUtil.h"

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

#pragma mark --- initialization and cleanup ---

/*" Initializes a newly allocated SCEventConverter. 

    This method is the designated initializer for the SCEventConverter
    class. Returns !{self}.
 "*/

- (id)init
{
  if (self = [super init]) {
    int numitems = sizeof(KeyMap)/sizeof(key1map);
    NSMutableArray *keyarray = [NSMutableArray arrayWithCapacity:numitems];
    NSMutableArray *soarray = [NSMutableArray arrayWithCapacity:numitems];
    NSMutableArray *printablearray = [NSMutableArray arrayWithCapacity:numitems];
    int i = 0;
    while (KeyMap[i].nsvalue != 0) {
      [keyarray addObject:[NSNumber numberWithChar:KeyMap[i].nsvalue]];
      [soarray addObject:[NSNumber numberWithInt:KeyMap[i].sovalue]];
      [printablearray addObject:[NSNumber numberWithChar:KeyMap[i].printable]];
      i++;
    }
    sodict = [[NSDictionary dictionaryWithObjects:soarray forKeys:keyarray] retain];
    printabledict = [[NSDictionary dictionaryWithObjects:printablearray forKeys:keyarray] retain];
  }
  return self;
}

/* Clean up after ourselves. */
- (void)dealloc
{
  [sodict release];
  [printabledict release];
  [super dealloc];
}

#pragma mark --- event conversion ---

/*"
  Creates an SoEvent from the NSEvent event, setting the mouse button and
  mouse state (for mouse events) or key information (for keyboard events), and
  position, modifier keys, and time when the event occurred.
  
  view should be set to nil for fullscreen rendering.
  "*/
  
- (SoEvent *)createSoEvent:(NSEvent *)event inDrawable:(id<SCDrawable>)drawable
{
  NSPoint q = [event locationInWindow];

  if ([drawable isKindOfClass:[NSView class]]) {
    q = [((NSView *)drawable) convertPoint:q fromView:nil];
  }
  else {
    NSRect frame = [drawable frame];
    q.x -= frame.origin.x;
    q.y -= frame.origin.y;
  }

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
    SC21_DEBUG(@"SCEventConverter.createSoEvent:inDrawable: Unknown event type: %d", type);
    break;
  }

  if (se) {
    se->setPosition(SbVec2s((int)q.x, (int)q.y));
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
 
- (SoKeyboardEvent *)createSoKeyboardEventWithString:(NSString *)s
{
  unsigned long c = [s characterAtIndex:0];
  SoKeyboardEvent * ke = new SoKeyboardEvent;
  NSNumber * key = [NSNumber numberWithChar:c];
  NSNumber * sokey = [sodict objectForKey:key];
  NSNumber * printable = [printabledict objectForKey:key];
  if (sokey && printable) {
    ke->setKey((SoKeyboardEvent::Key)[sokey intValue]);
    ke->setPrintableCharacter([printable charValue]);
  }
  else {
    ke->setKey(SoKeyboardEvent::UNDEFINED);
  }
  return ke;
}

@end
