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
