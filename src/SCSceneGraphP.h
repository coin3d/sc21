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

#import <Sc21/SCSceneGraph.h>

class SoLight;
class SoCamera;
class SoInput;

@interface SCSceneGraphP : NSObject
{
 @public
  SCCamera * camera;
  SoGroup * scenegraph;	 
  SoGroup * superscenegraph;
  SoSceneManager * scenemanager;
  SoDirectionalLight * headlight;  
  BOOL addedlight;
  BOOL addedcamera;
  BOOL createsuperscenegraph;
}
@end

@interface SCSceneGraph (InternalAPI)
- (void)_SC_commonInit;
- (SoLight *)_SC_findLightInSceneGraph:(SoGroup *)sg;
- (SoCamera *)_SC_findCameraInSceneGraph:(SoGroup *)sg;
- (void)_SC_setHasAddedCamera:(BOOL)yn;
- (SoGroup *)_SC_createSuperSceneGraph:(SoGroup *)root;
- (BOOL)_SC_readFromSoInput:(SoInput *)input;
- (void)_SC_setCreatesSuperSceneGraph:(BOOL)yn;
- (BOOL)_SC_createsSuperSceneGraph;
- (SoGroup *)_SC_superSceneGraph; 
- (void)_SC_setSceneManager:(SoSceneManager *)scenemanager;
- (SoSceneManager *)_SC_sceneManager;
@end  

SC21_EXTERN NSString * SCRootChangedNotification;
