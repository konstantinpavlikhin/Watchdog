////////////////////////////////////////////////////////////////////////////////
//  
//  LicenseStatusController.h
//  
//  Watchdog
//  
//  Created by Konstantin Pavlikhin on 27/01/10.
//  
////////////////////////////////////////////////////////////////////////////////

@interface LicenseStatusController : ViewController
{
  IBOutlet NSTextField* licensedTo;
}

@property(readwrite, retain) NSString* message;

@property(readwrite, assign) IBOutlet NSButton* dismissButton;

- (IBAction) deauthorizeAccount: (id) sender;

- (IBAction) dismiss: (id) sender;

- (void) viewDidAppear;

@end
