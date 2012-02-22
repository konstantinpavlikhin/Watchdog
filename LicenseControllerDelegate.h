//
//  LicenseControllerDelegate.h
//  Watchdog
//
//  Created by Константин Павлихин on 22/2/12.
//  Copyright (c) 2012 Konstantin Pavlikhin. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LicenseControllerDelegate <NSObject>

- (void) applicationDidBecomeRegistered;

- (void) applicationDidBecomeUnregistered;

- (NSString*) publicKeyInHexForm;

@end
