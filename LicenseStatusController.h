//
//  LicenseStatusController.h
//  Singlemizer
//
//  Created by Константин Павлихин on 27.01.10.
//  Copyright 2010 Minimalistic Dev. All rights reserved.
//

@interface LicenseStatusController : ViewController
{
  IBOutlet NSTextField* licensedTo;
}

@property(readwrite, assign) IBOutlet NSButton* dismissButton;

- (IBAction) deauthorizeAccount: (id) sender;

- (IBAction) dismiss: (id) sender;

- (void) viewDidAppear;

@end
