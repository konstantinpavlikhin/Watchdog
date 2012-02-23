//
//  LicenseEnterController.m
//  Singlemizer
//
//  Created by Константин Павлихин on 27.01.10.
//  Copyright 2010 Minimalistic Dev. All rights reserved.
//

#import "LicenseEnterController.h"

#import "LicenseController.h"

@implementation LicenseEnterController

@synthesize customerName;

- (id) init
{
  self = [self initWithNibName: @"LicenseEnter" bundle: [NSBundle bundleWithIdentifier: @"com.konstantinpavlikhin.Watchdog"]];
  
  return self;
}

- (IBAction) lostKey: (id) sender
{
  [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://minimalisticdev.com/support/"]];
}

- (IBAction) buyOnline: (id) sender
{
  [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString: @"http://minimalisticdev.com/singlemizer/order/"]];
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
