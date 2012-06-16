////////////////////////////////////////////////////////////////////////////////
//  
//  LicenseController.h
//  
//  Watchdog
//  
//  Created by Konstantin Pavlikhin on 27/01/10.
//  
////////////////////////////////////////////////////////////////////////////////

#import "LicenseControllerDelegate.h"

#import <Foundation/Foundation.h>

enum ApplicationStatus
{
  UnknownApplicationStatus,
  
  UnregisteredApplicationStatus,
  
  RegisteredApplicationStatus
};

typedef enum ApplicationStatus ApplicationStatus;


enum LicenseServerEcho
{
  ValidLicenseServerEcho,
  
  BlacklistedLicenseServerEcho,
  
  PiratedLicenseServerEcho
};

typedef enum LicenseServerEcho LicenseServerEcho;


@class RegistrationWindowController;

@interface LicenseController : NSObject
{
  RegistrationWindowController* registrationWindowController;
  
  ApplicationStatus applicationStatus;
}

@property(readwrite, assign) id<LicenseControllerDelegate> delegate;

#pragma mark - Public methods

// Возвращает singleton LicenseController'а.
+ (LicenseController*) sharedLicenseController;

// Показывает окно регистрации программы.
- (IBAction) showRegistrationWindow: (id) sender;

// Пытается зарегистрировать программу с данным именем и ключем.
typedef void (^AppRegistrationHandler)(BOOL isRegistered);

- (void) registerWithCustomerName: (NSString*) name licenseKeyInBase32: (NSString*) key completionHandler: (AppRegistrationHandler) handler;

- (void) registrationThread: (NSDictionary*) threadParams;

// Производит проверку установленной лицензии.
typedef void (^LicenseValidationHandler)(BOOL isValid);

- (void) validateLicenseWithCompletionHandler: (LicenseValidationHandler) handler;

- (void) validationThread: (NSDictionary*) threadParams;

// Удаляет лицензионный ключ из UserDefaults.
- (void) deauthorizeAccount;

// Возвращает текущий статус приложения.
@property(readonly) ApplicationStatus applicationStatus;

- (NSString*) registeredCustomerName;

- (void) getUrl: (NSAppleEventDescriptor*) event withReplyEvent: (NSAppleEventDescriptor*) reply;

#pragma mark Private methods

- (BOOL) isLicenseKeyInBase32: (NSString*) licenseKeyInBase32 conformsToCustomerName: (NSString*) customerName error: (NSError**) error;

typedef void (^vBv)(void);

- (void) checkLicenseWithName: (NSString*) n key: (NSString*) k corrupted: (vBv) c blacklisted: (vBv) b pirated: (vBv) p valid: (vBv) v;

// Лениво конструирует registrationWindowController.
- (RegistrationWindowController*) registrationWindowController;

// Проверяет наличие хэша лицензии в статическом черном списке.
- (BOOL) isLicenseInStaticList: (NSString*) licenseHash;

// Проверяет наличие хэша лицензии в динамическом черном списке.
- (BOOL) isLicenseInDynamicList: (NSString*) licenseHash;

// Проверяет лицензию через сервер.
- (LicenseServerEcho) synchronousServerCheck: (NSString*) licenseInBase32;

// Добавляет хэш лицензии в динамический черный список.
- (void) addLicenseToDynamicList: (NSString*) licenseInBase32;

- (void) performBlock: (void (^)(BOOL)) block withParam: (BOOL) param onThread: (NSThread*) thread;

- (void) threadedMethodWithBlock: (void (^)(BOOL)) block param: (NSNumber*) param;

@end
