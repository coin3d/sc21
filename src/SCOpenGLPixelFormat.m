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

#import <Sc21/SCOpenGLPixelFormat.h>

#define PRIVATE(p) ((p)->scopenglpixelformatpriv)
#define SELF PRIVATE(self)

@interface _SCOpenGLPixelFormatP : NSObject
{
@public
  NSMutableDictionary * attrdict;
  NSOpenGLPixelFormat * nspixelformat;
}
@end

@implementation _SCOpenGLPixelFormatP
@end

@interface SCOpenGLPixelFormat (InternalAPI)
- (void)_SC_commonInit;
@end

@implementation SCOpenGLPixelFormat

/*" 
  SCOpenGLPixelFormat is a replacement for NSOpenGLPixelFormat.
  
  The purpose of this class is to be able to set and query any
  NSOpenGLPixelFormatAttribute. In Sc21, this is used to be able to
  archive/unarchive these attributes for use in the Interface Builder
  inspector for SCView.
  "*/

/*!
  Designated initializer.
*/
- (id)init
{
  self = [super init];
  [self _SC_commonInit];
  return self;
}

- (void)dealloc
{
  [SELF->attrdict release];
  [SELF->nspixelformat release];
  [SELF release];
  [super dealloc];
}

/*"
  Sets boolean pixel format attribute.

  As with NSOpenGLPixelFormat, the existence of a boolean attribute
  implies a YES value.
  To set a boolean attribute to NO, use #removeAttribute:

  FIXME:/sa setAttribute:toValue:
"*/
- (void)setAttribute:(NSOpenGLPixelFormatAttribute)attr
{
  if (!SELF->attrdict) SELF->attrdict = [[NSMutableDictionary alloc] init];
  BOOL yes = YES;
  [SELF->attrdict 
       setObject:[NSValue value:&yes withObjCType:@encode(BOOL)] 
       forKey:[NSNumber numberWithInt:attr]];
  [SELF->nspixelformat release];
  SELF->nspixelformat = nil;
}

/*"
  Sets integer pixel format attribute.

  FIXME:/sa setAttribute:, removeAttribute:
  "*/
- (void)setAttribute:(NSOpenGLPixelFormatAttribute)attr toValue:(int)val
{
  if (!SELF->attrdict) SELF->attrdict = [[NSMutableDictionary alloc] init];
  [SELF->attrdict 
       setObject:[NSValue value:&val withObjCType:@encode(int)]
       forKey:[NSNumber numberWithInt:attr]];
  [SELF->nspixelformat release];
  SELF->nspixelformat = nil;
}

/*"
  Removes pixel format attribute.

  As with NSOpenGLPixelFormat, removing a boolean attribute implies a
  NO value.
  "*/
- (void)removeAttribute:(NSOpenGLPixelFormatAttribute)attr
{
  if (!SELF->attrdict) SELF->attrdict = [[NSMutableDictionary alloc] init];
  [SELF->attrdict removeObjectForKey:[NSNumber numberWithInt:attr]];
  [SELF->nspixelformat release];
  SELF->nspixelformat = nil;
}

/*"
  Copies the value of the given attribute into the integer pointed to by
  #valptr. 

  Returns YES if the attribute exists or NO otherwise.
  On return value of NO, the contents of the valptr is not written.

  If the attribute is a boolean value the valptr value will be set to 1
  if the attribute exists.

  NB! This method returns the value previously set with -setAttribute*.
  If you want the real attribute value of the corresponding 
  NSOpenGLPixelFormat, use its -getValues:forAttribute:forVirtualScreen:.
  "*/
- (BOOL)getValue:(int *)valptr forAttribute:(NSOpenGLPixelFormatAttribute)attr
{
  NSValue * val = [SELF->attrdict objectForKey:[NSNumber numberWithInt:attr]];
  if (!val) return NO;
  if (!strcmp([val objCType], @encode(int))) [val getValue:valptr];
  else *valptr = 1;
  return YES;
}

/*"
  If any attributes have been set, creates and returns a new 
  NSOpenGLPixelFormat instance from these attributes, else return nil.

  The returned pixelformat is cached, and the same instance will be returned
  if the attributes haven't changed since the last invocation of this
  method.
  "*/
- (NSOpenGLPixelFormat *)pixelFormat
{
  if (!SELF->nspixelformat && SELF->attrdict && [SELF->attrdict count] > 0) {
    // Create an attribute array from dict
    NSOpenGLPixelFormatAttribute * attrs = 
      malloc(2*[SELF->attrdict count]*sizeof(NSOpenGLPixelFormatAttribute*)+1);
    NSEnumerator * keys = [SELF->attrdict keyEnumerator];
    NSNumber * key;
    NSValue * val;
    int intval;
    int i = 0;
    while (key = (NSNumber *)[keys nextObject]) {
      attrs[i++] = [key intValue];
      NSLog(@"Attr: %d", attrs[i-1]);
      val = [SELF->attrdict objectForKey:key];
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
    if (SELF->nspixelformat = 
        [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs]) {
      NSLog(@"  pixelFormat created");
    }
    free(attrs);
  }
  return SELF->nspixelformat;
}

// ---------------- NSCoding conformance -------------------------------

- (void)encodeWithCoder:(NSCoder *)coder 
{
  if ([coder allowsKeyedCoding]) {
    [coder encodeObject:SELF->attrdict forKey:@"SC_attrdict"];
  }
}

- (id)initWithCoder:(NSCoder *)coder 
{
  if (self = [super init]) {
    [self _SC_commonInit];
    if ([coder allowsKeyedCoding]) {
      SELF->attrdict = [[coder decodeObjectForKey:@"SC_attrdict"] retain];
    }
  }
  return self;
}

// ---------------- NSCopying conformance -------------------------------

- (id)copyWithZone:(NSZone *)zone
{
  SCOpenGLPixelFormat * copy = [[[self class] allocWithZone:zone] init];
  PRIVATE(copy)->nspixelformat = nil;
  PRIVATE(copy)->attrdict = 
    [[NSMutableDictionary dictionaryWithDictionary:SELF->attrdict] retain];
  return copy;
}

@end

@implementation SCOpenGLPixelFormat (InternalAPI)

- (void)_SC_commonInit
{
  SELF = [[_SCOpenGLPixelFormatP alloc] init];
}

@end
