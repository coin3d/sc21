/* =============================================================== *
 |                                                                 |
 | This file is part of Sc21, a Cocoa user interface binding for   |
 | the Coin 3D visualization library.                              |
 |                                                                 |
 | Copyright (c) 2003-2009 Kongsberg SIM AS . All rights reserved. |
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
 | of our support services, please contact Kongsberg SIM AS        |
 | about acquiring a Coin Professional Edition License.            |
 |                                                                 |
 | See http://www.coin3d.org/mac/Sc21 for more information.        |
 |                                                                 |
 | Kongsberg SIM AS , Bygdoy Alle 5, 0257 Oslo, Norway.            |
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

#import <Inventor/VRMLnodes/SoVRMLGroup.h>

#import "SCSceneGraphP.h"

void error_cb(const class SoError * error, void * data)
{
  SCSceneGraph * scenegraph = (SCSceneGraph *)data;
  NSString * errstr = [[NSString alloc] 
                        initWithCString: 
                          error->getDebugString().getString()
                        encoding:
                          NSUTF8StringEncoding];
  [[NSNotificationCenter defaultCenter]
   postNotificationName:SCReadErrorNotification object:scenegraph
   userInfo:[NSDictionary dictionaryWithObject:errstr forKey:@"description"]];
}

@implementation SCSceneGraphP
@end

#define PRIVATE(p) ((p)->_sc_scenegraph)
#define SELF PRIVATE(self)

@implementation SCSceneGraph

/*" 
  An SCSceneGraph encapsulates a Coin scenegraph and provides
 an abstraction for reading Inventor and VRML files.

  #{Superscenegraph creation} 

  When a scene is read that contains no light or no camera, nothing
  would be visible, so by default SCSceneGraph inserts a light or
  camera if none is found. This is called %{superscenegraph creation}
  can be controlled in several ways:

  The delegate method !{shouldCreateDefaultSuperSceneGraph} determines
  whether or not the internal default superscenegraph creation code
  should be run. If no such delegate method is found, the value of the
  checkbox in SCSceneGraph's IB inspector is used. The default setting
  is to create the default superscenegraph.

  In addition, the !{createSuperSceneGraph} delegate method lets you
  specify your own superscenegraph creation code.

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
  is posted. If an error occurs while reading the file, an
  !{SCReadErrorNotification} is posted. (Note that such an error does
  not necessarily mean that loading the file fails.)

  If no valid scenegraph can be read from the file (either because the
  file cannot be opened or a fatal error occured when reading the
  file), the receiver is freed, and !{nil} is returned.
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

  If an error occurs while reading the URL, an
  !{SCReadErrorNotification} is posted. (Note that such an error does
  not necessarily mean that loading the file fails.)

  If the URL does not contain a valid scenegraph, the receiver is
  freed, and nil is returned.
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
  [super dealloc];
}

#pragma mark --- file system access --- 

/*"
  Read a new Coin scenegraph from the file name.

  Posts an !{SCCouldNotOpenFileNotification} if the file cannot be
  read.

  Posts an !{SCReadErrorNotification} if an error occurs when reading
  the file. (Note that such an error does not necessarily mean that
  loading the file will fail. Check the value returned by this method
  to find out whether reading was successful or not.)

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

  Posts an !{SCReadErrorNotification} if an error occurs when reading
  the file. (Note that such an error does not necessarily mean that
  loading the file will fail. Check the value returned by this method
  to find out whether reading was successful or not.)

  Returns !{YES} if reading the scenegraph was successful, and !{NO}
  otherwise.
"*/

- (BOOL)readFromURL:(NSURL *)URL
{
  NSData * data = [NSData dataWithContentsOfURL:URL];
  if (data) {
    return [self loadDataRepresentation:data];
  }
  return NO;
}

/*" 
  Read scene from data using !{SoInput::setBuffer()}.

  Posts an !{SCReadErrorNotification} if an error occurs when reading
  data. (Note that such an error does not necessarily mean that
  loading the buffer will fail. Check the value returned by this
  method to find out whether reading was successful or not.)

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

/*" 
   Positions the current camera so that the whole scene is visible, by sending 
   !{viewAll:self} to the receiver's SCCamera.
"*/

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

  Note that this is the root as previously set by !{setRoot:}, or the
  top node of the scenegraph read from a file, URL, or memory
  buffer. It thus does %not contain the superscenegraph. If for some
  reason you want to access the complete scenegraph (including the
  superscenegraph) that is actually used for rendering, you can get it
  by calling !{SoSceneManager::getSceneGraph()}.

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

  Returns !{YES} if the scenegraph was set successfully, and !{NO} if
  an unexpected problem occured. (Currently the only reason when !{NO}
  would be returned is when the delegate method
  !{createSuperSceneGraph:} returns !{NULL}, which is interpreted as
  an indication that setting the new scenegraph should be aborted.)

  Note that it is perfectly fine to pass !{NULL} as root, in which
  case the old scenegraph will be released and the scenegraph set to
  !{NULL}. Since this is considered a valid operation, !{setRoot:}
  will return !{YES} in this case.

  On return values of !{YES}, both the passed and the actual scene
  graph will be !{ref()}'ed. On !{NO}, the passed scene graph will not
  be !{ref()}'ed.
"*/

// FIXME: The parameter of this method should probably be of type
// SoNode * instead of SoGroup *. Arguments for this: 
//
//   (1) SoSceneManager::setSceneGraph(SoNode *) 
//   (2) allowing Coin extensions that are conceptionally a root node
//       but don't derive from SoGroup (nodekits, app programmer
//       creating a "group-like" node derived from SoNode)
//
// Since this breaks ABI, API, and source-code compatibility (code
// relying on -root: returning an SoGroup * would need to be
// rewritten), such a change can only go into the next major release.
// 20061109 kyrah

- (BOOL)setRoot:(SoGroup *)root
{
  SC21_DEBUG(@"SCSceneGraph.setRoot: %p", root);
  BOOL retval = YES;

  // just to be sure we don't accidentally delete root when
  // unref()'ing scenegraph below (in case root == scenegraph)
  if (root) root->ref(); 

  // Clean up existing scenegraph
  if (SELF->superscenegraph) { SELF->superscenegraph->unref(); }
  SELF->scenegraph = SELF->superscenegraph = NULL;  
  SELF->headlight = NULL;
  SELF->addedlight = NO;
  
  if (root) { 

    // --- Find out who will create a superscenegraph ---
    
    // SELF->createsuperscenegraph is controlled through the IB inspector.
    BOOL createdefaultsupersg = SELF->createsuperscenegraph;
    BOOL createdelegatesupersg = NO;
    
    if (self->delegate) {
      // Give delegate the chance to turn off default superscenegraph
      // creation: shouldCreateDefaultSuperSceneGraph returns whether we
      // should create the default superscenegraph or not. 
      if ([self->delegate respondsToSelector:
                 @selector(shouldCreateDefaultSuperSceneGraph)]) {
        createdefaultsupersg = [delegate shouldCreateDefaultSuperSceneGraph];
      }

      // Let delegate do its own superscenegraph setup work.
      if ([self->delegate respondsToSelector:
                 @selector(createSuperSceneGraph:)]) {
        createdelegatesupersg = YES;
      }    
    }

    // --- Superscenegraph creation --- 

    if (!createdefaultsupersg && !createdelegatesupersg) {
      SELF->superscenegraph = root;
    }
    else {
      SoGroup * defaultsupersg = root;
      if (createdefaultsupersg) {
        defaultsupersg = [self _SC_createSuperSceneGraph:root];
      }
      defaultsupersg->ref();
      if (createdelegatesupersg) {
        // Let delegate create its own superscenegraph structure, either 
        // based on the "blank" user-supplied scenegraph or the internally
        // generated superscenegraph.
        SELF->superscenegraph = [delegate createSuperSceneGraph:defaultsupersg];
      }
      else {
        SELF->superscenegraph = defaultsupersg;
      }
      defaultsupersg->unrefNoDelete();
    }

    // If superscenegraph was correctly set, set scenegraph here since
    // it may be accessed from a notification handler below.
    if (SELF->superscenegraph) {
      SELF->superscenegraph->ref();
      SELF->scenegraph = root;
    }

    // If superscenegraph == NULL at this point, it is because the
    // delegate returned NULL for superscenegraph. We regard that as a
    // sign that something is very wrong. No scenegraph has been set
    // and we return NO.
    else {
      retval = NO; // The only reason why we may fail
    }

    // --- Camera and light handling ---

    if (SELF->superscenegraph) {
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
    }
  }
    
  [[NSNotificationCenter defaultCenter]
    postNotificationName:SCRootChangedNotification object:self];
  
  // ref()'ed at the start of this method to avoid accidental deletion
  if (root) root->unrefNoDelete(); 
  
  return retval;
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

#if FOR_AUTODOC_ONLY  

// Dummy implementations to force AutoDoc to generate documentation for 
// delegate methods.

@implementation NSObject (SCSceneGraphDelegate)

/*" 
  The following delegate methods allow you to control superscenegraph creation.
"*/

/*" 
  Implement this method to return !{NO} to skip creation of the
  internal default superscenegraph.

  Note that this does not turn on or off custom superscenegraph
  creation (done by the !{createSuperSceneGraph:} delegate method, if
  present).
"*/

- (BOOL)shouldCreateDefaultSuperSceneGraph
{
  
}


/*" 
  If present, this method will be called from setRoot to allow the
  delegate to do custom superscenegraph creation.

  Note that this does not influence the creation of the default
  superscenegraph (i.e. the internal behaviour of adding a light and
  camera if necessary). Use the shouldCreateDefaultSuperSceneGraph:
  method to control whether the internal superscenegraph creation
  should be performed.

  Depending on whether an internal superscenegraph has been added,
  !{createSuperSceneGraph:} will be called either with the original root
  or (if the default scenegraph was created) with the root of the
  internal superscenegraph.

  The scenegraph argument is the root node of the Coin scene
  graph. The method is expected to return a new node that contains
  scenegraph as one of its children, or scenegraph itself. If the
  return value is !{NULL}, SCSceneGraph's !{setRoot:} will be aborted and
  the scenegraph and superscenegraph set to !{NULL}. Note that normally
  you should never return !{NULL} from this method - use this only to
  indicate unexpected error conditions.
"*/

- (SoGroup *)createSuperSceneGraph:(SoGroup *)scenegraph
{
  
}

@end
#endif // FOR_AUTODOC_ONLY  
