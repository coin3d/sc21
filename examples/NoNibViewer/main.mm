//
//  main.m
//  NoNibViewer
//
//  Created by Marius Kintel on Mon Jul 14 2003.
//  Copyright (c) 2003 Systems in Motion. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SC21/SCController.h>
#import "AppController.h"

int main(int argc, const char *argv[])
{
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
}
