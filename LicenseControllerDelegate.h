////////////////////////////////////////////////////////////////////////////////
//  
//  LicenseControllerDelegate.h
//  
//  Watchdog
//  
//  Created by Konstantin Pavlikhin on 22/02/12.
//  
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>

@protocol LicenseControllerDelegate <NSObject>

- (NSString*) publicKeyStringInPEMForm;

- (void) applicationDidBecomeRegistered;

- (void) applicationDidBecomeUnregistered;

@end
