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
 

#import <Cocoa/Cocoa.h>
#import <Sc21/Sc21.h>
#import <Inventor/actions/SoBoxHighlightRenderAction.h>

/*
  This example demonstrates how to implement a custom Sc21 event
  handler. It also shows you how to emulate the "viewing"
  vs. "picking" concept used in the So@GUI@ libraries (i.e. having two
  separate modes: either handling events in the viewer or sending them
  down the scenegraph).
*/

@interface AppController : NSObject
{
  IBOutlet SCController * coincontroller;
  IBOutlet NSButton * mode;
  SoBoxHighlightRenderAction * ra;
}
- (IBAction)dumpSceneGraph:(id)sender;
- (IBAction)open:(id)sender;
- (IBAction)toggleModes:(id)sender;
- (IBAction)menuToggleModes:(id)sender;
- (IBAction)viewAll:(id)sender;
- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)rc contextInfo:(void *)ctx;
@end
