//
//  LicenseController.m
//  Singlemizer
//
//  Created by Константин Павлихин on 27.01.10.
//  Copyright 2010 Minimalistic Dev. All rights reserved.
//

#import "LicenseController.h"

#import "RegistrationWindowController.h"

#import "LicenseVerifier.h"


NSString* const CustomerName = @"CustomerName";

NSString* const LicenseKeyInBase32 = @"LicenseKeyInBase32";

NSString* const CompletionHandler = @"CompletionHandler";

NSString* const CallerThread = @"CallerThread";

NSString* const DynamicBlacklist = @"DynamicBlacklist";


NSString* const CorruptedMsgTitle = @"License validation fail";

NSString* const CorruptedMsgBody = @"Your license data is corrupted. Please, re-register application.";

NSString* const BlacklistedMsgTitle = @"License validation fail";

NSString* const BlacklistedMsgBody = @"Your license key was blacklisted. Please, contact support to get a new key.";

NSString* const PiratedMsgTitle = @"License validation fail";

NSString* const PiratedMsgBody = @"Your are using pirated license key. Shame on you!";


@implementation LicenseController

@synthesize delegate;

#pragma mark Public methods

+ (LicenseController*) sharedLicenseController
{
  static dispatch_once_t pred;
  
  static LicenseController *sharedLicenseController = nil;
  
  dispatch_once(&pred, ^{ sharedLicenseController = [[self class] new]; });
  
  return sharedLicenseController;
}

- (id) init
{
  self = [super init];
  
  if(!self) return nil;
  
  // Пока мы не проверили лицензию мы не можем судить о ее валидности.
  applicationStatus = UnknownApplicationStatus;
  
  return self;
}

- (void) dealloc
{
  [registrationWindowController release];
  
  [super dealloc];
}

- (IBAction) showRegistrationWindow: (id) sender
{
  if(![NSThread isMainThread]) NSLog(@"%@ %s called from background thread.", [self className], __PRETTY_FUNCTION__);
  
  [[self registrationWindowController] performSelectorOnMainThread: @selector(showWindow:) withObject: self waitUntilDone: NO];
}

- (void) registerWithCustomerName: (NSString*) name licenseKeyInBase32: (NSString*) key completionHandler: (AppRegistrationHandler) handler
{
  NSMutableDictionary* threadParams = [NSMutableDictionary dictionary];
  
  // Encoding...
  [threadParams setObject: name forKey: CustomerName];
  
  [threadParams setObject: key forKey: LicenseKeyInBase32];
  
  [threadParams setObject: handler forKey: CompletionHandler];
  
  [threadParams setObject: [NSThread currentThread] forKey: CallerThread];
  
  // Starting...
  [NSThread detachNewThreadSelector: @selector(registrationThread:) toTarget: self withObject: threadParams];
}

- (void) registrationThread: (NSDictionary*) threadParams
{
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  
  //////////////////////////////////////////////////////////////////////////////
  NSString* name = [threadParams objectForKey: CustomerName];
  
  NSString* key = [threadParams objectForKey: LicenseKeyInBase32];
  
  AppRegistrationHandler handler = [threadParams objectForKey: CompletionHandler];
  
  NSThread* callerThread = [threadParams objectForKey: CallerThread];
  //////////////////////////////////////////////////////////////////////////////
  
  void (^corrupted)(void) = ^(void)
  {
    [self performBlock: handler withParam: NO onThread: callerThread];
  };
  
  void (^blacklisted)(void) = ^(void)
  {
    [self performBlock: handler withParam: NO onThread: callerThread];
  };
  
  void (^pirated)(void) = ^(void)
  {
    [self performBlock: handler withParam: NO onThread: callerThread];
  };
  
  void (^valid)(void) = ^(void)
  {
    // Запоминаем введенную лицензию.
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    [userDefaults setObject: name forKey: CustomerName];
    
    [userDefaults setObject: key forKey: LicenseKeyInBase32];
    
    // До перезапуска программа считается зарегистрированной.
    applicationStatus = RegisteredApplicationStatus;
    
    // Если окно регистрации на экране - переключаем вид на статусный.
    if([[registrationWindowController window] isVisible])
    {
      [registrationWindowController performSelectorOnMainThread: @selector(switchToLicenseStatusSubview) withObject: nil waitUntilDone: NO];
    }
    
    // Выходим из триала.
    [delegate applicationDidBecomeRegistered];
    //[[TrialController sharedTrialController] leaveTrialMode];
    
    // Выполняем завершающий блок.
    [self performBlock: handler withParam: YES onThread: callerThread];
  };
  
  [self checkLicenseWithName: name key: key corrupted: corrupted blacklisted: blacklisted pirated: pirated valid: valid];
  
  [pool release];
}

- (void) validateLicenseWithCompletionHandler: (LicenseValidationHandler) handler
{
  NSMutableDictionary* threadParams = [NSMutableDictionary dictionary];
  
  // Encoding...
  [threadParams setObject: handler forKey: CompletionHandler];
  
  [threadParams setObject: [NSThread currentThread] forKey: CallerThread];
  
  // Starting...
  [NSThread detachNewThreadSelector: @selector(validationThread:) toTarget: self withObject: threadParams];
}

- (void) validationThread: (NSDictionary*) threadParams
{
  NSAutoreleasePool* pool = [NSAutoreleasePool new];
  
  //////////////////////////////////////////////////////////////////////////////
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  
  NSString* name = [userDefaults stringForKey: CustomerName];
  
  NSString* key = [userDefaults stringForKey: LicenseKeyInBase32];
  
  LicenseValidationHandler handler = [threadParams objectForKey: CompletionHandler];
  
  NSThread* callerThread = [threadParams objectForKey: CallerThread];
  //////////////////////////////////////////////////////////////////////////////
  
  void (^deauthorizeAndShowModalMsg)(NSString* title, NSString* body) = ^(NSString* title, NSString* body)
  {
    [self deauthorizeAccount];
    
    ///
    
    //[[TrialController sharedTrialController] enterTrialModeAndShowRegistrationWindowIfNeeded];
    //[[TrialController sharedTrialController] enterTrialMode];
    [delegate applicationDidBecomeUnregistered];
    
    ///
    
    NSAlert* alert = [[[NSAlert alloc] init] autorelease];
    
    [alert setMessageText: title];
    
    [alert setInformativeText: body];
    
    [alert performSelectorOnMainThread: @selector(runModal) withObject: nil waitUntilDone: NO];
  };
  
  void (^corrupted)(void) = ^(void)
  {
    deauthorizeAndShowModalMsg(CorruptedMsgTitle, CorruptedMsgBody);
    
    [self performBlock: handler withParam: NO onThread: callerThread];
  };
  
  void (^blacklisted)(void) = ^(void)
  {
    deauthorizeAndShowModalMsg(BlacklistedMsgTitle, BlacklistedMsgBody);
    
    [self performBlock: handler withParam: NO onThread: callerThread];
  };
  
  void (^pirated)(void) = ^(void)
  {
    deauthorizeAndShowModalMsg(PiratedMsgTitle, PiratedMsgBody);
    
    [self performBlock: handler withParam: NO onThread: callerThread];
  };
  
  void (^valid)(void) = ^(void)
  {
    applicationStatus = RegisteredApplicationStatus;
    
    [registrationWindowController performSelectorOnMainThread: @selector(switchToLicenseStatusSubview) withObject: nil waitUntilDone: NO];
    
    [self performBlock: handler withParam: YES onThread: callerThread];
  };
  
  // Если лицензии вообще нету в UserDefaults...
  if(!name && !key)
  {
    applicationStatus = UnregisteredApplicationStatus;
    
    //[[TrialController sharedTrialController] enterTrialModeAndShowRegistrationWindowIfNeeded];
    //[[TrialController sharedTrialController] enterTrialMode];
    [delegate applicationDidBecomeUnregistered];
    
    [self performBlock: handler withParam: NO onThread: callerThread];
  }
  else
  {
    [self checkLicenseWithName: name key: key corrupted: corrupted blacklisted: blacklisted pirated: pirated valid: valid];
  }
  
  [pool release];
}

- (void) deauthorizeAccount
{
  // Выкидываем лицензию из UserDefaults.
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  
  [userDefaults removeObjectForKey: CustomerName];
  
  [userDefaults removeObjectForKey: LicenseKeyInBase32];
  
  // Приложение считается незарегистрированным до следующего перезапуска.
  applicationStatus = UnregisteredApplicationStatus;
  
  // Если окно регистрации на экране - переключаем на вид ввода имени и ключа.
  if([[registrationWindowController window] isVisible])
  {
    [registrationWindowController performSelectorOnMainThread: @selector(switchToLicenseEnterSubview) withObject: nil waitUntilDone: NO];
  }
  
  // Входим в триальный режим.
  //[[TrialController sharedTrialController] enterTrialMode];
  [delegate applicationDidBecomeUnregistered];
}

@synthesize applicationStatus;

- (NSString*) registeredCustomerName
{
  if([self applicationStatus] == RegisteredApplicationStatus)
  {
    return [[NSUserDefaults standardUserDefaults] stringForKey: CustomerName];
  }
  
  return nil;
}

- (void) getUrl: (NSAppleEventDescriptor*) event withReplyEvent: (NSAppleEventDescriptor*) reply
{
  NSString* URLString = [[event paramDescriptorForKeyword: keyDirectObject] stringValue];
  
  NSString* normalString = [URLString stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
  
  NSString* scheme = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"WDSerialInjectURLScheme"];
  
  scheme = [NSString stringWithFormat: @"%@://", scheme];
  
  NSString* withoutPrefix = [normalString stringByReplacingOccurrencesOfString: scheme withString: @""];
  
  NSArray* components = [withoutPrefix componentsSeparatedByString: @"@"];
  
  // Если ссылка сломалась...
  if([components count] != 2) return;
  
  void (^handler)(BOOL result) = ^(BOOL result) { if(result) [self showRegistrationWindow: self]; };
  
  [self registerWithCustomerName: [components objectAtIndex: 0] licenseKeyInBase32: [components objectAtIndex: 1] completionHandler: [[handler copy] autorelease]];
}

#pragma mark Private methods

// Синхронный метод-скелет.
- (void) checkLicenseWithName: (NSString*) n key: (NSString*) k corrupted: (vBv) c blacklisted: (vBv) b pirated: (vBv) p valid: (vBv) v
{
  LicenseVerifier* licenseVerifier = [[[LicenseVerifier alloc] initWithPublicKeyInHexForm: [delegate publicKeyInHexForm]] autorelease];
  
  // Если лицензия не расшифровалась...
  if(![licenseVerifier isLicenseKeyInBase32: k conformsToCustomerName: n])
  {
    c(); return;
  }
  
  // Если лицензия найдена в одном из черных списков...
  if([self isLicenseInStaticList: k] || [self isLicenseInDynamicList: k])
  {
    b(); return;
  }
  
  // Проверка через сервер...
  switch([self synchronousServerCheck: k])
  {
    // Если сервер дал добро...
    case ValidLicenseServerEcho: v(); break;
    
    // Если лицензия черная...
    case BlacklistedLicenseServerEcho: [self addLicenseToDynamicList: k]; b(); break;
    
    // Если мы такую не генерировали...
    case PiratedLicenseServerEcho: p(); break;
  }
}

- (RegistrationWindowController*) registrationWindowController
{
  if(!registrationWindowController)
  {
    registrationWindowController = [[RegistrationWindowController alloc] init];
  }
  
  return registrationWindowController;
}

- (BOOL) isLicenseInStaticList: (NSString*) licenseHash
{
  NSMutableArray* staticBlacklist = [NSMutableArray array];
  
  [staticBlacklist addObject: @"QAWAEFBRTJXH6CCUQTQ633MXGGKMNQ5XINPPXEQCCRKM6JIHR3Q4YAJNJJWMWBK64FZCSB7OEA"];
  
  [staticBlacklist addObject: @"GAWQEFC7JMBR5SOXEPEG4TUVM4QXZFKPWZ2XF3QCCUAJ2LA5IRQLABZDRQOT3XHKP4VSPAF5MDTA"];
  
  [staticBlacklist addObject: @"GAWQEFD2QOPSXHTAFXLWK7RUXKNLLXRYVSKLPHICCUALII6CK6UI4GQ3B6UGGNOPLLMH67DU2JCA"];
  
  [staticBlacklist addObject: @"GAWQEFIAQPJK43O3KZOWBLJYYSIEORUZWO3YFO62AIKFJIRGUECSPTBTQPS3MOROK5VH7LCCWEGQ"];
  
  //[staticBlacklist addObject: @""];
  
  return [staticBlacklist containsObject: licenseHash];
}

- (BOOL) isLicenseInDynamicList: (NSString*) licenseHash
{
  NSArray* dynamicBlacklist = [[NSUserDefaults standardUserDefaults] arrayForKey: DynamicBlacklist];
  
  return [dynamicBlacklist containsObject: licenseHash];
}

- (LicenseServerEcho) synchronousServerCheck: (NSString*) licenseInBase32
{
  NSString* serialCheckBase = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"WDSerialCheckURL"];
  
  NSString* userNameHash = [[NSUserName() dataUsingEncoding: NSUTF8StringEncoding] SHA1HexString];
  
  NSString* queryStr = [NSString stringWithFormat: @"%@?license=%@&account=%@", serialCheckBase, licenseInBase32, userNameHash];
  
  NSMutableURLRequest* URLRequest = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: queryStr]];
  
  {{
    NSString* hostAppName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"];
    
    [URLRequest setValue: hostAppName? hostAppName : @"Watchdog" forHTTPHeaderField: @"User-agent"];
  }}
  
  [URLRequest setTimeoutInterval: 5.0];
  
  NSURLResponse* URLResponse = nil;
  
  NSError* error = nil;
  
  NSData* responseData = [NSURLConnection sendSynchronousRequest: URLRequest returningResponse: &URLResponse error: &error];
  
  NSString* string = [[[NSString alloc] initWithData: responseData encoding: NSUTF8StringEncoding] autorelease];
  
  if([string isEqualToString: @"Valid"])
  {
    return ValidLicenseServerEcho;
  }
  else if([string isEqualToString: @"Blacklisted"])
  {
    return BlacklistedLicenseServerEcho;
  }
  else if([string isEqualToString: @"Pirated"])
  {
    return PiratedLicenseServerEcho;
  }
  else
  {
    return ValidLicenseServerEcho;
  }
}

- (void) addLicenseToDynamicList: (NSString*) licenseInBase32
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  
  NSArray* dynamicBlacklist = [userDefaults arrayForKey: DynamicBlacklist];
  
  if(!dynamicBlacklist) dynamicBlacklist = [NSArray array];
  
  [userDefaults setObject: [dynamicBlacklist arrayByAddingObject: licenseInBase32] forKey: DynamicBlacklist];
}

- (void) performBlock: (void (^)(BOOL)) block withParam: (BOOL) param onThread: (NSThread*) thread
{
  [self performSelector: @selector(threadedMethodWithBlock:param:) onThread: thread withObject: block withObject: [NSNumber numberWithBool: param]];
}

- (void) threadedMethodWithBlock: (void (^)(BOOL)) block param: (NSNumber*) param
{
  block([param boolValue]);
}

@end
