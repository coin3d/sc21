/* ============================================================== *
 |                                                                |
 | This file is part of SC21, a Cocoa user interface binding for  |
 | the Coin 3D visualization library.                             |
 |                                                                |
 | Copyright (c) 2003 Systems in Motion. All rights reserved.     |
 |                                                                |
 | SC21 is free software; you can redistribute it and/or          |
 | modify it under the terms of the GNU General Public License    |
 | ("GPL") version 2 as published by the Free Software            |
 | Foundation.                                                    |
 |                                                                |
 | A copy of the GNU General Public License can be found in the   |
 | source distribution of SC21. You can also read it online at    |
 | http://www.gnu.org/licenses/gpl.txt.                           |
 |                                                                |
 | For using Coin with software that can not be combined with the |
 | GNU GPL, and for taking advantage of the additional benefits   |
 | of our support services, please contact Systems in Motion      |
 | about acquiring a Coin Professional Edition License.           |
 |                                                                |
 | See http://www.coin3d.org/mac/SC21 for more information.       |
 |                                                                |
 | Systems in Motion, Bygdoy Alle 5, 0257 Oslo, Norway.           |
 |                                                                |
 * ============================================================== */

#import "MyDocument.h"
#import "MyWindowController.h"
#import <Inventor/SoDB.h>
#import <Inventor/SoInput.h>
#import <Inventor/nodes/SoSeparator.h>
#import <Inventor/actions/SoWriteAction.h>

@implementation MyDocument

- (id)init
{
    self = [super init];
    return self;
}

- (void)dealloc
{
  NSLog(@"MyDocument.dealloc");
  [_header release];
  [super dealloc];
}

- (NSString *)fileType
{
    return _filetype;
}

// Returns a readable file size string
- (NSString *)fileSize
{
    NSString *sizestr = nil;
    if (_filesize > 10*1024*1024) {
        sizestr = [NSString stringWithFormat:@"%.1f MB", (float)_filesize/(1024*1024)];
    }
    else if (_filesize > 30*1024) {
        sizestr = [NSString stringWithFormat:@"%.0f KB", (float)_filesize/1024];
    }
    else {
        sizestr = [NSString stringWithFormat:@"%d", _filesize];
    }
    return sizestr;
}

- (SoSeparator *)sceneGraph
{
    return _root;
}

- (void)setSceneGraph:(SoSeparator *)root
{
  NSLog(@"MyDocument.setSceneGraph:%p", root);
  root->unref();
  _root = root;
  if (_root) _root->ref();
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
    SoInput input;
    if (input.openFile([fileName UTF8String])) { // Coin doesn't like unicode, so convert to utf8 and hope for the best
      if (![self performRead:input]) {
        NSLog(@"Unable to read file \"%@\"", fileName);
        return NO;
      }
      else return YES;
    }
    else {
      NSLog(@"Unable to open file \"%@\"", fileName);
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
  NSLog(@"MyDocument.loadDataRepresentation:ofType:%@", docType);
  SoInput input;
  input.setBuffer((void *)[docData bytes], [docData length]);
  return [self performRead:input];
}

// Generalized file reading method
- (BOOL)performRead:(SoInput &)input
{
  SoSeparator *root = SoDB::readAll(&input);
  if (root) {
    if (input.isFileVRML1()) _filetype = @"VRML V1.0";
    else if (input.isFileVRML2()) _filetype = @"VRML V2.0";
    else _filetype = @"Inventor";
    _filesize = input.getNumBytesRead();
    _header = [[NSString stringWithCString:input.getHeader().getString()] retain];
    [self setSceneGraph:root];
    return YES;
  }
  return NO;  
}

// Overridden to use our own WindowController
- (void)makeWindowControllers
{
  NSLog(@"MyDocument.makeWindowControllers");
  MyWindowController *mwc = [[MyWindowController alloc] init];
  [self addWindowController:mwc];
  [mwc release];
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
  NSLog(@"MyDocument.windowControllerDidLoadNib");
}

- (void)windowControllerWillLoadNib:(NSWindowController *) aController
{
  NSLog(@"MyDocument.windowControllerWillLoadNib");
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
  [pb declareTypes:[NSArray arrayWithObjects:NSStringPboardType, @"VRML1PboardType", nil] owner:self];
  [pb setString:[self fileName] forType:NSStringPboardType];

  SoOutput out;
  buffer = (char *)malloc(102400);
  buffer_size = 102400;
  out.setBuffer(buffer, buffer_size, buffer_realloc);
  SbString hdr([_header cString]);
  out.setHeaderString(hdr);
  SoWriteAction wra(&out);
  wra.apply(_root);

  [pb setData:[NSData dataWithBytesNoCopy:buffer length:buffer_size] forType:@"VRML1PboardType"];
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
      while (controller = [enumerator nextObject]) [controller documentChanged:self];
    }
  }
}

@end
