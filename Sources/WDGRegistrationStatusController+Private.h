//
//  WDGRegistrationStatusController+Private.h
//  Watchdog
//
//  Created by Konstantin Pavlikhin on 27/01/10.
//  Copyright (c) 2015 Konstantin Pavlikhin. All rights reserved.
//

#import "WDGRegistrationStatusController.h"

@interface WDGRegistrationStatusController ()

@property(readwrite, strong, nonatomic) NSString* message;

- (IBAction) deauthorizeAccount: (id) sender;

- (IBAction) dismiss: (id) sender;

@end
