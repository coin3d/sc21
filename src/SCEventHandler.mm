/* =============================================================== *
 |                                                                 |
 | This file is part of Sc21, a Cocoa user interface binding for   |
 | the Coin 3D visualization library.                              |
 |                                                                 |
 | Copyright (c) 2003-2004 Systems in Motion. All rights reserved. |
 |                                                                 |
 | Sc21 is free software; you can redistribute it and/or           |
 | modify it under the terms of the GNU General Public License     |
 | ("GPL") version 2 as published by the Free Software             |
 | Foundation.                                                     |
 |                                                                 |
 | A copy of the GNU General Public License can be found in the    |
 | source distribution of Sc21. You can also read it online at     |
 | http://www.gnu.org/licenses/gpl.txt.                            |
 |                                                                 |
 | For using Coin with software that can not be combined with the  |
 | GNU GPL, and for taking advantage of the additional benefits    |
 | of our support services, please contact Systems in Motion       |
 | about acquiring a Coin Professional Edition License.            |
 |                                                                 |
 | See http://www.coin3d.org/mac/Sc21 for more information.        |
 |                                                                 |
 | Systems in Motion, Bygdoy Alle 5, 0257 Oslo, Norway.            |
 |                                                                 |
 * =============================================================== */

#import <Sc21/SCEventHandler.h>
#import <Sc21/SCController.h>
#import "SCEventHandlerP.h"

@implementation SCEventHandlerP
@end

#define PRIVATE(p) ((p)->_sc_eventhandler)
#define SELF PRIVATE(self)

@implementation SCEventHandler

/*" 

  SCEventHandler is the superclass for Sc21 eventhandlers. It takes
  care of managing the eventhandler chain. When writing your own
  eventhandler, it should be derived from this class and override
  !{controller:handleEvent:} (and potentially !{update:}).

  #{Sc21 eventhandling overview}

  The Sc21 eventhandling system takes a different approach than
  Cocoa. In Cocoa, events are handled in the view - so to do your own
  eventhandling, you have to subclass NSView and override a method for
  each event type you are interested in (!{mouseUp:},
  !{rightMouseDown:} etc). In Sc21, events received by the SCView are
  passed on to the SCController. SCController in turn passes them on
  to its SCEventHandler, who finally handles them. 

  #{Eventhandler Chain}

  The eventhandler has an outlet !{nextEventHandler}, which can be set to
  another SCEventHandler, thus forming a chain of event handlers: If
  an event is not handled by the first event handler, it will be
  passed on to the next one, and so on - until the event has either
  been handled or there are no more eventhandlers in the chain. 

  #{Sc21 eventhandler Chain and the Cocoa responder chain}

  If an event was not handled by the Sc21 eventhandler chain, it is
  sent back to NSView, and thus passed on to Cocoa's responder chain.
  To prevent unhandled events from being sent down the Cocoa responder
  chain, subclass SCEventHandler and implement
  !{controller:handleEvent:} to just return !{YES} in all cases. Then
  place this eventhandler at the end of your eventhandler chain.

"*/


- (id)init
{
  if (self = [super init]) {
  }
  return self;
}

/*" 
  Sets the next eventhandler in the eventhandler chain to nexthandler. 

  Usually you do not need to override this method.
"*/

- (void)setNextEventHandler:(SCEventHandler *)nexthandler
{
  self->nextEventHandler = nexthandler;
}

/*" 
  Returns the next eventhandler in the eventhandler chain. 

  Usually you do not need to override this method.
"*/

- (SCEventHandler *)nextEventHandler
{
  return self->nextEventHandler;
}

/*" 
  Handle the NSEvent event. The controller argument is sent to allow
  subclasses to access the current camera, scenegraph, etc.

  The default implementation does nothing and returns NO.
 "*/

- (BOOL)controller:(SCController *)controller handleEvent:(NSEvent *)event
{
  return NO;
}

/*" 
  Post-render callback that allows you to do continuous animation
  (such as needed when simulating a fly mode). 

  The default implementation does nothing and returns NO.
"*/
- (void)update:(SCController *)controller
{
}

@end
