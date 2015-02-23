//
//  AppDelegate.m
//  Sample
//
//  Created by Konstantin Pavlikhin on 02.03.14.
//  Copyright (c) 2014 Konstantin Pavlikhin. All rights reserved.
//

#import "AppDelegate.h"

#import "../WDGRegistrationController.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  WDGRegistrationController* rc = [WDGRegistrationController sharedRegistrationController];
  
  [rc showRegistrationWindow: self];
}

@end
