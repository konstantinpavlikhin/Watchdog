////////////////////////////////////////////////////////////////////////////////
//  
//  RegistrationStatusController.h
//  
//  Watchdog
//  
//  Created by Konstantin Pavlikhin on 27/01/10.
//  
////////////////////////////////////////////////////////////////////////////////

#import <KPFoundation/KPViewController.h>

@interface RegistrationStatusController : KPViewController

@property(readwrite, retain) NSString* message;

@property(readwrite, assign) IBOutlet NSButton* dismissButton;

- (IBAction) deauthorizeAccount: (id) sender;

- (IBAction) dismiss: (id) sender;

@end
