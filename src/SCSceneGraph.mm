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

#import <Sc21/SCSceneGraph.h>
#import <Sc21/SCCamera.h>
#import "SCUtil.h"

#import <Inventor/SoDB.h>
#import <Inventor/SoInput.h>
#import <Inventor/SoOutput.h>
#import <Inventor/actions/SoSearchAction.h>
#import <Inventor/actions/SoWriteAction.h>
#import <Inventor/errors/SoReadError.h>
#import <Inventor/nodekits/SoBaseKit.h>
#import <Inventor/nodes/SoPerspectiveCamera.h>
#import <Inventor/nodes/SoDirectionalLight.h>
#import <Inventor/VRMLnodes/SoVRMLGroup.h>

#import "SCSceneGraphP.h"

void error_cb(const class SoError * error, void * data)
{
  SCSceneGraph * scenegraph = (SCSceneGraph *)data;
  NSString * errstr = 
    [NSString stringWithCString:error->getDebugString().getString()];
  [[NSNotificationCenter defaultCenter]
   postNotificationName:SCCouldNotReadSceneNotification object:scenegraph
   userInfo:[NSDictionary dictionaryWithObject:errstr forKey:@"description"]];
}

@implementation SCSceneGraphP
@end

#define PRIVATE(p) ((p)->_sc_scenegraph)
#define SELF PRIVATE(self)

// Note: I find it really degoutant that this class should be named
// SCSceneGraph instead of SCScenegraph -- scenegraph is one word,
// for Goddess' sake! But the folks who designed the original Inventor
// API Thought Different, and hence are using setSceneGraph() &c.
// all over the place... so for consistency's sake, let's trudge along.
// kyrah 20040716

@implementation SCSceneGraph

/*" 
  An SCSceneGraph encapsulates a Coin scenegraph and provides
 an abstraction for reading Inventor and VRML files.

  #{Superscenegraph creation} 

  When a scene is read that contains no light or no camera, nothing
  would be visible, so by default SCSceneGraph inserts a light or
  camera if none is found. This is called %{superscenegraph creation}
  can be controlled in several ways:

  (1) !{shouldCreateDefaultSuperSceneGraph} delegate method (if present)

  (2) else: !{createSuperSceneGraph} delegate method
      (called instead of internal default)

  (3) else: use the value of SCSceneGraph's IB
      inspector (default setting is !{YES})

  For more information about the delegate methods refer to the 
  #{NSObject(SCSceneGraphDelegate)} documentation.
"*/
 
#pragma mark --- initialization and cleanup ---

/*" 
  Initializes the receiver, a newly allocated SCSceneGraph instance,
  with the contents of the file filename. The filename argument may be
  a full or relative pathname and should include an extension that
  identifies the data type in the file.
  
  If the file cannot be opened, an !{SCCouldNotOpenFileNotification}
  is posted. If the file does not contain a valid scenegraph, an
  !{SCCouldNotReadSceneNotification} is posted. In either of these
  cases, the receiver is freed, and nil is returned.

"*/

- (id)initWithContentsOfFile:(NSString *)filename
{
  if (self = [self init]) {
    if (![self readFromFile:filename]) {
      [self release];
      self = nil;
    }
  }
  return self;
}

/*"
  Initializes the receiver, a newly allocated SCSceneGraph instance,
  with the contents of the URL url. 

  If the URL does not contain a valid scenegraph, an
  !{SCCouldNotReadSceneNotification} is posted, the receiver is freed,
  and nil is returned.
"*/
- (id)initWithContentsOfURL:(NSURL *)URL
{
  if (self = [self init]) {
    if (![self readFromURL:URL]) {
      [self release];
      self = nil;
    }
  }
  return self;
}

- (id)init
{
  if (self = [super init]) {
    [self _SC_commonInit];
    SELF->createsuperscenegraph = YES;
  }
  return self;
}


- (void) dealloc
{
  [self setRoot:NULL];
  [SELF->camera release];
  [SELF release];
}

#pragma mark --- file system access --- 

/*"
  Read a new Coin scenegraph from the file name.

  Posts an !{SCCouldNotOpenFileNotification} if the file cannot be
  read.

  Posts an !{SCCouldNotReadSceneNotification} if the file does not
  contain a valid scenegraph.

  Returns !{YES} if reading the scenegraph was successful, and !{NO}
  otherwise.
"*/

- (BOOL)readFromFile:(NSString *)name 
{
  BOOL ret = NO;
  SoInput in;
  if (!in.openFile([name UTF8String])) {  
    [[NSNotificationCenter defaultCenter]
      postNotificationName:SCCouldNotOpenFileNotification object:self];
  } else {
    ret = [self _SC_readFromSoInput:&in];
    in.closeFile();
  }
  return ret;
}


/*"
  Read a new Coin scenegraph from URL.

  Posts an !{SCCouldNotReadSceneNotification} if the URL does not
  contain a valid scenegraph.

  Returns !{YES} if reading the scenegraph was successful, and !{NO}
  otherwise.

"*/

- (BOOL)readFromURL:(NSURL *)URL
{
  NSData * data = [URL resourceDataUsingCache:YES];
  if (data) {
    return [self loadDataRepresentation:data];
  }
  return NO;
}

/*" 
  Read scene from data using !{SoInput::setBuffer()}.

  Posts an !{SCCouldNotReadSceneNotification} if the file does not
  contain a valid scenegraph.

  Returns !{YES} if reading the scenegraph was successful, and !{NO}
  otherwise. 
"*/

- (BOOL)loadDataRepresentation:(NSData *)data
{
  SoInput input;
  input.setBuffer((void *)[data bytes], [data length]);
  return [self _SC_readFromSoInput:&input];
}

#pragma mark --- camera handling ---

/*" 
  Returns the camera used for viewing the scene. Note that 
  SCCamera is a only a proxy class, so you'll have to use SCCamera's
  !{soCamera} and !{setSoCamera:} methods to access the actual Coin
  camera.
"*/

- (SCCamera *)camera
{
  return SELF->camera; 
}

/*" Positions the current camera so that the whole scene is visible. "*/

- (void)viewAll
{
  [SELF->camera viewAll:self];
}

#pragma mark --- headlight access ---

/*" 
  If an additional light was added as part of the superscenegraph, this
  method returns this headlight. Otherwise, NULL is returned. 
"*/

- (SoDirectionalLight *)headlight
{
  return (SELF->addedlight) ? SELF->headlight : NULL;
}

#pragma mark --- Coin scenegraph access ---

/*"
  Returns the root node in the receiver's Open Inventor scenegraph, or
  NULL if there is no valid scenegraph.
  "*/
- (SoGroup *)root
{
  return SELF->scenegraph;
}


/*"
  Sets the receiver's Coin scenegraph to root. 

  By default, the internal implementation will check whether root
  contains at least one light source and one camera. If no light is
  found, a headlight (i.e. a light following the active camera) will
  be added. If a camera is found, it will be used as active camera;
  otherwise, a perspective camera will be added before the scenegraph.
  (See the class introduction at the top of this page for more
  information on how to control this behaviour.)

  After a scene graph is set, the delegate method -didSetSceneGraph:
  is called with the superscenegraph as parameter.
 
  Both the passed and the actual scene graph will be !{ref()}'ed.
"*/
- (void)setRoot:(SoGroup *)root
{
  SC21_DEBUG(@"SCSceneGraph.setRoot: %p", root);
  // Clean up existing scenegraph
  if (SELF->scenegraph) { SELF->scenegraph->unref(); }
  if (SELF->superscenegraph) { SELF->superscenegraph->unref(); }
  SELF->scenegraph = SELF->superscenegraph = NULL;  
  SELF->headlight = NULL;
  SELF->addedlight = NO;
  
  if ((SELF->scenegraph = root) == NULL) { return; }
  SELF->scenegraph->ref();    
  
  // SELF->createsuperscenegraph is controlled through the IB inspector.
  BOOL createsuperscenegraph = SELF->createsuperscenegraph;
  
  // Give delegate the chance to stop superscenegraph creation:
  // It can implement shouldCreateDefaultSuperSceneGraph to return
  // if we should create the default superscenegraph; or it can 
  // supply createSuperSceneGraph: to return its own superscenegraph.
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
    SELF->superscenegraph = [self _SC_createSuperSceneGraph:SELF->scenegraph];
  } else { 
    if (self->delegate &&
        [self->delegate respondsToSelector:@selector(createSuperSceneGraph:)]) {
      SELF->superscenegraph = [delegate createSuperSceneGraph:SELF->scenegraph];
    } else {
      SELF->superscenegraph = NULL;
    }
  }
  if (SELF->superscenegraph) SELF->superscenegraph->ref();
  
  // Set active camera to use in viewer. Note that we have to do this
  // after the delegate had the chance to create its own
  // superscenegraph to make sure the right camera is picked up.
  SoCamera * scenecamera = 
    [self _SC_findCameraInSceneGraph:SELF->superscenegraph];
  if (scenecamera) {
    [SELF->camera setSoCamera:scenecamera];
  } else {
    [[NSNotificationCenter defaultCenter]
        postNotificationName:SCNoCameraFoundInSceneNotification object:self];
  }
  
  // Check if there is a light in the scenegraph (we have to do this
  // here since one might have been added when creating the
  // superscenegraph) 
  if (![self _SC_findLightInSceneGraph:SELF->superscenegraph]) {
    [[NSNotificationCenter defaultCenter]
        postNotificationName:SCNoLightFoundInSceneNotification object:self];
  } 

  // Give delegate the chance to do postprocessing, regardless of 
  // whether the superscenegraph was created by us or by the delegate.
  if (SELF->superscenegraph && self->delegate &&
    [self->delegate respondsToSelector:@selector(didCreateSuperSceneGraph:)]) {
    [self->delegate didCreateSuperSceneGraph:SELF->superscenegraph];
  }
  
  [[NSNotificationCenter defaultCenter]
    postNotificationName:SCRootChangedNotification object:self];  
}

#pragma mark --- delegate handling ---

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




#pragma mark --- NSCoding conformance ---

- (void)encodeWithCoder:(NSCoder *)coder
{
  if ([coder allowsKeyedCoding]) {
    [coder encodeBool:SELF->createsuperscenegraph 
               forKey:@"SC_createsuperscenegraph"];
  }
}


- (id)initWithCoder:(NSCoder *)coder
{
  if (self = [super init]) {
    [self _SC_commonInit];
    if ([coder allowsKeyedCoding]) {
      SELF->createsuperscenegraph = 
      [coder decodeBoolForKey:@"SC_createsuperscenegraph"];
    }
  }
  return self;
}

@end

@implementation SCSceneGraph (InternalAPI)
    
- (void)_SC_commonInit
{
  SELF = [[SCSceneGraphP alloc] init];
  SELF->camera = [[SCCamera alloc] init];
  SELF->addedcamera = NO;
  SELF->addedlight = NO;

  SoReadError::setHandlerCallback(error_cb, self);

}

/* Find light in root. Returns a pointer to the light, if found,
   otherwise NULL.
*/

- (SoLight *)_SC_findLightInSceneGraph:(SoGroup *)sg
{
  assert (sg);  
  SoLight * light = NULL;
  SbBool oldsearch = SoBaseKit::isSearchingChildren();
  SoBaseKit::setSearchingChildren(TRUE);
  SoSearchAction sa;
  sa.reset();
  sa.setType(SoLight::getClassTypeId());
  sa.apply(sg);
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

- (SoCamera *)_SC_findCameraInSceneGraph:(SoGroup *)sg
{
  assert(sg);
  SoCamera * scenecamera = NULL;
  SbBool oldsearch = SoBaseKit::isSearchingChildren();
  SoBaseKit::setSearchingChildren(TRUE);
  SoSearchAction sa;
  sa.reset();
  sa.setType(SoCamera::getClassTypeId());
  sa.apply(sg);
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

- (SoGroup *)_SC_createSuperSceneGraph:(SoGroup *)root
{
  SoSeparator * superscenegraph = new SoSeparator;
  
  // Handle lighting
  if (![self _SC_findLightInSceneGraph:root]) {
    SELF->headlight = new SoDirectionalLight;
    superscenegraph->addChild(SELF->headlight);
    SELF->addedlight = YES;
  } else {
    SELF->addedlight = NO;
  }
  
  // Handle camera
  SoCamera * scenecamera  = [self _SC_findCameraInSceneGraph:root];
  if (scenecamera == NULL) {
    SELF->addedcamera = YES;
    superscenegraph->addChild(new SoPerspectiveCamera);
  } else {
    SELF->addedcamera = NO;
  }

  superscenegraph->addChild(root);
  return superscenegraph;
}

- (BOOL)_SC_readFromSoInput:(SoInput *)input
{
  SoGroup * fileroot = NULL;
  if (input->isFileVRML2()) {
    fileroot = SoDB::readAllVRML(input);
  } else {
    fileroot = SoDB::readAll(input);
  }
  if (fileroot) { 
    [self setRoot:fileroot];
    return YES; 
  } else {
    return NO;
  }
}


- (void)_SC_setCreatesSuperSceneGraph:(BOOL)yn
{
  SELF->createsuperscenegraph = yn; 
}

- (BOOL)_SC_createsSuperSceneGraph
{
  return SELF->createsuperscenegraph;
}


/*"
  Returns the root node in the receiver's _actually rendered_ Open
  Inventor scenegraph, or NULL if there is no valid scenegraph.

  The superscenegraph is a scenegraph created by the system if there
  is no camera and/or no light in a scene. The controller default
  implementation will in that case add a light/camera and the root
  node supplied by the user.
"*/
- (SoGroup *)_SC_superSceneGraph
{
  return SELF->superscenegraph;
}

- (void)_SC_setSceneManager:(SoSceneManager *)scenemanager
{
  SELF->scenemanager = scenemanager;
}

- (SoSceneManager *)_SC_sceneManager
{
  return SELF->scenemanager;
}

@end

// Dummy implementations to force AutoDoc to generate documentation for 
// delegate methods.

@implementation NSObject (SCSceneGraphDelegate)

/*" 
  The following delegate methods allow you to control superscenegraph creation.
"*/

/*" 
  Return !{NO} to skip superscenegraph creation.

  Important note: If you want to implement your own superscenegraph
  creation method, make sure to read the !{createSuperSceneGraph:}
  documentation!
"*/

- (BOOL)shouldCreateDefaultSuperSceneGraph
{
  
}

/*" 
  If present, this method will be called instead of the internal
  implementation to create a superscenegraph.

  The scenegraph argument is the root node of the Coin scene
  graph. The method is expected to return a new node that contains
  scenegraph as one of its children, or scenegraph itself.

  Important note: If the delegate implements
  !{shouldCreateDefaultSuperSceneGraph}, !{createSuperScenegraph:}
  will be ignored.

  (So if you want to implement your own superscenegraph creation
  method, #{DO NOT} implement !{shouldCreateDefaultSuperSceneGraph} to
  return !{NO}.  The right thing to do is to not have a
  !{shouldCreateDefaultSuperSceneGraph} implementation at all.)
"*/

- (SoGroup *)createSuperSceneGraph:(SoGroup *)scenegraph
{
  
}
/*" 

  Implement this method to do postprocessing after creation of superscenegraph.

  This method will be called both if superscenegraph was
  created using the internal default implementation, or the
  !{createSuperSceneGraph:} delegate method.

"*/
- (void)didCreateSuperSceneGraph:(SoGroup *)superscenegraph
{
  
}
@end
