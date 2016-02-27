//
//  WDGSerialEntryController+Private.h
//  Watchdog
//
//  Created by Konstantin Pavlikhin on 27/01/10.
//  Copyright (c) 2016 Konstantin Pavlikhin. All rights reserved.
//

#import "WDGSerialEntryController.h"

@interface WDGSerialEntryController ()

// NSTextField that is used for the registration greetings message is bound to this property.
@property(readwrite, strong, nonatomic) NSString* greeting;

// All outlets are declared as "assign" because these objects are nested in the one top-level window that is managed by the NSViewController.
@property(readwrite, assign, nonatomic) IBOutlet NSTextField* licenseKey;

@property(readwrite, assign, nonatomic) IBOutlet NSProgressIndicator* spinner;

@property(readwrite, assign, nonatomic) IBOutlet NSButton* proceed;

// Opens internet page with serial restoration dialog.
- (IBAction) lostKey: (id) sender;

// Opens internet page where user can purchase an application serial.
- (IBAction) buyOnline: (id) sender;

- (IBAction) cancel: (id) sender;

- (IBAction) proceed: (id) sender;

- (void) shakeWindow;

- (void) clearInputFields;

@end
