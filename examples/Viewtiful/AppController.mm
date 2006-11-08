/* =============================================================== *
 |                                                                 |
 | This file is part of Sc21, a Cocoa user interface binding for   |
 | the Coin 3D visualization library.                              |
 |                                                                 |
 | Copyright (c) 2003-2006 Systems in Motion. All rights reserved. |
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
