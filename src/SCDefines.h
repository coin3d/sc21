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
#define Sc21VersionNumber1_1 7
