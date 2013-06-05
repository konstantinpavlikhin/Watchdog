////////////////////////////////////////////////////////////////////////////////
//  
//  WDRegistrationStatusController.h
//  
//  Watchdog
//  
//  Created by Konstantin Pavlikhin on 27/01/10.
//  
////////////////////////////////////////////////////////////////////////////////

#import <KPToolbox/KPViewController.h>

@interface WDRegistrationStatusController : KPViewController

@property(readwrite, strong) NSString* message;

@property(readwrite, assign) IBOutlet NSButton* dismissButton;

- (IBAction) deauthorizeAccount: (id) sender;

- (IBAction) dismiss: (id) sender;

@end
