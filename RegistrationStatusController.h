////////////////////////////////////////////////////////////////////////////////
//  
//  RegistrationStatusController.h
//  
//  Watchdog
//  
//  Created by Konstantin Pavlikhin on 27/01/10.
//  
////////////////////////////////////////////////////////////////////////////////

@interface RegistrationStatusController : ViewController

@property(readwrite, retain) NSString* message;

@property(readwrite, assign) IBOutlet NSButton* dismissButton;

- (IBAction) deauthorizeAccount: (id) sender;

- (IBAction) dismiss: (id) sender;

@end
