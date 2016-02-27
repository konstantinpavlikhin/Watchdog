//
//  WDGSerialEntryController.m
//  Watchdog
//
//  Created by Konstantin Pavlikhin on 27/01/10.
//  Copyright (c) 2015 Konstantin Pavlikhin. All rights reserved.
//

#import "WDGSerialEntryController+Private.h"

#import "WDGRegistrationController.h"

#import "WDGPlistConstants.h"

#import "WDGShakeAnimation.h"

#import "WDGResources.h"

@implementation WDGSerialEntryController

- (id) init
{
  self = [self initWithNibName: @"WDGSerialEntry" bundle: [WDGResources resourcesBundle]];
  
  return self;
}

- (void) awakeFromNib
{
  NSString* str = NSLocalizedStringFromTableInBundle(@"Unlock %@", nil, [WDGResources resourcesBundle], @"Registration greeting. Parameter stays for the app name.");
  
  self.greeting = [NSString stringWithFormat: str, [self localizedAppName]];
}

- (NSString*) localizedAppName
{
  return [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"];
}

- (NSURL*) supportURL
{
  return [NSURL URLWithString: [[NSBundle mainBundle] objectForInfoDictionaryKey: WDGSupportURLKey]];
}

- (NSURL*) buyOnlineURL
{
  return [NSURL URLWithString: [[NSBundle mainBundle] objectForInfoDictionaryKey: WDGBuyOnlineURLKey]];
}

- (IBAction) lostKey: (id) sender
{
  [[NSWorkspace sharedWorkspace] openURL: [self supportURL]];
}

- (IBAction) buyOnline: (id) sender
{
  [[NSWorkspace sharedWorkspace] openURL: [self buyOnlineURL]];
}

- (IBAction) cancel: (id) sender
{
  [[[[self view] window] windowController] close];
}

+ (NSString*) sanitizeString: (NSString*) string
{
  NSCharacterSet* characterSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
  
  return [string stringByTrimmingCharactersInSet: characterSet];
}

- (IBAction) proceed: (id) sender
{
  NSString* name = [[self class] sanitizeString: [self.customerName stringValue]];
  
  NSString* serial = [[self class] sanitizeString: [self.licenseKey stringValue]];
  
  if([name length] < 1 || [serial length] < 1)
  {
    [self shakeWindow];
    
    return;
  };
  
  [self.spinner startAnimation: self];
  
  [self.proceed setEnabled: NO];
  
  // Pushing data to the WDRegistrationController.
  WDGRegistrationController* SRC = [WDGRegistrationController sharedRegistrationController];
  
  [SRC registerWithCustomerName: name serial: serial handler: ^(WDGSerialVerdict verdict)
  {
    dispatch_async(dispatch_get_main_queue(), ^()
    {
      [self.spinner stopAnimation: self];
      
      [self.proceed setEnabled: YES];
      
      if(verdict != WDGSerialVerdictValid)
      {
        [self shakeWindow];
        
        return;
      };
      
      [self clearInputFields];
    });
  }];
}

- (void) shakeWindow
{
  NSWindow* window = [[self view] window];
  
  [window setAnimations: [NSDictionary dictionaryWithObject: shakeAnimation([window frame], 4, 0.4, 0.05) forKey: @"frameOrigin"]];
  
  [[window animator] setFrameOrigin: [window frame].origin];
}

- (void) clearInputFields
{
  [self.customerName setStringValue: @""];
  
  [self.licenseKey setStringValue: @""];
}

@end
