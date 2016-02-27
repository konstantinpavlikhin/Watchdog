//
//  WDGRegistrationStatusController.m
//  Watchdog
//
//  Created by Konstantin Pavlikhin on 27/01/10.
//  Copyright (c) 2016 Konstantin Pavlikhin. All rights reserved.
//

#import "WDGRegistrationStatusController+Private.h"

#import "WDGRegistrationController.h"

#import "WDGResources.h"

@implementation WDGRegistrationStatusController

- (id) init
{
  self = [self initWithNibName: @"WDGRegistrationStatus" bundle: [WDGResources resourcesBundle]];
  
  return self;
}

- (void) awakeFromNib
{
  // Returns a localized version, if available.
  NSString* appName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"];
  
  self.message = [NSString stringWithFormat: NSLocalizedStringFromTableInBundle(@"You can use your serial to activate %@ on any personal Mac that you own. To use %@ from different accounts belonging to different persons, please consider buying additional serials.", nil, [WDGResources resourcesBundle], @"Both embedded objects are strings containing application name."), appName, appName];
}

- (IBAction) deauthorizeAccount: (id) sender
{
  [[WDGRegistrationController sharedRegistrationController] deauthorizeAccount];
}

- (IBAction) dismiss: (id) sender
{
  [[[[self view] window] windowController] close];
}

@end
