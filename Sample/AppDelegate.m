//
//  AppDelegate.m
//  Sample
//
//  Created by Konstantin Pavlikhin on 02.03.14.
//  Copyright (c) 2014 Konstantin Pavlikhin. All rights reserved.
//

#import "AppDelegate.h"

#import "../WDRegistrationController.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  WDRegistrationController* rc = [WDRegistrationController sharedRegistrationController];
  
  [rc showRegistrationWindow: self];
}

@end
