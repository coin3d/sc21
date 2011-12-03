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

#import "AppController.h"
#import "MyDocument.h"

@implementation AppController

// NSApplication delegate methods

- (BOOL)application:(NSApplication *)app openFile:(NSString *)filename
{
    if ([[NSDocumentController sharedDocumentController] 
        openDocumentWithContentsOfFile:filename display:YES]) {
        return YES;
    } else { 
      return NO;
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
  SEL action = [item action];
  // Enable "New From Pasteboard" only if pasteboard data is available
  if (action == @selector(newDocument:)) {
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    return ([pb availableTypeFromArray:[NSArray arrayWithObject:@"VRML1PboardType"]] != nil);
  }
  else return [super validateMenuItem:item];
}

// Enable the Services menu items we can use

- (id)validRequestorForSendType:(NSString *)sendType 
                     returnType:(NSString *)returnType
{
  BOOL return_ok = NO, send_ok = NO;

  if (!sendType || [sendType isEqualToString:@"VRML1PboardType"]) 
    send_ok = YES;

  if (!returnType || [returnType isEqualToString:@"VRML1PboardType"]) 
    return_ok = YES;

  if (send_ok && return_ok) return self;
  return nil;
}

- (BOOL)writeSelectionToPasteboard:(NSPasteboard *)pb types:(NSArray *)types
{
  return NO;
}

- (BOOL)readSelectionFromPasteboard:(NSPasteboard *)pb
{
  return [self newDocumentFromPasteboard:pb];
}

- (BOOL)newDocumentFromPasteboard:(NSPasteboard *)pb
{
  NSData *data = [pb dataForType:@"VRML1PboardType"];
  if (data) {
    MyDocument *doc = [[[MyDocument alloc] init] autorelease];
    if ([doc loadDataRepresentation:data ofType:@"VRML"]) {
      NSLog(@"loadDataRepresentation OK");
    }
    [doc makeWindowControllers];
    NSDocumentController *dc = [NSDocumentController sharedDocumentController];
    [dc addDocument:doc];
    [doc showWindows];
    return YES;
  }
  return NO;
 
  // FIXME: The code below doesn't work: openUntitled... returns nil. Why? 
  // (kintel 20030814)
  //  MyDocument *doc = [dc openUntitledDocumentOfType:@"MyDocument" display:YES];
  //  if ([doc loadDataRepresentation:data ofType:@"VRML"]) {
  //    NSLog(@"loadDataRepresentation OK");
  //  }
}

- (IBAction)newDocument:(id)sender
{
  NSLog(@"AppController.newDocument");
  NSPasteboard *pb = [NSPasteboard generalPasteboard];
  [self newDocumentFromPasteboard:pb];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notif
{
  NSLog(@"AppController.applicationDidFinishLaunching");
  NSArray * sendtypes = [NSArray arrayWithObject:@"VRML1PboardType"];
  NSArray * returntypes = [NSArray arrayWithObject:@"VRML1PboardType"];
  [NSApp registerServicesMenuSendTypes:sendtypes returnTypes:returntypes];
  
  // FIXME: Added since we want to connect this to a non-standard selector and
  // IB doesn't let us do this (kintel 20030814)
  [refreshItem setTarget:nil];
  [refreshItem setAction:@selector(refreshDocument:)];
}

@end
