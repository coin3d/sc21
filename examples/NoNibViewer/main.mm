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
#import <Sc21/SCController.h>
#import "AppController.h"

// For some reason, the setAppleMenu: is AWOL in Mac OS 10.4,
// but it has not been officially dropped, and NSApplication still
// responds to the message. 

@interface NSApplication(NSAppleMenu)
- (void)setAppleMenu:(NSMenu *)menu;
@end

int main(int argc, const char *argv[])
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  [SCController initCoin];
  [NSApplication sharedApplication];

  AppController * ctrl = [[AppController alloc] init];
  [NSApp setDelegate:ctrl];

  NSMenu * mainmenu = [[NSMenu allocWithZone:[NSMenu menuZone]] 
                        initWithTitle:@"MainMenu"];
  
  NSMenuItem * applemenuitem = [[NSMenuItem allocWithZone:[NSMenu menuZone]] 
                                initWithTitle:@"NoNibViewer" 
                                action:nil
                                keyEquivalent:@""];
  NSMenu * applemenu = [[NSMenu allocWithZone:[NSMenu menuZone]] 
                         initWithTitle:@"NoNibViewer"];
  
  [applemenu addItem:[[NSMenuItem allocWithZone:[NSMenu menuZone]] 
                       initWithTitle:@"Quit" 
                       action:@selector(terminate:) 
                       keyEquivalent:@"q"]];
  
  [applemenuitem setSubmenu:applemenu];
  [mainmenu addItem:applemenuitem];
  
  [NSApp setAppleMenu:applemenu];
  [NSApp setMainMenu:mainmenu];

  [NSApp run];
  [ctrl release];
  [pool release];
}
