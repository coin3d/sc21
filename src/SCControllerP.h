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

// No #imports here. Include this file _after_ SCController.h
// to ensure everything is included.
 
@interface _SCControllerP : NSObject
{
  id delegate;
  id redrawhandler;
  SEL redrawsel;
  NSInvocation * redrawinv;
  SCCamera * camera;
  SCEventConverter * eventconverter;
  NSTimer * timerqueuetimer;
  class SoGroup * scenegraph;	      // the user scenegraph 
  class SoGroup * superscenegraph;	  // the real scenegraph
  class SoSceneManager * scenemanager;
  BOOL handleseventsinviewer;
  float autoclipvalue;
  NSRect viewrect;
  SoDirectionalLight * headlight;  
  NSResponder * oldcontroller;
}
@end

@interface SCController (InternalAPI)
- (void)_SC_commonInit;
- (void)_SC_timerQueueTimerFired:(NSTimer *)t;
- (void)_SC_idle:(NSNotification *)notification;
- (void)_SC_sensorQueueChanged;
- (SoLight *)_SC_findLightInSceneGraph:(SoGroup *)root;
- (SoCamera *)_SC_findCameraInSceneGraph:(SoGroup *)root;
- (NSPoint)_SC_normalizePoint:(NSPoint)point;
- (void)_SC_setupRedrawInvocation;
- (SoGroup *)_SC_createSuperSceneGraph:(SoGroup *)scenegraph;
@end  
