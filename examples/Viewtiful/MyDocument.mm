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
  SbString hdr([header UTF8String]);
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
