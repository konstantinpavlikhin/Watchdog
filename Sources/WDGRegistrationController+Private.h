//
//  WDGRegistrationController+Private.h
//  Watchdog
//
//  Created by Konstantin Pavlikhin on 27/01/10.
//  Copyright (c) 2015 Konstantin Pavlikhin. All rights reserved.
//

#import "WDGRegistrationController.h"

@interface WDGRegistrationController ()

@property(readwrite, assign, atomic) WDGApplicationState applicationState;

// These method prototypes are here for unit testing purposes.

- (NSDictionary*) decomposeQuickApplyLink: (NSString*) link utilizingBundleName: (NSString*) bundleName;

- (BOOL) isSerial: (NSString*) serial conformsToCustomerName: (NSString*) name error: (NSError**) error;

@end
