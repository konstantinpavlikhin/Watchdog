////////////////////////////////////////////////////////////////////////////////
//  
//  LicenseStatusController.m
//  
//  Watchdog
//  
//  Created by Konstantin Pavlikhin on 27/01/10.
//  
////////////////////////////////////////////////////////////////////////////////

#import "LicenseStatusController.h"

#import "LicenseController.h"

@implementation LicenseStatusController

@synthesize message;

@synthesize dismissButton;

- (id) init
{
  self = [self initWithNibName: @"LicenseStatus" bundle: [NSBundle bundleWithIdentifier: @"com.konstantinpavlikhin.Watchdog"]];
  
  NSString* appName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"];
  
  self.message = [NSString stringWithFormat: @"You can use your serial number to activate %@ on any personal Mac that you own. To use %@ from different accounts belonging to different persons, please consider buying additional licenses.", appName, appName];
  
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
