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

#import <Sc21/SCInternalDefines.h>

/*" 

  The run-time Sc21 version number. 

  Allows you to check at runtime whether certain features you want to
  use are actually available.  For instance if you want to use a
  feature that was introduced in Sc21 1.1:

  !{if (floor(Sc21VersionNumber) >= Sc21VersionNumber1_1) {
    \/\/ use the new feature
   }}
"*/

// Note that the value of this is set via the apple-generic versioning
// system. To modify the actual value in Xcode, change the "Current
// Project Version" attribute in Targets -> Sc21 framework -> Info ->
// Build.

SC21_EXTERN const double Sc21VersionNumber;


/*" 
  The compile-time version number. (See Sc21VersionNumber
  documentation for more information.)
"*/

// Version numbers are increased by the following scheme:
// o Micro versions (e.g. 1.0.1): changes only after the decimal point
// o Minor versions (e.g. 1.1.0): increase by some number (might be >1 if
//                                there were intermediate beta releases)
// o Major versions:              basically the same as for minor versions
//                                but the Letter version will also change
//                                (e.g. A -> B).

#define Sc21VersionNumber1_0 6
