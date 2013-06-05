////////////////////////////////////////////////////////////////////////////////
//  
//  WDRegistrationController.m
//  
//  Watchdog
//  
//  Created by Konstantin Pavlikhin on 27/01/10.
//  
////////////////////////////////////////////////////////////////////////////////

#import "WDRegistrationController+Private.h"

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

- (BOOL) isSerial: (NSString*) serial conformsToCustomerName: (NSString*) name error: (NSError* __autoreleasing *) error
{
  // These parameters are mandatory.
  NSParameterAssert(serial);
  
  NSParameterAssert(name);
  
  // There is no reason to validate anything if supplied strings are void.
  if([serial length] == 0 || [name length] == 0) return NO;
  
  BOOL result = NO;
  
  BOOL reachedEnd = NO;
  
  CFErrorRef tempError;
  
  // Creating transformation from base32 string to the actual data.
  SecTransformRef base32DecodeTransform = SecDecodeTransformCreate(kSecBase32Encoding, &tempError);
  
  if(base32DecodeTransform)
  {
    CFDataRef tempData = CFBridgingRetain([serial dataUsingEncoding: NSUTF8StringEncoding]);
    
    if(SecTransformSetAttribute(base32DecodeTransform, kSecTransformInputAttributeName, tempData, &tempError))
    {
      CFTypeRef signature = SecTransformExecute(base32DecodeTransform, &tempError);
      
      if(signature)
      {
        NSData* tempSignature = CFBridgingRelease(signature);
        
        result = [self verifyDSASignature: tempSignature data: [name dataUsingEncoding: NSUTF8StringEncoding] error: error];
        
        reachedEnd = YES;
      }
    }
    
    CFRelease(tempData);
    
    CFRelease(base32DecodeTransform);
  }
  
  if(!reachedEnd)
  {
    // Control flow didn't reached end → something went wrong.
    *error = CFBridgingRelease(tempError);
  }
  
  return result;
}

- (BOOL) verifyDSASignature: (NSData*) signature data: (NSData*) sourceData error: (NSError* __autoreleasing *) error
{
  // These parameters are mandatory.
  NSParameterAssert(signature);
  
  NSParameterAssert(sourceData);
  
  // Make sure developer didn't forget to set the public key.
  NSAssert(self.DSAPublicKeyPEM, @"DSA public key is not set.");
  
  CFDataRef publicKeyData = CFBridgingRetain([self.DSAPublicKeyPEM dataUsingEncoding: NSUTF8StringEncoding]);
  
  // Turning our public key in PEM form into SecKeyRef.
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
  
  // Getting SecKeyRef from the array and retaining it.
  SecKeyRef publicKey = (SecKeyRef)CFRetain(CFArrayGetValueAtIndex(tempArray, 0));
  
  CFRelease(tempArray);
  
  // Creating signature verification transformation.
  CFDataRef tempSignature = CFBridgingRetain(signature);
  
  BOOL result = NO;
  
  BOOL reachedEnd = NO;
  
  CFErrorRef tempError;
  
  SecTransformRef verifyTransform = SecVerifyTransformCreate(publicKey, tempSignature, &tempError);
  
  CFRelease(publicKey);
  
  CFRelease(tempSignature);
  
  if(verifyTransform)
  {
    CFDataRef tempSourceData = CFBridgingRetain(sourceData);
    
    if(SecTransformSetAttribute(verifyTransform, kSecTransformInputAttributeName, tempSourceData, &tempError))
    {
      // See http://openradar.appspot.com/12184687
      CFBooleanRef booleanOrNull = SecTransformExecute(verifyTransform, &tempError);
      
      // The Apple' sample code seems to test the *error argument to determine success, instead of checking the result... Wat?
      if(booleanOrNull != NULL)
      {
        result = (booleanOrNull == kCFBooleanTrue)? YES : NO;
        
        reachedEnd = YES;
      }
    }
    
    CFRelease(tempSourceData);
    
    CFRelease(verifyTransform);
  }
  
  if(!reachedEnd)
  {
    // Control flow didn't reached end → something went wrong.
    *error = CFBridgingRelease(tempError);
  }
  
  return result;
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
