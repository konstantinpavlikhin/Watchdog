//
//  LicenseEnterController.h
//  Singlemizer
//
//  Created by Константин Павлихин on 27.01.10.
//  Copyright 2010 Minimalistic Dev. All rights reserved.
//

@interface LicenseEnterController : ViewController
{
  IBOutlet NSTextField* licenseKey;
  
  IBOutlet NSProgressIndicator* spinner;
  
  IBOutlet NSButton* proceed;
}

@property(readwrite, assign) IBOutlet NSTextField* customerName;

- (IBAction) lostKey: (id) sender;

- (IBAction) buyOnline: (id) sender;

- (IBAction) cancel: (id) sender;

- (IBAction) proceed: (id) sender;

- (NSString*) cleanKeyFromDashes: (NSString*) keyWithDashes;

- (void) shakeWindow;

- (void) clearInputFields;

@end
