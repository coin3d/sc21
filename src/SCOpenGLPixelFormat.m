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
#import "SCUtil.h"

#define PRIVATE(p) ((p)->_sc_openglpixelformat)
#define SELF PRIVATE(self)

@interface _SCOpenGLPixelFormatP : NSObject
{
 @public
  NSMutableDictionary * intattributes;
  NSMutableSet * boolattributes;
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

#pragma mark --- initialization and cleanup ---

/*!
  Designated initializer.
*/
- (id)init
{
  self = [super init];
  [self _SC_commonInit];
  SELF->intattributes = [[NSMutableDictionary alloc] init];
  SELF->boolattributes = [[NSMutableSet alloc] init];
  return self;
}

- (void)dealloc
{
  [SELF->intattributes release];
  [SELF->boolattributes release];
  [SELF->nspixelformat release];
  [SELF release];
  [super dealloc];
}

#pragma mark --- NSOpenGLPixelFormat creation ---

/*"
If any attributes have been set, creates and returns a new 
 NSOpenGLPixelFormat instance from these attributes, else return nil.
 
 The returned pixelformat is cached, and the same instance will be returned
 if the attributes haven't changed since the last invocation of this
 method.
 "*/
- (NSOpenGLPixelFormat *)pixelFormat
{
  if (!SELF->nspixelformat && 
      (SELF->intattributes && [SELF->intattributes count] > 0 ||
       SELF->boolattributes && [SELF->boolattributes count] > 0)) {
    // Create an attribute array from dict
    NSOpenGLPixelFormatAttribute * attrs = 
    malloc(2*
           [SELF->intattributes count]*sizeof(NSOpenGLPixelFormatAttribute*)+
           [SELF->boolattributes count]*sizeof(NSOpenGLPixelFormatAttribute*)+
           1);
    
    NSEnumerator * keys = [SELF->intattributes keyEnumerator];
    NSNumber * key;
    int i = 0;
    while (key = (NSNumber *)[keys nextObject]) {
      attrs[i++] = [key intValue];
      attrs[i++] = [[SELF->intattributes objectForKey:key] intValue];
      SC21_DEBUG(@"Attr: %d, value: %d", attrs[i-2], attrs[i-1]);
    }
    keys = [SELF->boolattributes objectEnumerator];
    while (key = (NSNumber *)[keys nextObject]) {
      attrs[i++] = [key intValue];
    }
    
    attrs[i++] = nil; // nil-terminate
    
    // Create new pixelformat object, copy dict
    if (SELF->nspixelformat = 
        [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs]) {
      SC21_DEBUG(@"  pixelFormat created");
    }
    free(attrs);
  }
  return SELF->nspixelformat;
}


#pragma mark --- attribute handling ---

/*"
  Sets boolean pixel format attribute.

  As with NSOpenGLPixelFormat, the existence of a boolean attribute
  implies a YES value.
  To set a boolean attribute to NO, use #removeAttribute:

  FIXME:/sa setAttribute:toValue:
"*/
- (void)setAttribute:(NSOpenGLPixelFormatAttribute)attr
{
  [SELF->boolattributes addObject:[NSNumber numberWithInt:attr]];
  [SELF->nspixelformat release];
  SELF->nspixelformat = nil;
}

/*"
  Sets integer pixel format attribute.

  FIXME:/sa setAttribute:, removeAttribute:
  "*/
- (void)setAttribute:(NSOpenGLPixelFormatAttribute)attr toValue:(int)val
{
  [SELF->intattributes setObject:[NSNumber numberWithInt:val]
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
  [SELF->boolattributes removeObject:[NSNumber numberWithInt:attr]];
  [SELF->intattributes removeObjectForKey:[NSNumber numberWithInt:attr]];
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
  if ([SELF->boolattributes containsObject:[NSNumber numberWithInt:attr]]) {
    *valptr = 1;
  }
  else {
    NSNumber * num = 
      [SELF->intattributes objectForKey:[NSNumber numberWithInt:attr]];
    if (!num) return NO;
    *valptr = [num intValue];
  }
  return YES;
}


#pragma mark --- NSCoding conformance ---

- (void)encodeWithCoder:(NSCoder *)coder 
{
  if ([coder allowsKeyedCoding]) {
    [coder encodeObject:SELF->intattributes forKey:@"SC_intattributes"];
    [coder encodeObject:SELF->boolattributes forKey:@"SC_boolattributes"];
  }
}

- (id)initWithCoder:(NSCoder *)coder 
{
  if (self = [super init]) {
    [self _SC_commonInit];
    if ([coder allowsKeyedCoding]) {
      SELF->intattributes = [[coder decodeObjectForKey:@"SC_intattributes"] retain];
      SELF->boolattributes = [[coder decodeObjectForKey:@"SC_boolattributes"] retain];
    }
    //FIXME: This should not be necessary as these will always exist,
    //but some old nibs might not have them yet. This can probablt be
    //removed when everything is in sync. (kintel 20040729).
    if (!SELF->intattributes) {
      SELF->intattributes = [[NSMutableDictionary alloc] init];
    }
    if (!SELF->boolattributes) {
      SELF->boolattributes = [[NSMutableSet alloc] init];
    }
  }
  return self;
}

#pragma mark --- NSCopying conformance ---

- (id)copyWithZone:(NSZone *)zone
{
  SCOpenGLPixelFormat * copy = [[[self class] allocWithZone:zone] init];
  PRIVATE(copy)->nspixelformat = nil;
  PRIVATE(copy)->intattributes = 
    [[NSMutableDictionary dictionaryWithDictionary:SELF->intattributes] retain];
  PRIVATE(copy)->boolattributes = 
    [[NSMutableSet setWithSet:SELF->boolattributes] retain];
  return copy;
}

@end

@implementation SCOpenGLPixelFormat (InternalAPI)

- (void)_SC_commonInit
{
  SELF = [[_SCOpenGLPixelFormatP alloc] init];
}

@end
