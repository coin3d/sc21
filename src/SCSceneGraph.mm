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

#import "SCSceneGraph.h"

#import <Inventor/SoDB.h>
#import <Inventor/SoInput.h>
#import <Inventor/actions/SoSearchAction.h>
#import <Inventor/nodekits/SoBaseKit.h>
#import <Inventor/nodes/SoPerspectiveCamera.h>
#import <Inventor/nodes/SoDirectionalLight.h>

@implementation SCSceneGraph

/*" Initializes the receiver, a newly allocated SCSceneGraph instance, with the contents of the file
    filename. The filename argument may be a full or relative pathname and should include an extension 
    that identifies the data type in the file. 

    After finishing the initialization, this method returns an initialized object. However, if a valid 
    Open Inventor scenegraph cannot be read from the specified file, the receiver is freed, and nil is 
    returned.
"*/
- (id)initWithContentsOfFile:(NSString *)filename
{
  if (self = [super init]) {
    camera = [[SCCamera alloc] init];
    SoSeparator * s = nil;
    SoInput in;
    if (!in.openFile([filename cString])) {  
      // FIXME: Post notification or call delegate method
      [self release];
    } else {
      s = SoDB::readAll(&in);
      // Note that this is not strictly necessary, but I consider it bad practice to leave 
      // the closing of my resources to the destructor... *shrug*, kyrah
      in.closeFile();      
      if (s == nil) {
        // FIXME: Post notification or call delegate method
        [self release];
        return nil;
      } else {
        [self setRoot:s];
      }
    }
  }
  return self;
}

/*" Initializes the receiver, a newly allocated SCSceneGraph instance, with the contents of the URL url.
  After finishing the initialization, this method returns an initialized object. However, if a valid 
  Open Inventor scenegraph cannot be read from the specified file, the receiver is freed, and nil is 
  returned.
"*/

- (id)initWithContentsOfURL:(NSURL *)url
{
  // FIXME: Implement.
  return [super init]; 
}

- (void) dealloc
{
  [camera release]; 
}

/*" Returns the name assigned to the scenegraph, or nil if no name has been assigned. This name 
    corresponds to the node name of the Open Inventor scenegraph's root node. 
 "*/

- (NSString *)name
{
  // FIXME: Implement.
  return @"foo";
}

/*" Registers the receiver under the name specified by name. "*/

- (BOOL)setName:(NSString *)name
{
  // FIXME: Does name have to be unique? (If we want to make it correspond to the saved filename
  // in the bundle, then we probably want to do that... -> cf. NSImage setName:) kyrah 20040715
  
  // FIXME: Implement.
  return YES;
}

/*" Returns the root node in the receiver's Open Inventor scenegraph, or nil if there is no 
    valid scenegraph. 
 "*/

- (SoSeparator *)root
{
  return scenegraph;
}

/*" Returns the root node in the receiver's _actually rendered_ Open 
    Inventor scenegraph, or nil if there is no valid scenegraph.

    The superscenegraph is a scenegraph created by the system if there is no 
    camera and/or no light in a scene. The controller default implementation will 
    in that case add a light/camera and the root node supplied by the user.
"*/

- (SoSeparator *)superSceneGraph
{
  return superscenegraph;
}

/*" Sets the receiver's scenegraph to root. Note that no checking will be done whether root is
    actually a valid Open Inventor scenegraph or not. 
 "*/

- (void)setRoot:(SoSeparator *)root
{
  if (root == NULL) { 
    // FIXME: Post notification?
    return; 
  }
  
  // Clean up existing scenegraph
  if (scenegraph) { scenegraph->unref(); }
  if (superscenegraph) { superscenegraph->unref(); }
  scenegraph = superscenegraph = NULL;  
  
  headlight = NULL;
  [self setHeadlightIsOn:NO];
  root->ref();
  
  // FIXME: Give delegate chance to handle this.
  // (Please note the FIXME comment in the #ifdef'ed code 
  // in SCController at the same place.)
  superscenegraph = [self _SC_createSuperSceneGraph:root];
  
  if (superscenegraph) { // Successful superscenegraph creation
    scenegraph = root;
    superscenegraph->ref();
    // It's possible to create an SCScenegraph without having a valid
    // SCController class, which means we also don't have an 
    // SoSceneManager. In this case, we cannot call these methods.
    if ([camera controller]) {
      [camera updateClippingPlanes:scenegraph];
      if ([camera controllerHasCreatedCamera]) {
        [camera viewAll];
      }
    }
  } else {
    // NULL super scene graph => leave everything at NULL
    root->unrefNoDelete();
  }
}

/*" Sets the SoCamera used for viewing the scene to cam.
    It is first checked if the scenegraph contains a camera created by
    the controller, and if yes, this camera is deleted.

    Note that cam is expected to be part of the scenegraph already;
    it is not inserted into it.
"*/

- (void)setCamera:(SoCamera *)cam
{
  [camera setSoCamera:cam deleteOldCamera:YES];
}

/*" Returns the current SoCamera used for viewing. "*/

- (SoCamera *)camera
{
  return [camera soCamera];
}

/*" Returns !{SCCameraPerspective} if the camera is perspective
    and !{SCCameraOrthographic} if the camera is orthographic.
"*/

// FIXME: If SCCamera class remains public, remove this method.
- (SCCameraType)cameraType
{
  return [camera type];
}

/*" Repositions the camera so that we can se the whole scene. "*/
- (void)viewAll
{
  [camera viewAll]; // SCViewAllNotification sent by _camera
}


// ----------------- Automatic headlight configuration -----------------

/*" Returns !{YES} if the headlight is on, and !{NO} if it is off. "*/

- (BOOL)headlightIsOn
{
  if (headlight == NULL) { return FALSE; }
  return (headlight->on.getValue() == TRUE) ? YES : NO;
}


/*" Turns the headlight on or off. "*/

- (void)setHeadlightIsOn:(BOOL)yn
{
  if (headlight == NULL) { return; }
  headlight-> on = yn ? TRUE : FALSE;
  
  [[NSNotificationCenter defaultCenter]
    postNotificationName:SCHeadlightChangedNotification object:self];
}

/*" Returns the headlight of the current scene graph. "*/

- (SoDirectionalLight *)headlight
{
  return headlight;
}

@end

@implementation SCSceneGraph (InternalAPI)

/* Find light in root. Returns a pointer to the light, if found,
   otherwise NULL.
*/

- (SoLight *)_SC_findLightInSceneGraph:(SoGroup *)root
{
  if (root == NULL) return NULL;
  
  SoLight * light = NULL;
  SbBool oldsearch = SoBaseKit::isSearchingChildren();
  SoBaseKit::setSearchingChildren(TRUE);
  SoSearchAction sa;
  sa.reset();
  sa.setType(SoLight::getClassTypeId());
  sa.apply(root);
  SoBaseKit::setSearchingChildren(oldsearch);
  if (sa.getPath() != NULL) {
    SoFullPath * fullpath = (SoFullPath *) sa.getPath();
    light = (SoLight *)fullpath->getTail();
  }
  return light;
}

/* Find camera in root. Returns a pointer to the camera, if found,
    otherwise NULL.
 */

- (SoCamera *)_SC_findCameraInSceneGraph:(SoGroup *)root
{
  SoCamera * scenecamera = NULL;
  SbBool oldsearch = SoBaseKit::isSearchingChildren();
  SoBaseKit::setSearchingChildren(TRUE);
  SoSearchAction sa;
  sa.reset();
  sa.setType(SoCamera::getClassTypeId());
  sa.apply(root);
  SoBaseKit::setSearchingChildren(oldsearch);
  if (sa.getPath() != NULL) {
    SoFullPath * fullpath = (SoFullPath *) sa.getPath();
    scenecamera = (SoCamera *)fullpath->getTail();
  }
  return scenecamera;
}

- (SoSeparator *)_SC_createSuperSceneGraph:(SoGroup *)sg
{
  SoSeparator *supersg = new SoSeparator;
  
  // Handle lighting
  if (![self _SC_findLightInSceneGraph:sg]) {
    [self setHeadlightIsOn:YES];
  } else {
    [self setHeadlightIsOn:NO];
  }
  headlight = new SoDirectionalLight;
  supersg->addChild(headlight);
  
  // Handle camera
  SoCamera * scenecamera  = [self _SC_findCameraInSceneGraph:sg];
  if (scenecamera == NULL) {
    scenecamera = new SoPerspectiveCamera;
    [camera setSoCamera:scenecamera deleteOldCamera:NO];
    [camera setControllerHasCreatedCamera:YES];
    supersg->addChild(scenecamera);
  } else {
    [camera setSoCamera:scenecamera deleteOldCamera:NO];
    [camera setControllerHasCreatedCamera:NO];
  }
  
  supersg->addChild(sg);
  
  return supersg;
}

@end