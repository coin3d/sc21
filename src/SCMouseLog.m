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
