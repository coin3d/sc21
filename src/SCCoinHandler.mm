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

#import <Sc21/SCCoinHandler.h>
#import <Sc21/SCController.h>

#import "SCCoinHandlerP.h"
#import "SCEventConverter.h"
#import "SCUtil.h"

#import <Inventor/SoSceneManager.h>

@implementation SCCoinHandlerP
@end


#define SELF self->_sc_coinhandler


@implementation SCCoinHandler

/*" 
  An SCCoinHandler takes incoming NSEvents, converts them to SoEvents,
  and sends them to the Coin scenegraph. 

  SCCoinHandler does not override the !{update:} method (i.e. it
  inherits SCEventHandler's default implementation, which does
  nothing.)
"*/

- (id)init
{
  if (self = [super init]) {
    [self _SC_commonInit];
  }
  return self;
}


- (void)dealloc
{
  [SELF->eventconverter release];
  [SELF release];
  [super dealloc];
}


/*" 
  Converts the NSEvent event to an SoEvent and sends it to the Coin
  scenegraph by calling the SoSceneManager's !{processEvent()} method.

  Returns !{YES} if event has been handled, !{NO} otherwise.
"*/

- (BOOL)controller:(SCController *)controller handleEvent:(NSEvent *)event
{
  SC21_DEBUG(@"SCCoinHandler.controller:handleEvent:");
  BOOL handled = NO;
  SoEvent * se = [SELF->eventconverter createSoEvent:event 
                      inDrawable:[controller drawable]];
  if (se) {
    handled = [controller sceneManager]->processEvent(se);
    delete se;
  }
  return handled;
}


#pragma mark --- NSCoding conformance ---

- (void)encodeWithCoder:(NSCoder *)coder
{
}


- (id)initWithCoder:(NSCoder *)coder
{
  if (self = [super init]) {
    [self _SC_commonInit];
  }
  return self;
}

@end


@implementation SCCoinHandler (InternalAPI)

- (void)_SC_commonInit
{
  SELF = [[SCCoinHandlerP alloc] init];
  SELF->eventconverter = [[SCEventConverter alloc] init];
}

@end
