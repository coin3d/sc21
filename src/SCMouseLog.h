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

#import <Cocoa/Cocoa.h>

@interface SCMouseLog : NSObject
{
  NSPoint _startpos;
  NSTimeInterval _starttime;
  NSPoint _pos[5];
  NSTimeInterval _time[5];
  unsigned int _curridx;
  unsigned int _age;
}

+ (SCMouseLog *)defaultMouseLog;
- (void)clear;
- (void)setStartPoint:(NSPoint *)point timestamp:(NSTimeInterval)timestamp;
- (NSPoint *)startPoint;
- (NSTimeInterval)startTime;
- (void)appendPoint:(NSPoint *)point timestamp:(NSTimeInterval)timestamp;
- (unsigned int)numPoints;
- (NSPoint *)point:(unsigned int)age;
- (NSTimeInterval)timestamp:(unsigned int)age;

@end
