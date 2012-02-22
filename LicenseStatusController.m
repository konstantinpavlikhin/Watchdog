//
//  LicenseStatusController.m
//  Singlemizer
//
//  Created by Константин Павлихин on 27.01.10.
//  Copyright 2010 Minimalistic Dev. All rights reserved.
//

#import "LicenseStatusController.h"

#import "LicenseController.h"

@implementation LicenseStatusController

@synthesize dismissButton;

- (id) init
{
  self = [self initWithNibName: @"LicenseStatus" bundle: nil];
  
  return self;
}

- (IBAction) deauthorizeAccount: (id) sender
{
  [[LicenseController sharedLicenseController] deauthorizeAccount];
}

- (IBAction) dismiss: (id) sender
{
  [self.windowController close];
}

- (void) viewDidAppear
{
  [licensedTo setStringValue: [[LicenseController sharedLicenseController] registeredCustomerName]];
}

@end
