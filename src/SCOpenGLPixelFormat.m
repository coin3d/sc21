#import "SCOpenGLPixelFormat.h"

@implementation SCOpenGLPixelFormat

- (void)dealloc
{
  [_attrdict release];
  [_nspixelformat release];
  [super dealloc];
}

// Set boolean pixel format attribute
- (void)setAttribute:(NSOpenGLPixelFormatAttribute)attr
{
  if (!_attrdict) _attrdict = [[NSMutableDictionary alloc] init];
  BOOL yes = YES;
  [_attrdict setObject:[NSValue value:&yes withObjCType:@encode(BOOL)] 
             forKey:[NSNumber numberWithInt:attr]];
  [_nspixelformat release];
  _nspixelformat = nil;
}

// Set pixel format attribute to the given value
- (void)setAttribute:(NSOpenGLPixelFormatAttribute)attr toValue:(int)val
{
  if (!_attrdict) _attrdict = [[NSMutableDictionary alloc] init];
  [_attrdict setObject:[NSValue value:&val withObjCType:@encode(int)]
             forKey:[NSNumber numberWithInt:attr]];
  [_nspixelformat release];
  _nspixelformat = nil;
}

// Remove pixel format attribute (i.e. use default value)
- (void)removeAttribute:(NSOpenGLPixelFormatAttribute)attr
{
  if (!_attrdict) _attrdict = [[NSMutableDictionary alloc] init];
  [_attrdict removeObjectForKey:[NSNumber numberWithInt:attr]];
  [_nspixelformat release];
  _nspixelformat = nil;
}

/*!
  Copies the value of the given attribute into the int pointed to by
  valptr. If the attribute is a boolean value the value will be set to 1.
  Returns YES if the attribute exists or NO otherwise.
  On return value of NO, the contents of the valptr is not written.
  NB! This method returns the value previously set with -setAttribute*.
  If you want the real attribute value of the corresponding 
  NSOpenGLPixelFormat, use its -getValues:forAttribute:forVirtualScreen:.
*/
- (BOOL)getValue:(int *)valptr forAttribute:(NSOpenGLPixelFormatAttribute)attr
{
  NSValue * value = [_attrdict objectForKey:[NSNumber numberWithInt:attr]];
  if (!value) return NO;
  if (!strcmp([value objCType], @encode(int))) [value getValue:valptr];
  else *valptr = 1;
  return YES;
}

/*!
  If we have a _attrdict containing any values, create a new
  NSOpenGLPixelFormat based on those values and return it,
  else return nil.

  If a pixelformat has already been created with the current dictionary,
  return this pixelformat.
*/
- (NSOpenGLPixelFormat *)pixelFormat
{
  NSLog(@"SCOpenGLPixelFormat.pixelFormat");
  // FIXME: Have a "valid" flag instead to avoid repeatedly
  // trying to create a pixelformat and fail? (kintel 20040401)
  if (!_nspixelformat && _attrdict && [_attrdict count] > 0) {
    // Create an attribute array from dict
    NSOpenGLPixelFormatAttribute * attrs = 
      malloc([_attrdict count] * 2 * 
             sizeof(NSOpenGLPixelFormatAttribute*) + 1);
    NSEnumerator * keys = [_attrdict keyEnumerator];
    NSNumber * key;
    NSValue * val;
    int intval;
    int i = 0;
    while (key = (NSNumber *)[keys nextObject]) {
      attrs[i++] = [key intValue];
      NSLog(@"Attr: %d", attrs[i-1]);
      val = [_attrdict objectForKey:key];
      NSLog(@"  objctype: %s", [val objCType]);
      if (!strcmp([val objCType], @encode(int))) {
        [val getValue:&intval];
        attrs[i++] = intval;
        NSLog(@"  value: %d", attrs[i-1]);
      }
      else assert(!strcmp([val objCType], @encode(BOOL)));
    }
    attrs[i++] = nil; // nil-terminate
    
    // Create new pixelformat object, copy dict
    if (_nspixelformat = 
        [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs]) {
      NSLog(@"  pixelFormat created");
    }
    free(attrs);
  }
  return _nspixelformat;
}

// NSCoding compliance

- (void)encodeWithCoder:(NSCoder *)coder 
{
  NSLog(@"SCOpenGLPixelFormat.encodeWithCoder");
  if (![coder allowsKeyedCoding]) {
    [coder encodeObject:_attrdict];
  } else {
    NSLog(@"  allowsKeyedCoding");
    [coder encodeObject:_attrdict forKey:@"SC_attrdict"];
  }
}

- (id)initWithCoder:(NSCoder *)coder 
{
  NSLog(@"SCOpenGLPixelFormat.initWithCoder");
  self = [super init];
  if (![coder allowsKeyedCoding]) {
    _attrdict = [[coder decodeObject] retain];
  } else {
    NSLog(@"  allowsKeyedCoding");
    _attrdict = [[coder decodeObjectForKey:@"SC_attrdict"] retain];
  }
  return self;
}

@end
