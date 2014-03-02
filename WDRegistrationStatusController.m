////////////////////////////////////////////////////////////////////////////////
//  
//  WDRegistrationStatusController.m
//  
//  Watchdog
//  
//  Created by Konstantin Pavlikhin on 27/01/10.
//  
////////////////////////////////////////////////////////////////////////////////

#import "WDRegistrationStatusController+Private.h"

#import "WDRegistrationController.h"

#import "WDResources.h"

@implementation WDRegistrationStatusController

- (id) init
{
  self = [self initWithNibName: @"WDRegistrationStatus" bundle: [WDResources resourcesBundle]];
  
  return self;
}

- (void) awakeFromNib
{
  // Returns a localized version, if available.
  NSString* appName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"];
  
  self.message = [NSString stringWithFormat: NSLocalizedStringFromTableInBundle(@"You can use your serial to activate %@ on any personal Mac that you own. To use %@ from different accounts belonging to different persons, please consider buying additional serials.", nil, [WDResources resourcesBundle], @"Both embedded objects are strings containing application name."), appName, appName];
}

- (IBAction) deauthorizeAccount: (id) sender
{
  [[WDRegistrationController sharedRegistrationController] deauthorizeAccount];
}

- (IBAction) dismiss: (id) sender
{
  [[[[self view] window] windowController] close];
}

@end
