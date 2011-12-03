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

#import "MyWindowController.h"
#import "MyDocument.h"
#import <Sc21/SCDebug.h>
#import <Inventor/nodes/SoSeparator.h>
#import <Inventor/SoSceneManager.h>

@implementation MyWindowController

- (id)init
{
  NSLog(@"MyWindowController.init");
  if (self = [super initWithWindowNibName:@"MyDocument"]) {

    [[NSNotificationCenter defaultCenter] 
      addObserver:self
      selector:@selector(applicationDidHide:)
      name:NSApplicationDidHideNotification object:nil];    
    
    [[NSNotificationCenter defaultCenter] 
      addObserver:self
      selector:@selector(applicationDidUnhide:)
      name:NSApplicationDidUnhideNotification object:nil];    
  }

  return self;
}

- (void)dealloc
{
  NSLog(@"MyWindowController.dealloc");

  [[NSNotificationCenter defaultCenter] removeObserver:self];

  [super dealloc];
}

- (void)awakeFromNib
{
  NSLog(@"MyWindowController.awakeFromNib");
  [self documentChanged:self];
}

- (void)windowWillLoad
{
  NSLog(@"MyWindowController.windowWillLoad");
}

- (void)windowDidLoad
{
  NSLog(@"MyWindowController.windowDidLoad");
}

- (void)windowDidMiniaturize:(NSNotification *)notif
{
  NSLog(@"MyWindowController.windowDidMiniturize");
  [controller sceneManager]->deactivate();
}

- (void)windowDidDeminiaturize:(NSNotification *)notif
{
  NSLog(@"MyWindowController.windowDidDeminiturize");
  [controller sceneManager]->activate();
}

- (IBAction)viewAll:(id)sender
{
  [[controller sceneGraph] viewAll];
}

- (IBAction)modeButtonClicked:(id)sender
{
  if ([modebutton state] == NSOnState) {
    [controller setEventHandler:coinhandler];
  } else {
    [controller setEventHandler:examinerhandler];
  }
}

- (IBAction)modeMenuSelected:(id)sender
{
  NSLog(@"MyWindowController.modeMenuSelected");
  NSMenuItem *item = sender;
  BOOL viewmode = ([item state] == NSOnState);
  if (viewmode) {
    [controller setEventHandler:examinerhandler];
  } else {
    [controller setEventHandler:coinhandler];
  }
  [modebutton setState:viewmode?NSOffState:NSOnState];
}

- (IBAction)dumpScenegraph:(id)sender
{
  NSLog(@"MyWindowController.dumpScenegraph");
  [SCDebug dumpSceneGraph:[controller sceneManager]->getSceneGraph()];
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
  // Set checkmark for "Pick Mode" menu item
  if ([item tag] == 901) {
    [item setState:[modebutton state]];
  }
  return YES;
}

- (IBAction)showDebugInfo:(id)sender
{
  NSString *info = [SCDebug openGLInfo];
  NSWindow *panel = NSGetInformationalAlertPanel(@"Debug info",
                                                 info, @"Dismiss", nil, nil );
  [NSApp runModalForWindow:panel];
  [panel close];
  NSReleaseAlertPanel(panel);
}

- (IBAction)documentChanged:(id)sender
{
  MyDocument *doc = [self document];
  [controller setSceneGraph:[doc sceneGraph]];
  [[controller sceneGraph] viewAll];

  [typetext setStringValue:[doc fileType]];
  [sizetext setStringValue:[doc fileSize]];
}

- (void)applicationDidHide:(NSNotification *)notif
{
  NSLog(@"MyWindowController.applicationDidHide");
  [controller sceneManager]->deactivate();
}

- (void)applicationDidUnhide:(NSNotification *)notif
{
  NSLog(@"MyWindowController.applicationDidUnhide");
  if (![[self window] isMiniaturized]) {
    [controller sceneManager]->activate();
  }
}

@end
