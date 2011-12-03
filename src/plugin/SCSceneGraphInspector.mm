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
 
#import "SCSceneGraphInspector.h"
#import <Sc21/SCSceneGraph.h>
#import "SCSceneGraphP.h"
#import "SCUtil.h"

@implementation SCSceneGraphInspector

- (NSString *)viewNibName {
	return @"SCSceneGraphInspector";
}

- (void)ok:(id)sender
{
  SC21_DEBUG(@"SCSceneGraphInspector.ok:");
  SCSceneGraph * scscenegraph = [[self inspectedObjects] lastObject];
  
  // Undo support
//  [self beginUndoGrouping];
//  [self noteAttributesWillChangeForObject:scscenegraph];
  
  [scscenegraph _SC_setCreatesSuperSceneGraph:([createsuperscenegraph state] == NSOnState)];
}

- (void)refresh
{
  SC21_DEBUG(@"SCSceneGraphInspector.refresh");
  SCSceneGraph * scscenegraph = [[self inspectedObjects] lastObject];
  [createsuperscenegraph setState:
    ([scscenegraph _SC_createsSuperSceneGraph] ? NSOnState:NSOffState)];
  [super refresh];
}

@end

// Undo support workaround:
// IB wants a standard accessor method - it does not accept our _SC_xxx one.
// FIXME: Maybe there's a way to tell IB what accessor to use? Investigate.
// kyrah 20040827

@interface SCSceneGraph (UndoSupport)
- (void)setCreatesSuperSceneGraph:(BOOL)yn;
- (BOOL)createsSuperSceneGraph;
@end

@implementation SCSceneGraph (UndoSupport)
- (void)setCreatesSuperSceneGraph:(BOOL)yn
{
  [self _SC_setCreatesSuperSceneGraph:yn]; 
}

- (BOOL)createsSuperSceneGraph
{
  return [self _SC_createsSuperSceneGraph];
}
@end
