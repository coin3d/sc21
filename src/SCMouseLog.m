/* =============================================================== *
 |                                                                 |
 | This file is part of Sc21, a Cocoa user interface binding for   |
 | the Coin 3D visualization library.                              |
 |                                                                 |
 | Copyright (c) 2003-2005 Systems in Motion. All rights reserved. |
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

#import "SCMouseLog.h"

@implementation SCMouseLog

+ (SCMouseLog *)defaultMouseLog
{
  static SCMouseLog * mouselog = nil;

  if (!mouselog) {
    mouselog = [[SCMouseLog alloc] init];
  }
  return mouselog;
}

- (void)clear
{
  _curridx = 0;
  _age = 0;
}

- (void)setStartPoint:(NSPoint *)point timestamp:(NSTimeInterval)timestamp
{
  _startpos = _pos[0] = *point;
  _starttime = _time[0] = timestamp;
  _curridx = 0;
  _age = 1;
}

- (NSPoint *)startPoint
{
  if (_age > 0) return &_startpos;
  return NULL;
}

- (NSTimeInterval)startTime
{
  if (_age > 0) return _starttime;
  return -1;
}

- (void)appendPoint:(NSPoint *)point timestamp:(NSTimeInterval)timestamp
{
  _curridx = (_curridx + 1)%5;
  _pos[_curridx] = *point;
  _time[_curridx] = timestamp;
  if (_age < 5) _age++;
}

- (unsigned int)numPoints
{
  return _age;
}

- (NSPoint *)point:(unsigned int)age
{
  if (_age > 0) {
    if (age > 4) age = 4;
    return &_pos[(_curridx + 5 - age)%5];
  }
  return NULL;
}

- (NSTimeInterval)timestamp:(unsigned int)age
{
  if (_age > 0) {
    if (age > 4) age = 4;
    return _time[(_curridx + 5 - age)%5];
  }
  return -1;
}

@end
