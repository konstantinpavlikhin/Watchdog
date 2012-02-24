////////////////////////////////////////////////////////////////////////////////
//  
//  LicenseEnterController.m
//  
//  Watchdog
//  
//  Created by Konstantin Pavlikhin on 27/01/10.
//  
////////////////////////////////////////////////////////////////////////////////

#import "LicenseEnterController.h"

#import "LicenseController.h"

NSString* const watchdogBundleIdentifier = @"com.konstantinpavlikhin.Watchdog";

@implementation LicenseEnterController

@synthesize greeting;

@synthesize customerName;

- (id) init
{
  self = [self initWithNibName: @"LicenseEnter" bundle: [NSBundle bundleWithIdentifier: watchdogBundleIdentifier]];
  
  self.greeting = [NSString stringWithFormat: @"Register %@", [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"]];
  
  return self;
}

- (IBAction) lostKey: (id) sender
{
  NSString* str = [[NSBundle bundleWithIdentifier: watchdogBundleIdentifier] objectForInfoDictionaryKey: @"WDHelpOnlineURL"];
  
  [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: str]];
}

- (IBAction) buyOnline: (id) sender
{
  NSString* str = [[NSBundle bundleWithIdentifier: watchdogBundleIdentifier] objectForInfoDictionaryKey: @"WDBuyOnlineURL"];
  
  [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: str]];
}

- (IBAction) cancel: (id) sender
{
  [self.windowController close];
}

- (IBAction) proceed: (id) sender
{
  NSString* enteredName = [customerName stringValue];
  
  NSString* cleanKey = [self cleanKeyFromDashes: [licenseKey stringValue]];
  
  if(![enteredName length] || ![cleanKey length])
  {
    [self shakeWindow];
    
    return;
  }
  
  //////////////////////////////////////////////////////////////////////////////
  
  void (^handler)(BOOL result) = ^(BOOL result)
  {
    [spinner stopAnimation: self];
    
    [proceed setEnabled: YES];
    
    if(result)
    {
      [self clearInputFields];
    }
    else
    {
      [self shakeWindow];
    }
  };
  
  [spinner startAnimation: self];
  
  [proceed setEnabled: NO];
  
  //////////////////////////////////////////////////////////////////////////////
  
  LicenseController* SLC = [LicenseController sharedLicenseController];
  
  [SLC registerWithCustomerName: enteredName licenseKeyInBase32: cleanKey completionHandler: [[handler copy] autorelease]];
}

- (NSString*) cleanKeyFromDashes: (NSString*) keyWithDashes
{
  return [keyWithDashes stringByReplacingOccurrencesOfString: @"-" withString: @""];
}

- (void) shakeWindow
{
  NSWindow* window = [[self windowController] window];
  
  [window setAnimations: [NSDictionary dictionaryWithObject: shakeAnimation([window frame], 4, 0.4, 0.05) forKey: @"frameOrigin"]];
  
  [[window animator] setFrameOrigin: [window frame].origin];
}

- (void) clearInputFields
{
  [customerName setStringValue: @""];
  
  [licenseKey setStringValue: @""];
}

@end
