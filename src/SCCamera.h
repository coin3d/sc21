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
 
#import <Sc21/SCDefines.h>

#import <Inventor/SbRotation.h>
#import <Inventor/nodes/SoCamera.h>

@class SCSceneGraph;
@class SCCameraP;

@interface SCCamera : NSObject
{
 @protected
  SCCameraP * _sc_camera;
 @private
  id delegate;
}

/*" Positioning the camera "*/
- (void)reorient:(SbRotation)rotation;
- (void)translate:(SbVec3f)vector;
- (void)zoom:(float)delta;
- (void)viewAll:(SCSceneGraph *)scenegraph;

/*" Adjusting the clipping planes "*/
- (void)updateClippingPlanes:(SCSceneGraph *)scenegraph;
- (BOOL)updatesClippingPlanes;
- (void)setUpdatesClippingPlanes:(BOOL)yn;

/*" Accessing the SoCamera "*/ 
// FIXME: -> property?
- (void)setSoCamera:(SoCamera *)newcamera;
- (SoCamera *)soCamera;

  /*" Delegate handling "*/
// FIXME: -> property?
- (void)setDelegate:(id)newdelegate;
- (id)delegate;
@end

@interface NSObject (SCCameraDelegate)
- (void)adjustNearClippingPlane:(float *)near farClippingPlane:(float *)far;
@end

