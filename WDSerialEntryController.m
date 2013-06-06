////////////////////////////////////////////////////////////////////////////////
//  
//  WDSerialEntryController.m
//  
//  Watchdog
//  
//  Created by Konstantin Pavlikhin on 27/01/10.
//  
////////////////////////////////////////////////////////////////////////////////

#import "WDSerialEntryController.h"

#import "WDRegistrationController.h"

#import "WDPlistConstants.h"

@implementation WDSerialEntryController

- (id) init
{
  self = [self initWithNibName: @"WDSerialEntry" bundle: [NSBundle bundleForClass: [self class]]];
  
  return self;
}

- (void) viewDidLoad
{
  NSString* str = NSLocalizedStringFromTableInBundle(@"Unlock %@", nil, [NSBundle bundleForClass: [self class]], @"Registration greeting. Parameter stays for the app name.");
  
  self.greeting = [NSString stringWithFormat: str, [self localizedAppName]];
}

- (NSString*) localizedAppName
{
  return [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"];
}

- (NSURL*) supportURL
{
  return [NSURL URLWithString: [[NSBundle mainBundle] objectForInfoDictionaryKey: WDSupportURLKey]];
}

- (NSURL*) buyOnlineURL
{
  return [NSURL URLWithString: [[NSBundle mainBundle] objectForInfoDictionaryKey: WDBuyOnlineURLKey]];
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
  [self.windowController close];
}

- (IBAction) proceed: (id) sender
{
  #warning TODO: sanitize values!
  NSString* name = [self.customerName stringValue];
  
  NSString* serial = [self.licenseKey stringValue];
  
  // Dumb check.
  if(![name length] || ![serial length]) { [self shakeWindow]; return; };
  
  [self.spinner startAnimation: self];
  
  [self.proceed setEnabled: NO];
  
  // Pushing data to the WDRegistrationController.
  WDRegistrationController* SRC = [WDRegistrationController sharedRegistrationController];
  
  [SRC registerWithCustomerName: name serial: serial handler: ^(enum SerialVerdict verdict)
  {
    dispatch_sync(dispatch_get_main_queue(), ^()
    {
      [self.spinner stopAnimation: self];
      
      [self.proceed setEnabled: YES];
      
      if(verdict != ValidSerialVerdict) { [self shakeWindow]; return; };
      
      [self clearInputFields];
    });
  }];
}

- (void) shakeWindow
{
  NSWindow* window = [[self windowController] window];
  
  [window setAnimations: [NSDictionary dictionaryWithObject: shakeAnimation([window frame], 4, 0.4, 0.05) forKey: @"frameOrigin"]];
  
  [[window animator] setFrameOrigin: [window frame].origin];
}

- (void) clearInputFields
{
  [self.customerName setStringValue: @""];
  
  [self.licenseKey setStringValue: @""];
}

@end
