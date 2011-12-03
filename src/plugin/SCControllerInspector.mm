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
 

#import "SCControllerInspector.h"
#import <Sc21/SCController.h>
#import "SCUtil.h"

@implementation SCControllerInspector

- (NSString *)viewNibName {
	return @"SCControllerInspector";
}

// FIXME: Figure out where this actually ends up. kintel 20090326.
//- (NSString *)label {
//	return @"SCControllerInspector";
//}

- (void)ok:(id)sender
{
  SC21_DEBUG(@"SCControllerInspector.ok:");
  SCController *sccontroller = [[self inspectedObjects] lastObject];
  
  // Undo support
//  [self beginUndoGrouping];
 // [self noteAttributesWillChangeForObject:sccontroller];
  
  [sccontroller setClearsColorBuffer:([clearcolorbuffer state] == NSOnState)];
  [sccontroller setClearsDepthBuffer:([cleardepthbuffer state] == NSOnState)];
}

- (void)refresh
{
  SC21_DEBUG(@"SCControllerInspector.revert:");
  SCController *sccontroller = [[self inspectedObjects] lastObject];
  
  [clearcolorbuffer 
   setState:([sccontroller clearsColorBuffer] ? NSOnState : NSOffState)];
  [cleardepthbuffer 
   setState:([sccontroller clearsDepthBuffer] ? NSOnState : NSOffState)];
  
  [super refresh];
}

@end
