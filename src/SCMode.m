/* =============================================================== *
 |                                                                 |
 | This file is part of Sc21, a Cocoa user interface binding for   |
 | the Coin 3D visualization library.                              |
 |                                                                 |
 | Copyright (c) 2003-2009 Kongsberg SIM AS . All rights reserved. |
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
 | of our support services, please contact Kongsberg SIM AS        |
 | about acquiring a Coin Professional Edition License.            |
 |                                                                 |
 | See http://www.coin3d.org/mac/Sc21 for more information.        |
 |                                                                 |
 | Kongsberg SIM AS , Bygdoy Alle 5, 0257 Oslo, Norway.            |
 |                                                                 |
 * =============================================================== */

#import "SCMode.h"
#import "SCUtil.h"

@implementation SCMode

- (BOOL)isActive
{
  return active;
}

- (void)activate
{
  SC21_LOG_METHOD;
  active = YES;
}

- (void)activate:(NSEvent *)event point:(NSPoint *)point camera:(SCCamera *)camera
{
  [self activate];
}

- (void)deactivate
{
  SC21_LOG_METHOD;
  active = NO;
}

- (NSCursor *)cursor
{
  SC21_LOG_METHOD;
  return nil;
}

- (id)valueForEvent:(NSEvent *)event
{
  return nil;
}

- (BOOL)modifyCamera:(SCCamera *)camera withValue:(id)value
{
  SC21_LOG_METHOD;
  return NO; 
}

- (void)modifyCamera:(SCCamera *)camera withTimeInterval:(NSTimeInterval)currtime
{
  SC21_LOG_METHOD;
}
@end
