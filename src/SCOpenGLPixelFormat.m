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

#import <Sc21/SCOpenGLPixelFormat.h>
#import "SCUtil.h"

#define PRIVATE(p) ((p)->_sc_openglpixelformat)
#define SELF PRIVATE(self)

@interface SCOpenGLPixelFormatP : NSObject
{
 @public
  NSMutableDictionary * intattributes;
  NSMutableSet * boolattributes;
  NSOpenGLPixelFormat * nspixelformat;
}
@end

@implementation SCOpenGLPixelFormatP
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
      SC21_DEBUG(@"Attr: %d", attrs[i-1]);
    }
    
    attrs[i++] = 0; // 0-terminate
    
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

  See also !{setAttribute:toValue:}
"*/
- (void)setAttribute:(NSOpenGLPixelFormatAttribute)attr
{
  [SELF->boolattributes addObject:[NSNumber numberWithInt:attr]];
  [SELF->nspixelformat release];
  SELF->nspixelformat = nil;
}

/*"
  Sets integer pixel format attribute.

  See also !{setAttribute:}
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
  valptr. 

  Returns YES if the attribute exists or NO otherwise.
  On return value of NO, the contents of the valptr is not written.

  If the attribute is a boolean value the valptr value will be set to 1
  if the attribute exists.

  Note that this method returns the value previously set with
  -setAttribute*.  If you want the real attribute value of the
  corresponding NSOpenGLPixelFormat, use its
  !{-getValues:forAttribute:forVirtualScreen:} method. 
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
    //but some old nibs might not have them yet. This can probably be
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
  SELF = [[SCOpenGLPixelFormatP alloc] init];
}

@end
