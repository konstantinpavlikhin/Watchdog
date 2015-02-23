//
//  WDGRegistrationController.h
//  Watchdog
//
//  Created by Konstantin Pavlikhin on 27/01/10.
//  Copyright (c) 2015 Konstantin Pavlikhin. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WDGRegistrationWindowController;

enum WDGApplicationState
{
  // Application state before any checks are made.
  WDGUnknownApplicationState = 0,
  
  // Application state when no [valid] serial is found.
  WDGUnregisteredApplicationState,
  
  // Application state when all checks are succeeded.
  WDGRegisteredApplicationState
};

enum WDGSerialVerdict
{
  // When a supplied serial is perfectly legal.
  WDGValidSerialVerdict,
  
  // When a supplied serial doesn't conform to the customer name.
  WDGCorruptedSerialVerdict,
  
  // Response on serial that was added to the blacklist.
  WDGBlacklistedSerialVerdict,
  
  // Response on serial that was not generated by the developer.
  WDGPiratedSerialVerdict
};

@interface WDGRegistrationController : NSObject

// Returnes a singleton of the WDRegistrationController.
+ (WDGRegistrationController*) sharedRegistrationController;

// Returns current registration state of the application.
@property(readonly, atomic) enum WDGApplicationState applicationState;

// Must be set to the application DSA/ECDSA public key in PEM format.
@property(readwrite, strong, atomic) NSString* publicKeyPEM;

// Should be set to the array of the blacklisted serials.
@property(readwrite, strong, atomic) NSArray* serialsStaticBlacklist;

// Accepts a Quick-Apply link string in form of "appname-wd://GFUENLVNDLPOJHJB:GAWWERTYUIOPEDCNJIKLKJHGFDXCVBNM". Runs asynchronously. Shows either alerts or registration window.
- (void) registerWithQuickApplyLink: (NSString*) link;

typedef void (^SerialCheckHandler)(enum WDGSerialVerdict verdict);

// Tries to register app with the supplied customer name & serial pair then calls handler with the appropriate flag. Runs asynchronously.
- (void) registerWithCustomerName: (NSString*) name serial: (NSString*) serial handler: (SerialCheckHandler) handler;

// Opens application registration window. Should be called from the main thread.
- (IBAction) showRegistrationWindow: (id) sender;

// Returns the name of the successfully accepted customer. Thread safe.
- (NSString*) registeredCustomerName;

// Removes registration data from UserDefaults and puts app in unregistered state. Should be called from the main thread only!
- (void) deauthorizeAccount;

// Launches an asynchronous check of the installed serial. Shows alerts on invalid serials.
- (void) checkForStoredSerialAndValidateIt;

@end

// Use this const string instead of manual typing of the "applicationState" property name in KVO addition/removal of observers.
extern NSString* const ApplicationStateKeyPath;

// May be useful if someone wants to migrate user license data to a new place.
extern NSString* const WDGCustomerNameKey;

extern NSString* const WDGSerialKey;