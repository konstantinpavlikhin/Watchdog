////////////////////////////////////////////////////////////////////////////////
//  
//  LicenseEnterController.h
//  
//  Watchdog
//  
//  Created by Konstantin Pavlikhin on 27/01/10.
//  
////////////////////////////////////////////////////////////////////////////////

@interface LicenseEnterController : ViewController
{
  IBOutlet NSTextField* licenseKey;
  
  IBOutlet NSProgressIndicator* spinner;
  
  IBOutlet NSButton* proceed;
}

@property(readwrite, retain) NSString* greeting;

@property(readwrite, assign) IBOutlet NSTextField* customerName;

- (IBAction) lostKey: (id) sender;

- (IBAction) buyOnline: (id) sender;

- (IBAction) cancel: (id) sender;

- (IBAction) proceed: (id) sender;

- (NSString*) cleanKeyFromDashes: (NSString*) keyWithDashes;

- (void) shakeWindow;

- (void) clearInputFields;

@end
