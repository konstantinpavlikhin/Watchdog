////////////////////////////////////////////////////////////////////////////////
//  
//  RegistrationController.h
//  
//  Watchdog
//  
//  Created by Konstantin Pavlikhin on 27/01/10.
//  
////////////////////////////////////////////////////////////////////////////////

#import <Foundation/Foundation.h>

@class RegistrationWindowController;

enum ApplicationState
{
  // Application state before any checkings are made.
  UnknownApplicationState,
  
  // Application state when no [valid] serial is found.
  UnregisteredApplicationState,
  
  // Application state when all checkings are succeeded.
  RegisteredApplicationState
};

enum SerialVerdict
{
  // When a supplied serial is perfectly legal.
  ValidSerialVerdict,
  
  // When a supplied serial doesn't conform to the customer name.
  CorruptedSerialVerdict,
  
  // Response on serial that was added to the blacklist.
  BlacklistedSerialVerdict,
  
  // Response on serial that was not generated by the developer.
  PiratedSerialVerdict
};

@interface RegistrationController : NSObject

// Returnes a singleton of the RegistrationController.
+ (RegistrationController*) sharedRegistrationController;

// Returns current registration state of the application.
@property(readonly, atomic) enum ApplicationState applicationState;

// Must be set to the application DSA public key in PEM format.
@property(readwrite, retain, atomic) NSString* DSAPublicKeyPEM;

// Should be set to the array of the blacklisted serials.
@property(readwrite, retain, atomic) NSArray* serialsStaticBlacklist;

// Accepts a Quick-Apply link string in form of "appname-wd://GFUENLVNDLPOJHJB:GAWWERTYUIOPEDCNJIKLKJHGFDXCVBNM". Runs asynchronously. Shows either alerts or registration window.
- (void) registerWithQuickApplyLink: (NSString*) link;

typedef void (^SerialCheckHandler)(enum SerialVerdict verdict);

// Tries to register app with the supplied customer name & serial pair then calls handler with the appropriate flag. Runs asynchronously.
- (void) registerWithCustomerName: (NSString*) name serial: (NSString*) serial handler: (SerialCheckHandler) handler;

// Opens application registration window. Should be called from the main thread.
- (IBAction) showRegistrationWindow: (id) sender;

// Returns the name of the successfully accepted customer. Thread safe.
- (NSString*) registeredCustomerName;

// Removes registration data from UserDefaults and puts app in unregistered state. Thread safe.
- (void) deauthorizeAccount;

// Launches an asynchronous check of the installed serial. Shows alerts on invalid serials.
- (void) checkForStoredSerialAndValidateIt;

@end

// Use this const string instead of manual typing of the "applicationState" property name in KVO addition/removal of observers.
extern NSString* const ApplicationStateKeyPath;

// May be useful if someone wants to migrate user license data to a new place.
extern NSString* const WDCustomerNameKey;

extern NSString* const WDSerialKey;