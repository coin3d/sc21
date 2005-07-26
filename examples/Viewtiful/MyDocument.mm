/* =============================================================== *
 |                                                                 |
 | This file is part of Sc21, a Cocoa user interface binding for   |
 | the Coin 3D visualization library.                              |
 |                                                                 |
 | Copyright (c) 2003-2005 Systems in Motion. All rights reserved. |
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

#import "MyDocument.h"
#import "MyWindowController.h"
#import <Inventor/SoDB.h>
#import <Inventor/SoInput.h>
#import <Inventor/nodes/SoSeparator.h>
#import <Inventor/actions/SoWriteAction.h>

@implementation MyDocument

- (id)init
{
  if (self = [super init]) {
    scenegraph = [[SCSceneGraph alloc] init];
  }
  return self;
}

- (void)dealloc
{
  [header release];
  [scenegraph release];
  [super dealloc];
}

- (NSString *)fileType
{
  return filetype;
}

// Returns a readable file size string
- (NSString *)fileSize
{
  NSString *sizestr = nil;
  if (filesize > 10*1024*1024) {
    sizestr = [NSString stringWithFormat:@"%.1f MB", (float)filesize/(1024*1024)];
  }
  else if (filesize > 30*1024) {
    sizestr = [NSString stringWithFormat:@"%.0f KB", (float)filesize/1024];
  }
  else {
    sizestr = [NSString stringWithFormat:@"%d", filesize];
  }
  return sizestr;
}

- (SCSceneGraph *)sceneGraph
{
  return scenegraph;
}

- (void)setSceneGraph:(SCSceneGraph *)sg
{
  scenegraph = sg;
}

// Overridden from NSDocument to read our files using SoInput
- (BOOL)readFromFile:(NSString *)fileName ofType:(NSString *)docType
{
  NSLog(@"MyDocument.readFromFile:%@ ofType:%@", fileName, docType);
  // Check for supported file formats
  if ([docType isEqualToString:@"VRML"] ||
      [docType isEqualToString:@"VRML V1.0"] ||
      [docType isEqualToString:@"VRML V2.0"] ||
      [docType isEqualToString:@"Inventor"]) {
    if ([scenegraph readFromFile:fileName]) {
      filetype = docType;
      NSDictionary *attr = [[NSFileManager defaultManager] 
                             fileAttributesAtPath:fileName traverseLink:YES];
      filesize = [[attr objectForKey:NSFileSize] intValue];
      return YES;
    }
  }
  else {
    NSLog(@"Unknown file type \"%@\"", docType);
  }
  return NO;
}

// This methods of reading files are typically used when reading
// from the pasteboard.
- (BOOL)loadDataRepresentation:(NSData *)docData ofType:(NSString *)docType
{
  if ([scenegraph loadDataRepresentation:docData]) {
    filetype = docType;
    filesize = [docData length];
    return YES;
  }
  return NO;
}

// Overridden to use our own WindowController
- (void)makeWindowControllers
{
  MyWindowController *mwc = [[MyWindowController alloc] init];
  [self addWindowController:mwc];
  [mwc release];
}

// FIXME: Since we are read-only, we shouldn't need to do this (kintel 20031211)
- (BOOL)validateMenuItem:(NSMenuItem *)item
{
  SEL action = [item action];
  if (action == @selector(saveDocumentAs:)) return NO;
  else return [super validateMenuItem:item];
}

// The realloc function and static variables are used by SoOutput
// in memory buffer mode.
static char *buffer;
static size_t buffer_size = 0;

static void *
buffer_realloc(void *bufptr, size_t size)
{
  buffer = (char *)realloc(bufptr, size);
  buffer_size = size;
  return buffer;
}

// Non-lazy copy to pasteboard
// FIXME: Support other file formats than VRML1 (kintel 20031112)
- (IBAction)copy:(id)sender
{
  NSLog(@"MyDocument.copy");
  NSPasteboard *pb = [NSPasteboard generalPasteboard];
  NSArray * types = [NSArray arrayWithObjects:NSStringPboardType,
    @"VRML1PboardType", nil];
  [pb declareTypes:types owner:self];
  [pb setString:[self fileName] forType:NSStringPboardType];

  SoOutput out;
  buffer = (char *)malloc(102400);
  buffer_size = 102400;
  out.setBuffer(buffer, buffer_size, buffer_realloc);
  SbString hdr([header cString]);
  out.setHeaderString(hdr);
  SoWriteAction wra(&out);
  wra.apply([scenegraph root]);

  [pb setData:[NSData dataWithBytesNoCopy:buffer length:buffer_size] 
      forType:@"VRML1PboardType"];
}

// Refresh document from disk
- (IBAction)refreshDocument:(id)sender
{
  NSLog(@"MyDocument.refreshDocument");
  if ([self revertToSavedFromFile:[self fileName] ofType:[self fileType]]) {
    [self updateChangeCount:NSChangeCleared];
    NSArray *controllers = [self windowControllers];
    if (controllers) {
      NSEnumerator *enumerator = [controllers objectEnumerator];
      MyWindowController *controller;
      while (controller = [enumerator nextObject]) 
        [controller documentChanged:self];
    }
  }
}

@end
