// Notification names in SCSceneGraph
NSString * SCCouldNotOpenFileNotification = @"SCCouldNotOpenFileNotification";
NSString * SCCouldNotReadFileNotification = @"SCCouldNotReadFileNotification";
NSString * SCNoCameraFoundInSceneNotification = @"SCNoCameraFoundInSceneNotification";
NSString * SCNoLightFoundInSceneNotification = @"SCNoLightFoundInSceneNotification";

// Notification names in SCController and SCSceneGraph
NSString * SCSceneGraphChangedNotification = @"SCSceneGraphChangedNotification";

// Notification names in SCController
NSString * SCModeChangedNotification = @"SCModeChangedNotification";
NSString * SCDrawableChangedNotification = @"SCDrawableChangedNotification";

// Notification names in SCCamera
NSString * SCViewAllNotification = @"SCViewAllNotification";
NSString * SCCameraTypeChangedNotification = @"SCCameraTypeChangedNotification";

// Notification names in SCEventHandling
NSString * SCCursorChangedNotification = @"SCCursorChangedNotification";

// Internally used notifications
// Note that the variable name is intentionally not starting with _ since
// C++ reserves '_' usage in the global namespace. 
NSString * SCRootChangedNotification = @" _SC_RootChangedNotification";

