#import "SCOpenGLPixelFormat.h"

@interface SCOpenGLPixelFormat(InternalAPI)
- (id)initWithDict;
@end

@implementation SCOpenGLPixelFormat

- (void)dealloc
{
  [_attrDict release];
  [super dealloc];
}

// Set boolean pixel format attribute
- (void)setAttribute:(NSOpenGLPixelFormatAttribute)attr
{
  if (!_attrDict) _attrDict = [[NSMutableDictionary alloc] init];
  [_attrDict setObject:[NSValue value:1 WithObjCType:@encode(BOOL)] 
	    forKey:[NSNumber numberWithInt:attr]];
}

// Set pixel format attribute to the given value
- (void)setAttribute:(NSOpenGLPixelFormatAttribute)attr toValue:(int)val
{
  if (!_attrDict) _attrDict = [[NSMutableDictionary alloc] init];
  [_attrDict setObject:[NSValue value:val WithObjCType:@encode(int)] 
                forKey:[NSNumber numberWithInt:attr]];
}

// Remove pixel format attribute (i.e. use default value)
- (void)removeAttribute:(NSOpenGLPixelFormatAttribute)attr
{
  if (!_attrDict) _attrDict = [[NSMutableDictionary alloc] init];
  [_attrDict removeObjectForKey:[NSNumber numberWithInt:attr]];
}

// Copies the value of the given attribute into the int pointed to by
// valptr. If the attribute is a boolean value the value will be set to 1.
// Returns YES if the attribute exists or NO otherwise.
// On return value of NO, the contents of the valptr is not written.
// NB! This doesn't return the real attribute value, but the
// value previously set with setAttribute:
// For the real value, use getValues:forAttribute:forVirtualScreen:
- (BOOL)getValue:(int *)valptr forAttribute:(NSOpenGLPixelFormatAttribute)attr
{
  NSValue *value = [_attrDict objectForKey:[NSNumber numberWithInt:attr]];
  int val;
  if (!value) return NO;
  if ([value objCType] == @encode(int)) [value getValue:&valptr];
  else *valptr = 1;
  return YES;
}

// Reinitialize using settings provided earlier.
// If settings don't result in a valid pixel format,
// return self, else return the new instance.
// NB! The return value of this method must be assigned to
// self, just as with any other init method.
- (id)reinit
{
  id newformat = [self initWithDict];
  if (newformat) {
    [self autorelease];
    return [newformat retain];
  }
  return self;
}

// NSCoding compliance

- (void)encodeWithCoder:(NSCoder *)coder 
{
  [super encodeWithCoder:coder];
  if (![coder allowsKeyedCoding]) {
    [coder encodeObject:_attrDict];
  } else {
    [coder encodeObject:_attrDict forKey:@"NSMutableDictionary"];
  }
}

- (id)initWithCoder:(NSCoder *)coder 
{
  if (self = [super initWithCoder:coder]) {
    if (![coder allowsKeyedCoding]) {
      _attrDict = [[coder decodeObject] retain];
    } else {
      _attrDict = [[coder decodeObjectForKey:@"NSMutableDictionary"] retain];
    }
    self = [self reinit];
  }
  return self;
}

// ----------------------- InternalAPI -------------------------

/*!
  If we have a _attrDict containing any values, create a new
  SCOpenGLPixelFormat based on those values, copy _attrDict into it
  and return it.
  Else return nil
*/
- (id)initWithDict
{
  SCOpenGLPixelFormat *pixelFormat = nil;
  if (_attrDict && [_attrDict count] > 0) {
    // Create an attribute array from dict
    NSOpenGLPixelFormatAttribute *attrs = 
      malloc([_attrDict count] * 2 * sizeof(NSOpenGLPixelFormatAttribute*) + 1);
    NSEnumerator *keys = [_attrDict keyEnumerator];
    NSNumber *key;
    NSValue *value;
    NSOpenGLPixelFormatAttribute val;
    int i = 0;
    while (key = (NSNumber *)[keys nextObject]) {
      attrs[i++] = [key intValue];
      value = [_attrDict objectForKey:key];
      if ([value objCType] == @encode(int)) {
        [value getValue:&val];
        attrs[i++] = val;
      }
    }
    attrs[i++] = (NSOpenGLPixelFormatAttribute)nil; // nil-terminate

    // Create new pixelformat object, copy dict
    if (pixelFormat = [[SCOpenGLPixelFormat alloc] initWithAttributes:attrs]) {
      pixelFormat->_attrDict = [_attrDict mutableCopy];
      [pixelFormat autorelease];
    }
    free(attrs);
  }
  return pixelFormat;
}

@end
