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
