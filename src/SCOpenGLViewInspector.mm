/* ============================================================== *
 |                                                                |
 | This file is part of SC21, a Cocoa user interface binding for  |
 | the Coin 3D visualization library.                             |
 |                                                                |
 | Copyright (c) 2003 Systems in Motion. All rights reserved.     |
 |                                                                |
 | SC21 is free software; you can redistribute it and/or          |
 | modify it under the terms of the GNU General Public License    |
 | ("GPL") version 2 as published by the Free Software            |
 | Foundation.                                                    |
 |                                                                |
 | A copy of the GNU General Public License can be found in the   |
 | source distribution of SC21. You can also read it online at    |
 | http://www.gnu.org/licenses/gpl.txt.                           |
 |                                                                |
 | For using Coin with software that can not be combined with the |
 | GNU GPL, and for taking advantage of the additional benefits   |
 | of our support services, please contact Systems in Motion      |
 | about acquiring a Coin Professional Edition License.           |
 |                                                                |
 | See http://www.coin3d.org/mac/SC21 for more information.       |
 |                                                                |
 | Systems in Motion, Bygdoy Alle 5, 0257 Oslo, Norway.           |
 |                                                                |
 * ============================================================== */
 

#import "SC21Inspector.h"
#import <SC21/SCOpenGLView.h>

@implementation SC21Inspector

- (id)init
{
  NSLog(@"SC21Inspector.init");
  self = [super init];
  BOOL ok = [NSBundle loadNibNamed:@"SC21Inspector" owner:self];
  if (ok == NO) NSLog(@"SC21Inspector.init: Failed loading nib");
  //FIXME: Return nil on error? (kintel 20030324)
  return self;
}

- (void)ok:(id)sender
{
  NSLog(@"SC21Inspector.ok:");
  SCOpenGLView *scview = [self object];

#if 0
  NSMutableDictionary *dict;
  [dict setObject:[NSNumber numberWithBool:YES] forKey:[NSNumber numberWithInt:NSOpenGLPFADoubleBuffer]];

  switch ([coloralpha indexOfSelectedItem]) {
  case 1:
    NSOpenGLPFAColorSize = 5;
    NSOpenGLPFAAlphaSize = 0;
  break;
  case 2:
    NSOpenGLPFAColorSize = 5;
    NSOpenGLPFAAlphaSize = 1;
    break;
  case 3:
    NSOpenGLPFAColorSize = 5;
    NSOpenGLPFAAlphaSize = 8;
    break;
  case 4:
    NSOpenGLPFAColorSize = 8;
    NSOpenGLPFAAlphaSize = 0;
    break;
  case 5:
    NSOpenGLPFAColorSize = 8;
    NSOpenGLPFAAlphaSize = 8;
    break;
  default:
    //Remove color&alpha hints
    break;
  }

  switch ([depth indexOfSelectedItem]) {
  case 0:
    none;
    break;
  case 1:
    min;
    break;
  case 2:
    16;
    break;
  case 3:
    24;
    break;
  case 4:
    32;
    break;
  case 5:
    max;
    break;
  }

  switch ([stencil indexOfSelectedItem]) {
  case 0:
    none;
    break;
  case 1:
    min;
    break;
  case 2:
    8;
    break;
  case 3:
    16;
    break;
  case 4:
    max;
    break;
  }

  switch ([accum indexOfSelectedItem]) {
  case 0:
    none;
    break;
  case 1:
    888;
    break;
  case 2:
    8888;
    break;
  case 3:
    16x3 rgb;
    break;
  case 4:
    16x4 rgb;
    break;
  }

  NSOpenGLPFAAccelerated;
  NSOpenGLPFAColorSize;
  NSOpenGLPFAAlphaSize;
  NSOpenGLPFADepthSize;
  NSOpenGLPFAStencilSize;
  NSOpenGLPFAAccumSize;
#endif

  [super ok:sender];
}

- (void)revert:(id)sender
{
  NSLog(@"SC21Inspector.revert:");
  
  [super revert:sender];
}

@end
