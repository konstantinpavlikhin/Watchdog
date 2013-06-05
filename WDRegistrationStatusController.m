////////////////////////////////////////////////////////////////////////////////
//  
//  WDRegistrationStatusController.m
//  
//  Watchdog
//  
//  Created by Konstantin Pavlikhin on 27/01/10.
//  
////////////////////////////////////////////////////////////////////////////////

#import "WDRegistrationStatusController.h"

#import "WDRegistrationController.h"

@implementation WDRegistrationStatusController

- (id) init
{
  self = [self initWithNibName: @"WDRegistrationStatus" bundle: [NSBundle bundleForClass: [self class]]];
  
  return self;
}

- (void) dealloc
{
  [_message release], _message = nil;
  
  [super dealloc];
}

- (void) viewDidLoad
{
  // Returns a localized version, if available.
  NSString* appName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"];
  
  self.message = [NSString stringWithFormat: NSLocalizedStringFromTableInBundle(@"You can use your serial to activate %@ on any personal Mac that you own. To use %@ from different accounts belonging to different persons, please consider buying additional serials.", nil, [NSBundle bundleForClass: [self class]], @"Both embedded objects are strings containing application name."), appName, appName];
}

- (IBAction) deauthorizeAccount: (id) sender
{
  [[WDRegistrationController sharedRegistrationController] deauthorizeAccount];
}

- (IBAction) dismiss: (id) sender
{
  [self.windowController close];
}

@end
