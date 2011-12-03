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

  #{Eventhandler chain}

  The eventhandler has an outlet !{nextEventHandler}, which can be set to
  another SCEventHandler, thus forming a chain of event handlers: If
  an event is not handled by the first event handler, it will be
  passed on to the next one, and so on - until the event has either
  been handled or there are no more eventhandlers in the chain. 

  #{Sc21 eventhandler chain and the Cocoa responder chain}

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
