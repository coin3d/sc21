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
