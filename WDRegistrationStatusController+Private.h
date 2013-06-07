//
//  WDRegistrationStatusController+Private.h
//  Watchdog
//
//  Created by Konstantin Pavlikhin on 6/7/13.
//  Copyright (c) 2013 Konstantin Pavlikhin. All rights reserved.
//

#import "WDRegistrationStatusController.h"

@interface WDRegistrationStatusController ()

@property(readwrite, strong) NSString* message;

- (IBAction) deauthorizeAccount: (id) sender;

- (IBAction) dismiss: (id) sender;

@end
