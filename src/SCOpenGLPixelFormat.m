#import <SC21/SCOpenGLPixelFormat.h>

@implementation SCOpenGLPixelFormat

/*"
  FIXME: write doc
  "*/

/*!
  FIXME: write doc
*/
- (void)dealloc
{
  [_attrdict release];
  [_nspixelformat release];
  [super dealloc];
}

/*"
  Sets the boolean pixel format attribute.

  As with #NSOpenGLPixelFormat, the existence of a boolean attribute
  implies a YES value.
  To set a boolean attribute to NO, use #removeAttribute:

  FIXME:/sa setAttribute:toValue:
"*/
- (void)setAttribute:(NSOpenGLPixelFormatAttribute)attr
{
  if (!_attrdict) _attrdict = [[NSMutableDictionary alloc] init];
  BOOL yes = YES;
  [_attrdict setObject:[NSValue value:&yes withObjCType:@encode(BOOL)] 
             forKey:[NSNumber numberWithInt:attr]];
  [_nspixelformat release];
  _nspixelformat = nil;
}

/*"
  Sets pixel format attribute to the given value

  FIXME:/sa setAttribute:, removeAttribute:
  "*/
- (void)setAttribute:(NSOpenGLPixelFormatAttribute)attr toValue:(int)val
{
  if (!_attrdict) _attrdict = [[NSMutableDictionary alloc] init];
  [_attrdict setObject:[NSValue value:&val withObjCType:@encode(int)]
             forKey:[NSNumber numberWithInt:attr]];
  [_nspixelformat release];
  _nspixelformat = nil;
}

/*"
  Removes pixel format attribute.

  Attributes that are not set will be set to their default value.
  FIXME: How is this handled by NSOpenGLPixelFormat, especially in case 
  of boolean attributes?
  "*/
- (void)removeAttribute:(NSOpenGLPixelFormatAttribute)attr
{
  if (!_attrdict) _attrdict = [[NSMutableDictionary alloc] init];
  [_attrdict removeObjectForKey:[NSNumber numberWithInt:attr]];
  [_nspixelformat release];
  _nspixelformat = nil;
}

/*!
  Copies the value of the given attribute into the integer pointed to by
  #valptr. 

  If the attribute is a boolean value the value will be set to 1.

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

  The returned pixelformat is cached, and the same instance will be returned
  if the attributes haven't changed since the last invocation of this
  method.
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
//FIXME: Remove non-keyed archiving? Exception on non-keyed archiving? (kintel 20040412)

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
  if (self = [super init]) {
    if (![coder allowsKeyedCoding]) {
      _attrdict = [[coder decodeObject] retain];
    } else {
      NSLog(@"  allowsKeyedCoding");
      _attrdict = [[coder decodeObjectForKey:@"SC_attrdict"] retain];
    }
  }
  return self;
}

// NSCopying compliance

- (id)copyWithZone:(NSZone *)zone
{
  SCOpenGLPixelFormat * copy = [[[self class] allocWithZone:zone] init];
  copy->_nspixelformat = nil;
  copy->_attrdict = [[NSMutableDictionary 
                       dictionaryWithDictionary:self->_attrdict] retain];
  return copy;
}

@end
