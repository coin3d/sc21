/* =============================================================== *
 |                                                                 |
 | This file is part of Sc21, a Cocoa user interface binding for   |
 | the Coin 3D visualization library.                              |
 |                                                                 |
 | Copyright (c) 2003-2004 Systems in Motion. All rights reserved. |
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

#import "SCTimer.h"

@implementation NSTimer (SCTimer)

/*" 
  Provide interface for deaction of NSTimer instance.
  
  Note: We deactivate the timer by setting its fireDate to
  "distantFuture" (cf. NSDate). IMNSHO, it is quite stupid that it is
  not possible to activate and deactive NSTimers, but my radar
  enhancement request was declined *shrug*. kyrah 20040910. 
"*/


/*" 
  Deactiates the receiver.
"*/

- (void)_SC_deactivate
{
  [self setFireDate:[NSDate distantFuture]];
}


/*" 
  Return YES if the receiver is active, NO otherwise.
"*/

- (BOOL)_SC_isActive
{
  // A timer is "active" if its fire date is less than 100000 seconds from now.
  // Note that we cannot compare for "== distantFuture" here, since
  // distantFuture is "current time + a high number" (i.e. the actual 
  // date changes with time)
  
  return ([self fireDate] < [NSDate dateWithTimeIntervalSinceNow:100000]);
}

@end