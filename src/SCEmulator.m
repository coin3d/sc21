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

#import "SCEmulator.h"

@implementation SCEmulator

#pragma mark --- initialization ---

-(id)init 
{
  if (self = [super init]) {
    emulationdict = [[NSMutableDictionary alloc] init];
  }
  return self;
}

#pragma mark --- mouse button emulation ---

- (void)emulateButton:(int)buttonNumber usingModifier:(unsigned int)modifierFlags;
{
 [emulationdict setObject:[NSNumber numberWithUnsignedInt:modifierFlags]
                          forKey:[NSNumber numberWithInt:buttonNumber]];
}

- (void)removeEmulationForButton:(int)buttonNumber
{
  [emulationdict removeObjectForKey:[NSNumber numberWithInt:buttonNumber]];
}

- (BOOL)emulatesButton:(int)button
{
  // Do we have an entry for button in the dictionary?
  return ([emulationdict objectForKey:[NSNumber numberWithInt:button]] != nil);
}

- (unsigned int)modifierToEmulateButton:(int)buttonNumber
{
  NSNumber * modifiervalue = 
    [emulationdict objectForKey:[NSNumber numberWithInt:buttonNumber]];
  if (modifiervalue) return [modifiervalue unsignedIntValue];
  else return 0;
}

- (int)emulatedButtonForButton:(int)buttonNumber modifier:(unsigned int)modifierFlags
{
  int effectivebutton = buttonNumber;
  if (effectivebutton == 0) {
    NSEnumerator * keys = [emulationdict keyEnumerator];
    NSNumber * key;
    unsigned int matchedflags = 0;
    while ((key = [keys nextObject])) {
      NSNumber * value = [emulationdict objectForKey:key];
      unsigned int flags = [value unsignedIntValue];
      if ((flags & modifierFlags) == flags &&
          flags >= matchedflags) {
        matchedflags = flags;
        effectivebutton = [key intValue];
      }
    }
  }
  return effectivebutton;
}

#pragma mark --- NSCoding conformance ---

- (void)encodeWithCoder:(NSCoder *)coder
{
  if ([coder allowsKeyedCoding]) {
     [coder encodeObject:emulationdict forKey:@"SC_emulationdict"];
  }
}

- (id)initWithCoder:(NSCoder *)coder
{
  if (self = [super init]) {
    if ([coder allowsKeyedCoding]) {
      emulationdict = [[coder decodeObjectForKey:@"SC_emulationdict"] retain];
    }
  }
  return self;
}

@end
