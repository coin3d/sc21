//
//  SC21Inspector.m
//  SC21
//
//  Created by Karin Kosina on Wed Jun 18 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "SC21Inspector.h"
#import "SCView.h"

@implementation SC21Inspector

- (id)init
{
    self = [super init];
    [NSBundle loadNibNamed:@"SC21Inspector" owner:self];
    return self;
}

- (void)ok:(id)sender
{
	/* Your code Here */
    [super ok:sender];
}

- (void)revert:(id)sender
{
	/* Your code Here */
    [super revert:sender];
}

@end
