#import <Foundation/Foundation.h>
#import <Inventor/events/SoEvents.h>
#import <Inventor/events/SoKeyboardEvent.h>
#import <Inventor/SbDict.h>

@class SCController;

@interface SCEventConverter : NSObject {
  SCController * _controller;
  SbDict * _keydict, * _printabledict;
}

/*" Initializing an SCEventConverter "*/
- (id) initWithController:(SCController *)ctrl;

/*" Event conversion "*/
- (SoEvent *) createSoEvent:(NSEvent *)event;
- (SoKeyboardEvent *) createSoKeyboardEventWithString:(NSString *)s;

/*" Setting the controller component "*/
- (void) setController:(SCController *) controller;
- (SCController *) controller;

@end


