////////////////////////////////////////////////////////////////////////////////
//  
//  WDRegistrationController.m
//  
//  Watchdog
//  
//  Created by Konstantin Pavlikhin on 27/01/10.
//  
////////////////////////////////////////////////////////////////////////////////

#import "WDRegistrationController.h"

#import "WDRegistrationWindowController.h"

NSString* const ApplicationStateKeyPath = @"applicationState";

NSString* const WDCustomerNameKey = @"WDCustomerName";

NSString* const WDSerialKey = @"WDSerial";

NSString* const WDDynamicBlacklistKey = @"WDDynamicBlacklist";

// WDRegistrationController is a singleton instance, so we can allow ourselves this trick.
static WDRegistrationWindowController* registrationWindowController = nil;

@interface WDRegistrationController ()

// Redeclare this property as private readwrite.
@property(readwrite, assign, atomic) enum ApplicationState applicationState;

@end

@implementation WDRegistrationController

#pragma mark - Public Methods

+ (WDRegistrationController*) sharedRegistrationController
{
  static dispatch_once_t predicate;
  
  static WDRegistrationController *sharedRegistrationController = nil;
  
  dispatch_once(&predicate, ^{ sharedRegistrationController = [self new]; });
  
  return sharedRegistrationController;
}

// Supplied link should look like this: bundledisplayname-wd://WEDSCVBNMRFHNMJJFCV:WSXFRFVBJUHNMQWETYIOPLKJHGFDSXCVBNYFVBGFCVBNMHSGHFKAJSHCASC.
- (void) registerWithQuickApplyLink: (NSString*) link
{
  // Getting non-localized application name.
  NSString* appName = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleName"];
  
  // Concatenating URL scheme part with forward slashes.
  NSString* schemeWithSlashes = [[appName lowercaseString] stringByAppendingString: @"-wd://"];
  
  // Wiping out link prefix.
  NSString* nameColonSerial = [link stringByReplacingOccurrencesOfString: schemeWithSlashes withString: @""];
  
  NSRange rangeOfColon = [nameColonSerial rangeOfString: @":"];
  
  // Colon name/serial separator not found — link is corrupted.
  if(rangeOfColon.location == NSNotFound)
  {
    [[[self class] corruptedQuickApplyLinkAlert] runModal];
    
    return;
  }
  
  NSString* customerNameInBase32 = nil;
  
  NSString* serial = nil;
  
  // -substringToIndex can raise an exception...
  @try
  {
    customerNameInBase32 = [nameColonSerial substringToIndex: rangeOfColon.location];
    
    serial = [nameColonSerial substringFromIndex: rangeOfColon.location + 1];
  }
  @catch(NSException* exception)
  {
    [[[self class] corruptedQuickApplyLinkAlert] runModal];
    
    return;
  }
  
  // If we are here we already got two base32 encoded parts: customer name & the serial itself. Lets decode a name!
  
  // Создаем трансформацию перевода из base32.
  SecTransformRef base32DecodeTransform = SecDecodeTransformCreate(kSecBase32Encoding, NULL);
  
  if(base32DecodeTransform)
  {
    BOOL success = NO;
    
    CFDataRef tempData = CFBridgingRetain([customerNameInBase32 dataUsingEncoding: NSUTF8StringEncoding]);
    
    // Задаем входной параметр в виде NSData.
    if(SecTransformSetAttribute(base32DecodeTransform, kSecTransformInputAttributeName, tempData, NULL))
    {
      // Запускаем трансформацию.
      CFTypeRef customerNameData = SecTransformExecute(base32DecodeTransform, NULL);
      
      if(customerNameData)
      {
        NSString* customerName = [[NSString alloc] initWithData: CFBridgingRelease(customerNameData) encoding: NSUTF8StringEncoding];
        
        [self registerWithCustomerName: customerName serial: serial handler: ^(enum SerialVerdict verdict)
        {
          dispatch_async(dispatch_get_main_queue(), ^()
          {
            if(verdict != ValidSerialVerdict)
            {
              [[[self class] alertWithSerialVerdict: verdict] runModal];
              
              return;
            }
            // Show Registration Window if everything is OK.
            [self showRegistrationWindow: self];
          });
        }];
        
        success = YES;
      }
    }
    
    CFRelease(tempData);
    
    CFRelease(base32DecodeTransform);
    
    if(success) return;
  }
  
  // Error state.
  [[[self class] corruptedQuickApplyLinkAlert] runModal];
}

// Tries to register application with supplied customer name & serial pair.
- (void) registerWithCustomerName: (NSString*) name serial: (NSString*) serial handler: (SerialCheckHandler) handler
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
  {
    // Wiping out any existing registration data & state.
    dispatch_sync(dispatch_get_main_queue(), ^()
    {
      [self deauthorizeAccount];
    });
    
    // Launching full-featured customer data check.
    [self complexCheckOfCustomerName: name serial: serial completionHandler: ^(enum SerialVerdict verdict)
    {
      // If all of the tests pass...
      if(verdict == ValidSerialVerdict)
      {
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        
        [userDefaults setObject: name forKey: WDCustomerNameKey];
        
        [userDefaults setObject: serial forKey: WDSerialKey];
        
        // KVO-notifications always arrive on the same thread that set the value.
        dispatch_sync(dispatch_get_main_queue(), ^()
        {
          self.applicationState = RegisteredApplicationState;
        });
      }
      
      // Calling handler with the corresponding verdict (used by the WDSerialEntryController to determine when to shake the input window).
      handler(verdict);
    }];
  });
}

- (IBAction) showRegistrationWindow: (id) sender
{
  [[self registrationWindowController] showWindow: sender];
}

- (NSString*) registeredCustomerName
{
  if([self applicationState] != RegisteredApplicationState) return nil;
  
  return [[NSUserDefaults standardUserDefaults] stringForKey: WDCustomerNameKey];
}

- (void) deauthorizeAccount
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  
  [userDefaults removeObjectForKey: WDCustomerNameKey];
  
  [userDefaults removeObjectForKey: WDSerialKey];
  
  self.applicationState = UnregisteredApplicationState;
}

- (void) checkForStoredSerialAndValidateIt
{
  // Starting a separate thread...
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^()
  {
    // Looking for serial data in user preferences.
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString* name = [userDefaults stringForKey: WDCustomerNameKey];
    
    NSString* serial = [userDefaults stringForKey: WDSerialKey];
    
    // If both parameters are missing — treat it (silently) like unregistered state.
    if(!name && !serial)
    {
      dispatch_sync(dispatch_get_main_queue(), ^()
      {
        self.applicationState = UnregisteredApplicationState;
      });
      
      return;
    };
    
    // Prepare block handler for any other cases.
    void (^handler)(enum SerialVerdict serialVerdict) = ^(enum SerialVerdict serialVerdict)
    {
      if(serialVerdict == ValidSerialVerdict)
      {
        dispatch_sync(dispatch_get_main_queue(), ^()
        {
          self.applicationState = RegisteredApplicationState;
        });
        
        return;
      };
      
      // Once we've reached this point something is definitely incorrect.
      
      dispatch_async(dispatch_get_main_queue(), ^()
      {
        // Wiping out stored registration data and going to the unregistered state.
        [self deauthorizeAccount];
        
        [[[self class] alertWithSerialVerdict: serialVerdict] runModal];
      });
    };
    
    [self complexCheckOfCustomerName: name serial: serial completionHandler: handler];
  });
}

#pragma mark - Private Methods

+ (NSAlert*) corruptedQuickApplyLinkAlert
{
  NSAlert* alert = [[NSAlert alloc] init];
  
  [alert setMessageText: NSLocalizedStringFromTableInBundle(@"Corrupted Quick-Apply Link", nil, [NSBundle bundleForClass: [self class]], @"Alert title.")];
  
  [alert setInformativeText: NSLocalizedStringFromTableInBundle(@"Please enter your registration data manualy.", nil, [NSBundle bundleForClass: [self class]], @"Alert body.")];
  
  return alert;
}

+ (NSAlert*) corruptedRegistrationDataAlert
{
  NSAlert* alert = [[NSAlert alloc] init];
  
  [alert setMessageText: NSLocalizedStringFromTableInBundle(@"Serial validation fail", nil, [NSBundle bundleForClass: [self class]], @"Alert title.")];
  
  [alert setInformativeText: NSLocalizedStringFromTableInBundle(@"Your serial is corrupted. Please, try again.", nil, [NSBundle bundleForClass: [self class]], @"Alert body.")];
  
  return alert;
}

+ (NSAlert*) blacklistedRegistrationDataAlert
{
  NSAlert* alert = [[NSAlert alloc] init];
  
  [alert setMessageText: NSLocalizedStringFromTableInBundle(@"Serial validation fail", nil, [NSBundle bundleForClass: [self class]], @"Alert title.")];
  
  [alert setInformativeText: NSLocalizedStringFromTableInBundle(@"Your serial is blacklisted. Please, contact support to get a new key.", nil, [NSBundle bundleForClass: [self class]], @"Alert body.")];
  
  return alert;
}

+ (NSAlert*) piratedRegistrationDataAlert
{
  NSAlert* alert = [[NSAlert alloc] init];
  
  [alert setMessageText: NSLocalizedStringFromTableInBundle(@"Serial validation fail", nil, [NSBundle bundleForClass: [self class]], @"Alert title.")];
  
  [alert setInformativeText: NSLocalizedStringFromTableInBundle(@"It seems like you are using pirated serial.", nil, [NSBundle bundleForClass: [self class]], @"Alert body.")];
  
  return alert;
}

+ (NSAlert*) alertWithSerialVerdict: (enum SerialVerdict) verdict
{
  NSAlert* alert = nil;
  
  switch(verdict)
  {
    // Compiler generates warning if this constant not handled in switch.
    case ValidSerialVerdict:
    {
      alert = nil;
      
      break;
    }
    
    case CorruptedSerialVerdict:
    {
      alert = [self corruptedRegistrationDataAlert];
      
      break;
    }
    
    case BlacklistedSerialVerdict:
    {
      alert = [self blacklistedRegistrationDataAlert];
      
      break;
    }
    
    case PiratedSerialVerdict:
    {
      alert = [self piratedRegistrationDataAlert];
      
      break;
    }
  }
  
  return alert;
}

- (id) init
{
  self = [super init];
  
  if(!self) return nil;
  
  // We can't judge about application state until we execute all checks.
  _applicationState = UnknownApplicationState; // Using synthesized instance variable directly so no KVO-notification is being fired!
  
  return self;
}

// Lazy RegistrationWindowController constructor.
- (WDRegistrationWindowController*) registrationWindowController
{
  if(!registrationWindowController) registrationWindowController = [WDRegistrationWindowController new];
  
  return registrationWindowController;
}

- (void) complexCheckOfCustomerName: (NSString*) name serial: (NSString*) serial completionHandler: (SerialCheckHandler) handler
{
  // Если лицензия не расшифровалась...
  if(![self isSerial: serial conformsToCustomerName: name error: NULL])
  {
    handler(CorruptedSerialVerdict); return;
  }
  
  // Если лицензия найдена в одном из черных списков...
  if([self isSerialInStaticBlacklist: serial] || [self isSerialInDynamicBlacklist: serial])
  {
    handler(BlacklistedSerialVerdict); return;
  }
  
  handler([self synchronousServerCheckWithSerial: serial]);
}

- (BOOL) isSerial: (NSString*) serial conformsToCustomerName: (NSString*) name error: (NSError**) error
{
  // Проверка на элементарные вырожденные случаи.
  if(!serial || !name || ![serial length] || ![name length]) return NO;
  
  CFErrorRef tempError;
  
  // Переводим серийник из base32 ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  
  // Создаем трансформацию перевода из base32.
  SecTransformRef base32DecodeTransform = SecDecodeTransformCreate(kSecBase32Encoding, &tempError);
  
  // Если трансформация не создана — выход с ошибкой.
  if(base32DecodeTransform == NULL)
  {
    *error = CFBridgingRelease(tempError);
    
    return NO;
  }
  
  // Задаем входной параметр в виде NSData.
  CFDataRef tempData = CFBridgingRetain([serial dataUsingEncoding: NSUTF8StringEncoding]);
  
  Boolean result = SecTransformSetAttribute(base32DecodeTransform, kSecTransformInputAttributeName, tempData, &tempError);
  
  CFRelease(tempData);
  
  if(!result)
  {
    *error = CFBridgingRelease(tempError);
    
    CFRelease(base32DecodeTransform);
    
    return NO;
  }
  
  // Запускаем трансформацию.
  CFTypeRef signature = SecTransformExecute(base32DecodeTransform, &tempError);
  
  if(signature == NULL)
  {
    *error = CFBridgingRelease(tempError);
    
    CFRelease(base32DecodeTransform);
    
    return NO;
  }
  
  CFRelease(base32DecodeTransform);
  
  return [self verifyDSASignature: CFBridgingRelease(signature) data: [name dataUsingEncoding: NSUTF8StringEncoding] error: NULL];
}

- (BOOL) verifyDSASignature: (NSData*) signature data: (NSData*) sourceData error: (NSError**) error
{
  if(!self.DSAPublicKeyPEM) [NSException raise: NSInternalInconsistencyException format: @"DSA public key is not set."];
  
  // Получаем публичный ключ от делегата в виде строки формата PEM и переводим его в дату.
  CFDataRef publicKeyData = CFBridgingRetain([self.DSAPublicKeyPEM dataUsingEncoding: NSUTF8StringEncoding]);
  
  // Приводим публичный ключ к виду SecKeyRef.
  
  SecExternalFormat externalFormat = kSecFormatPEMSequence;
  
  SecExternalItemType externalItemType = kSecItemTypePublicKey;
  
  SecItemImportExportKeyParameters itemImportExportKeyParameters;
  {
    itemImportExportKeyParameters.keyUsage = NULL;
    
    itemImportExportKeyParameters.keyAttributes = NULL;
  }
  
  CFArrayRef tempArray;
  
  // TODO: check status?
  OSStatus status = SecItemImport(publicKeyData, NULL, &externalFormat, &externalItemType, 0, &itemImportExportKeyParameters, NULL, &tempArray);
  
  CFRelease(publicKeyData);
  
  SecKeyRef publicKey = (SecKeyRef)CFRetain(CFArrayGetValueAtIndex(tempArray, 0));
  
  CFRelease(tempArray);
  
  // Создаем трансформацию проверки подписи.
  CFDataRef tempSignature = CFBridgingRetain(signature);
  
  CFErrorRef tempError;
  
  SecTransformRef verifier = SecVerifyTransformCreate(publicKey, tempSignature, &tempError);
  
  CFRelease(publicKey);
  
  CFRelease(tempSignature);
  
  if(verifier == NULL)
  {
    *error = CFBridgingRelease(tempError);
    
    return NO;
  }
  
  // Задаем дату, чью подпись мы собираемся проверять.
  CFDataRef tempSourceData = CFBridgingRetain(sourceData);
  
  Boolean result = SecTransformSetAttribute(verifier, kSecTransformInputAttributeName, tempSourceData, &tempError);
  
  CFRelease(tempSourceData);
  
  if(!result)
  {
    *error = CFBridgingRelease(tempError);
    
    CFRelease(verifier);
    
    return NO;
  }
  
  CFTypeRef isValid = SecTransformExecute(verifier, &tempError);
  
  CFRelease(verifier);
  
  return (isValid == kCFBooleanTrue)? YES : NO;
}

// Performs server check of the supplied serial.
- (enum SerialVerdict) synchronousServerCheckWithSerial: (NSString*) serial
{
  NSString* serialCheckBase = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"WDServerCheckURL"];
  
  NSString* userNameHash = [[NSUserName() dataUsingEncoding: NSUTF8StringEncoding] SHA1HexString];
  
  NSString* queryString = [NSString stringWithFormat: @"%@?serial=%@&account=%@", serialCheckBase, serial, userNameHash];
  
  NSMutableURLRequest* URLRequest = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: queryString]];
  
  {{
    NSString* hostAppName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"];
    
    [URLRequest setValue: hostAppName? hostAppName : @"Watchdog" forHTTPHeaderField: @"User-agent"];
  }}
  
  [URLRequest setTimeoutInterval: 3.0];
  
  NSURLResponse* URLResponse = nil;
  
  NSError* error = nil;
  
  #warning TODO: переделать на асинхронное поведение
  NSData* responseData = [NSURLConnection sendSynchronousRequest: URLRequest returningResponse: &URLResponse error: &error];
  
  NSString* string = [[NSString alloc] initWithData: responseData encoding: NSUTF8StringEncoding];
  
  if([string isEqualToString: @"Valid"])
  {
    return ValidSerialVerdict;
  }
  else if([string isEqualToString: @"Blacklisted"])
  {
    [self addSerialToDynamicBlacklist: serial];
    
    return BlacklistedSerialVerdict;
  }
  else if([string isEqualToString: @"Pirated"])
  {
    [self addSerialToDynamicBlacklist: serial];
    
    return PiratedSerialVerdict;
  }
  
  // Not going to be too strict at this point.
  return ValidSerialVerdict;
}

// Checks whether specified serial is present in the static blacklist.
- (BOOL) isSerialInStaticBlacklist: (NSString*) serial
{
  return [self.serialsStaticBlacklist containsObject: serial];
}

// Checks whether specified serial is present in the dynamic blacklist.
- (BOOL) isSerialInDynamicBlacklist: (NSString*) serial
{
  NSArray* dynamicBlacklist = [[NSUserDefaults standardUserDefaults] arrayForKey: WDDynamicBlacklistKey];
  
  return [dynamicBlacklist containsObject: serial];
}

// Adds specified serial to the dynamic blacklist.
- (void) addSerialToDynamicBlacklist: (NSString*) serial
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  
  NSArray* dynamicBlacklist = [userDefaults arrayForKey: WDDynamicBlacklistKey];
  
  if(!dynamicBlacklist) dynamicBlacklist = [NSArray array];
  
  [userDefaults setObject: [dynamicBlacklist arrayByAddingObject: serial] forKey: WDDynamicBlacklistKey];
}

@end
