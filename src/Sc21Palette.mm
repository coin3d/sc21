//
//  SC21Palette.m
//  SC21
//
//  Created by Karin Kosina on Wed Jun 18 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "SC21Palette.h"
#import "SCExaminerController.h"

@implementation SC21Palette

- (void)finishInstantiate
{
  scview = [[SCView alloc] initWithFrame:[viewbutton bounds]];
  [self associateObject:scview
                 ofType:IBViewPboardType
               withView:viewbutton];
  
  [self associateObject:[[SCController alloc] init]
                 ofType:IBObjectPboardType
               withView:controllerbutton];

  [self associateObject:[[SCExaminerController alloc] init] 	ofType:IBObjectPboardType
               withView:examinerbutton];

  NSLog(@"Calling reshape");
  [scview reshape];
}
@end

@implementation SCView (SC21PaletteInspector)

- (NSString *)inspectorClassName
{
    return @"SC21Inspector";
}

@end
