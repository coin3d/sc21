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
#import "SCSceneGraphP.h"

#import <Inventor/SoDB.h>
#import <Inventor/SoInput.h>
#import <Inventor/actions/SoSearchAction.h>
#import <Inventor/nodekits/SoBaseKit.h>
#import <Inventor/nodes/SoPerspectiveCamera.h>
#import <Inventor/nodes/SoDirectionalLight.h>

@implementation _SCSceneGraphP
@end

#define PRIVATE(p) ((p)->scscenegraphpriv)
#define SELF PRIVATE(self)

// Note: I find it really degoutant that this class should be named
// SCSceneGraph instead of SCScenegraph -- scenegraph is one word,
// for Goddess' sake! But the folks who designed the original Inventor
// API Thought Different, and hence are using setSceneGraph() &c.
// all over the place... so for consistency's sake, let's trudge along.
// kyrah 20040716

@implementation SCSceneGraph

/*" 
  Initializes the receiver, a newly allocated SCSceneGraph instance,
  with the contents of the file filename. The filename argument may be
  a full or relative pathname and should include an extension that
  identifies the data type in the file.
  
  After finishing the initialization, this method returns an
  initialized object. However, if a valid Open Inventor scenegraph
  cannot be read from the specified file, the receiver is freed, and
  nil is returned.
"*/
- (id)initWithContentsOfFile:(NSString *)filename
{
  if (self = [super init]) {
    [self _SC_commonInit];
    SoSeparator * fileroot = [self _SC_readFile:filename];
    if (fileroot == NULL) {
      [self release];
      self = nil;
    } else {
      [self setRoot:fileroot];
    }
  }
  return self;
}

/*"
  Initializes the receiver, a newly allocated SCSceneGraph instance,
  with the contents of the URL url. After finishing the
  initialization, this method returns an initialized object. However,
  if a valid Open Inventor scenegraph cannot be read from the
  specified file, the receiver is freed, and nil is returned.
"*/
- (id)initWithContentsOfURL:(NSURL *)url
{
  if (self = [super init]) {
    [self _SC_commonInit];
    // FIXME: Implement reading file from URL.
  }
  return self;
}

- (id)init
{
  if (self = [super init]) {
    [self _SC_commonInit];
  }
  return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
  if (self = [super init]) {
    [self _SC_commonInit];
    if ([coder allowsKeyedCoding]) {
      SELF->addedlight = [coder decodeBoolForKey:@"SC_addedlight"];
      SELF->addedcamera = [coder decodeBoolForKey:@"SC_addedcamera"];
    }
  }
  return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  if ([coder allowsKeyedCoding]) {
    [coder encodeBool:SELF->addedlight forKey:@"SC_addedlight"];
    [coder encodeBool:SELF->addedcamera forKey:@"SC_addedcamera"];
  }
}

- (void) dealloc
{
  [SELF->camera release];
  if (SELF->superscenegraph) { SELF->superscenegraph->unref(); }
  else if (SELF->scenegraph) { SELF->scenegraph->unref(); }
  [SELF release];
}


- (BOOL)readFromFile:(NSString *)name 
{
  SoSeparator * fileroot = [self _SC_readFile:name];
  if (fileroot) { 
    [self setRoot:fileroot];
    return YES; 
  }

  return NO;
}

/*"
  Returns the name assigned to the scenegraph, or nil if no name has
  been assigned. This name corresponds to the node name of the Open
  Inventor scenegraph's root node.
  "*/
- (NSString *)name
{
  // FIXME: Implement.
  return @"foo";
}

/*"
  Registers the receiver under the name specified by name.
  "*/
- (BOOL)setName:(NSString *)name
{
  // FIXME: Does name have to be unique? (If we want to make it correspond to 
  // the saved filename in the bundle, then we probably want to do that... -> 
  // cf. NSImage setName:) kyrah 20040715
  
  // FIXME: Implement.
  return YES;
}

/*"
  Returns the root node in the receiver's Open Inventor scenegraph, or
  NULL if there is no valid scenegraph.
  "*/
- (SoSeparator *)root
{
  return SELF->scenegraph;
}

/*"
  Returns the root node in the receiver's _actually rendered_ Open
  Inventor scenegraph, or NULL if there is no valid scenegraph.

  The superscenegraph is a scenegraph created by the system if there
  is no camera and/or no light in a scene. The controller default
  implementation will in that case add a light/camera and the root
  node supplied by the user.
"*/
- (SoSeparator *)superSceneGraph
{
  return SELF->superscenegraph;
}

/*"
  Sets the receiver's Coin scenegraph to root. 

  By default, the internal implementation will check whether root
  contains at least one light source and one camera. If no light is
  found, a headlight (i.e. a light following the active camera) will
  be added. If a camera is found, it will be used as active camera;
  otherwise, a perspective camera will be added before the scenegraph.

  After a scene graph is set, the delegate method -didSetSceneGraph:
  is called with the super scene graph as parameter.
 
  Both the passed and the actual scene graph will be !{ref()}'ed.
"*/
- (void)setRoot:(SoSeparator *)root
{
  if (root == NULL) { return; }
  
  // Clean up existing scenegraph
  if (SELF->scenegraph) { SELF->scenegraph->unref(); }
  if (SELF->superscenegraph) { SELF->superscenegraph->unref(); }
  SELF->scenegraph = SELF->superscenegraph = NULL;  
  
  SELF->scenegraph = root;
  SELF->headlight = NULL;
  SELF->addedlight = NO;

  // Give delegate the chance to stop superscenegraph creation:
  // It can implement shouldCreateDefaultSuperSceneGraph to return
  // if we should create the default superscenegraph; or it can 
  // supply createSuperSceneGraph: to return its own superscenegraph.
  BOOL createsuperscenegraph = YES;
  if (self->delegate) {
    if ([self->delegate 
      respondsToSelector:@selector(shouldCreateDefaultSuperSceneGraph)]) {
      createsuperscenegraph = [delegate shouldCreateDefaultSuperSceneGraph];    
    } else if ([self->delegate 
        respondsToSelector:@selector(createSuperSceneGraph:)]) {
      createsuperscenegraph = NO;
    }
  }
  if (createsuperscenegraph) {
    [self _SC_createSuperSceneGraph];
  } else { 
    if (self->delegate &&
        [self->delegate respondsToSelector:@selector(createSuperSceneGraph:)]) {
      SELF->superscenegraph = [delegate createSuperSceneGraph:SELF->scenegraph];
    } else {
      SELF->superscenegraph = NULL;
      SELF->scenegraph->ref();    
    }
  }
  
  // Give delegate the chance to do postprocessing, regardless of 
  // whether the superscenegraph was created by us or by the delegate.
  if (SELF->superscenegraph && self->delegate &&
    [self->delegate respondsToSelector:@selector(didCreateSuperSceneGraph:)]) {
    [self->delegate didCreateSuperSceneGraph:SELF->superscenegraph];
  } 
}

- (void)setSceneManager:(SoSceneManager *)scenemanager
{
  SELF->scenemanager = scenemanager;
}

- (SoSceneManager *)sceneManager
{
  return SELF->scenemanager;
}

/*"
  Sets the SoCamera used for viewing the scene to cam. It is first
  checked if the scenegraph contains a camera created by the
  controller, and if yes, this camera is deleted.

  Note that cam is expected to be part of the scenegraph already; it
  is not inserted into it.
"*/
- (SCCamera *)camera
{
  return SELF->camera; 
}

// Note that I removed the methods for getting and setting the
// SoCamera -- app programmers should get the current SCCamera 
// and access the SoCamera this way.

/*" Returns !{YES} if a camera was added in the superscenegraph,
    and !{NO} if the camera is part of the user-supplied
    scenegraph.
"*/
- (BOOL) hasAddedCamera
{
  return SELF->addedcamera;
}

// ----------------- Automatic headlight configuration -----------------

// Note that I intentionally removed the methods for turning the
// headlight on and off. This can easily be done by the application
// programmer by first getting the scenegraph's headlight and then
// modifying its values directly. kyrah 20040717.


/*" If an additional light was added as part of the superscenegraph, this
    method returns this headlight. Otherwise, NULL is returned. "*/

- (SoDirectionalLight *)headlight
{
  return (SELF->addedlight) ? SELF->headlight : NULL;
}

/*" Returns !{YES} if a light was added in the superscenegraph,
    and !{NO} otherwise.
"*/
- (BOOL)hasAddedLight
{
  return SELF->addedlight;
}

/*" Makes newdelegate the receiver's delegate. "*/

- (void)setDelegate:(id)newdelegate
{
  self->delegate = newdelegate;
}

/*" Returns the receiver's delegate. "*/

- (id)delegate
{
  return self->delegate;
}

@end

@implementation SCSceneGraph (InternalAPI)
    
- (void)_SC_commonInit
{
  SELF = [[_SCSceneGraphP alloc] init];
  SELF->camera = [[SCCamera alloc] initWithSceneGraph:self];
  SELF->addedcamera = NO;  
  SELF->addedlight = NO;  
}

/* Find light in root. Returns a pointer to the light, if found,
   otherwise NULL.
*/

- (SoLight *)_SC_findLight
{
  assert (SELF->scenegraph);  
  SoLight * light = NULL;
  SbBool oldsearch = SoBaseKit::isSearchingChildren();
  SoBaseKit::setSearchingChildren(TRUE);
  SoSearchAction sa;
  sa.reset();
  sa.setType(SoLight::getClassTypeId());
  sa.apply(SELF->scenegraph);
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

- (SoCamera *)_SC_findCamera
{
  assert (SELF->scenegraph);
  SoCamera * scenecamera = NULL;
  SbBool oldsearch = SoBaseKit::isSearchingChildren();
  SoBaseKit::setSearchingChildren(TRUE);
  SoSearchAction sa;
  sa.reset();
  sa.setType(SoCamera::getClassTypeId());
  sa.apply(SELF->scenegraph);
  SoBaseKit::setSearchingChildren(oldsearch);
  if (sa.getPath() != NULL) {
    SoFullPath * fullpath = (SoFullPath *) sa.getPath();
    scenecamera = (SoCamera *)fullpath->getTail();
  }
  return scenecamera;
}

/* Set whether the camera was created by the system.
   (as opposed to being part of the user-supplied scene graph). 
   When setting a new camera, this setting will determine if the
   old camera should be deleted or not.   

   This method is intentionally not public, since it changes the
   internal state of SCSceneGraph that should not be modifyable by
   the application programmer. It is possible to _query_ this
   attribute through the public hasAddedCamera method, though.
*/
- (void) _SC_setHasAddedCamera:(BOOL)yn
{
  SELF->addedcamera = yn;
}

- (void)_SC_createSuperSceneGraph
{
  SELF->superscenegraph = new SoSeparator;
  SELF->superscenegraph->ref();
  
  // Must ref before applying action!
  SELF->scenegraph->ref();
  
  // Handle lighting
  if (![self _SC_findLight]) {
    SELF->headlight = new SoDirectionalLight;
    SELF->superscenegraph->addChild(SELF->headlight);
    SELF->addedlight = YES;
    [[NSNotificationCenter defaultCenter]
        postNotificationName:SCNoLightFoundInSceneNotification object:self];
  } else {
    SELF->addedlight = NO;
  }
  
  // Handle camera
  SoCamera * scenecamera  = [self _SC_findCamera];
  if (scenecamera == NULL) {
    scenecamera = new SoPerspectiveCamera;
    [SELF->camera setSoCamera:scenecamera deleteOldCamera:NO];
    SELF->addedcamera = YES;
    SELF->superscenegraph->addChild(scenecamera);
    [[NSNotificationCenter defaultCenter]
        postNotificationName:SCNoCameraFoundInSceneNotification object:self];
  } else {
    [SELF->camera setSoCamera:scenecamera deleteOldCamera:NO];
    SELF->addedcamera = NO;
  }

  SELF->superscenegraph->addChild(SELF->scenegraph);
  
  // We ref'ed the scenegraph earlier so we could savely
  // apply a search action. Now that it is part of the 
  // superscenegraph, we can savely unref it again.
  SELF->scenegraph->unref();
}

- (SoSeparator *)_SC_readFile:(NSString *)filename
{
  SoSeparator * fileroot = NULL;
  SoInput in;
  if (!in.openFile([filename UTF8String])) {  
    [[NSNotificationCenter defaultCenter]
        postNotificationName:SCCouldNotOpenFileNotification object:self];
    return NULL;
  } else {
    fileroot = SoDB::readAll(&in);
    // Note that this is not strictly necessary, but I consider it bad 
    // practice to leave the closing of my resources to the destructor...
    // *shrug*, kyrah
    in.closeFile();
    if (fileroot == NULL) {
      [[NSNotificationCenter defaultCenter]
          postNotificationName:SCCouldNotReadFileNotification object:self];
    }
  }
  return fileroot;
}
@end
