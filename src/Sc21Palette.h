//
//  SC21Palette.h
//  SC21
//
//  Created by Karin Kosina on Wed Jun 18 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <InterfaceBuilder/InterfaceBuilder.h>
#import "SCView.h"

@interface SC21Palette : IBPalette
{
  IBOutlet NSButton *viewbutton;
  IBOutlet NSButton *controllerbutton;
  IBOutlet NSButton *examinerbutton;
  SCView *scview;
}
@end

@interface SCView (SC21PaletteInspector)
- (NSString *)inspectorClassName;
@end
