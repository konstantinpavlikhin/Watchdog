//
//  WDGRegistrationController.m
//  Watchdog
//
//  Created by Konstantin Pavlikhin on 27/01/10.
//  Copyright (c) 2015 Konstantin Pavlikhin. All rights reserved.
//

#import "WDGRegistrationController+Private.h"

#import "WDGRegistrationWindowController.h"

#import "WDGPlistConstants.h"

#import "WDGResources.h"

#import <CommonCrypto/CommonDigest.h>

NSString* const WDGCustomerNameKey = @"WDGCustomerName";

NSString* const WDGSerialKey = @"WDGSerial";

NSString* const WDGDynamicBlacklistKey = @"WDGDynamicBlacklist";

// WDGRegistrationController is a singleton instance, so we can allow ourselves this trick.
static WDGRegistrationWindowController* registrationWindowController = nil;

@implementation WDGRegistrationController

#pragma mark - Public Methods

+ (WDGRegistrationController*) sharedRegistrationController
{
  static dispatch_once_t predicate;
  
  static WDGRegistrationController *sharedRegistrationController = nil;
  
  dispatch_once(&predicate, ^{ sharedRegistrationController = [self new]; });
  
  return sharedRegistrationController;
}

// Supplied link should look like this: bundlename-wd://WEDSCVBNMRFHNMJJFCV:GAWWSXFRFVBJU...CVBNMHSGHFKAJSHC.
- (NSDictionary*) decomposeQuickApplyLink: (NSString*) link utilizingBundleName: (NSString*) bundleName
{
  NSParameterAssert(link);
  
  NSParameterAssert(bundleName);
  
  // Concatenating URL scheme part with suffix.
  NSString* schemeWithSlashes = [[bundleName lowercaseString] stringByAppendingString: @"-wd://"];
  
  // Wiping out link prefix.
  NSString* nameColonSerial = [link stringByReplacingOccurrencesOfString: schemeWithSlashes withString: @""];
  
  NSRange rangeOfColon = [nameColonSerial rangeOfString: @":"];
  
  // Colon (name/serial separator) not found — link is corrupted.
  if(rangeOfColon.location == NSNotFound) return nil;
  
  NSString* customerNameInBase32 = nil;
  
  NSString* serial = nil;
  
  // -substringToIndex or -substringFromIndex can raise an exception...
  @try
  {
    customerNameInBase32 = [nameColonSerial substringToIndex: rangeOfColon.location];
    
    serial = [nameColonSerial substringFromIndex: rangeOfColon.location + 1];
  }
  @catch(NSException* exception)
  {
    return nil;
  }
  
  if(!customerNameInBase32 || !serial) return nil;
  
  // If we are here we already got two base32 encoded parts: customer name & the serial itself. Lets decode a name!
  
  NSDictionary* result = nil;
  
  SecTransformRef base32DecodeTransform = SecDecodeTransformCreate(kSecBase32Encoding, NULL);
  
  if(base32DecodeTransform)
  {
    CFDataRef tempData = CFBridgingRetain([customerNameInBase32 dataUsingEncoding: NSUTF8StringEncoding]);
    
    if(SecTransformSetAttribute(base32DecodeTransform, kSecTransformInputAttributeName, tempData, NULL))
    {
      CFTypeRef customerNameData = SecTransformExecute(base32DecodeTransform, NULL);
      
      if(customerNameData)
      {
        NSString* customerName = [[NSString alloc] initWithData: CFBridgingRelease(customerNameData) encoding: NSUTF8StringEncoding];
        
        result = @{@"name": customerName, @"serial": serial};
      }
    }
    
    CFRelease(tempData);
    
    CFRelease(base32DecodeTransform);
  }
  
  return result;
}

- (void) registerWithQuickApplyLink: (NSString*) link
{
  NSParameterAssert(link);
  
  // Getting non-localized application name.
  NSString* bundleName = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleName"];
  
  NSDictionary* dict = [self decomposeQuickApplyLink: link utilizingBundleName: bundleName];
  
  if(!dict)
  {
    [[[self class] corruptedQuickApplyLinkAlert] runModal];
    
    return;
  }
  
  [self registerWithCustomerName: dict[@"name"] serial: dict[@"serial"] handler: ^(WDGSerialVerdict verdict)
  {
    dispatch_async(dispatch_get_main_queue(), ^()
    {
      if(verdict != WDGSerialVerdictValid)
      {
        [[[self class] alertWithSerialVerdict: verdict] runModal];
        
        return;
      }
      
      [self showRegistrationWindow: self];
    });
  }];
}

// Tries to register application with supplied customer name & serial pair.
- (void) registerWithCustomerName: (NSString*) name serial: (NSString*) serial handler: (SerialCheckHandler) handler
{
  NSParameterAssert(name);
  
  NSParameterAssert(serial);
  
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
  {
    // Launching full-featured customer data check.
    [self complexCheckOfCustomerName: name serial: serial completionHandler: ^(WDGSerialVerdict verdict)
    {
      // If all of the tests pass...
      if(verdict == WDGSerialVerdictValid)
      {
        // KVO-notifications always arrive on the same thread that set the value.
        dispatch_async(dispatch_get_main_queue(), ^()
        {
          NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
          
          [userDefaults setObject: name forKey: WDGCustomerNameKey];
          
          [userDefaults setObject: serial forKey: WDGSerialKey];
          
          [userDefaults synchronize];
          
          // * * *.
          
          self.applicationState = WDGApplicationStateRegistered;
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
  if([self applicationState] != WDGApplicationStateRegistered) return nil;
  
  return [[NSUserDefaults standardUserDefaults] stringForKey: WDGCustomerNameKey];
}

- (void) deauthorizeAccount
{
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  
  [userDefaults removeObjectForKey: WDGCustomerNameKey];
  
  [userDefaults removeObjectForKey: WDGSerialKey];
  
  [userDefaults synchronize];
  
  dispatch_async(dispatch_get_main_queue(), ^()
  {
    self.applicationState = WDGApplicationStateUnregistered;
  });
}

- (void) checkForStoredSerialAndValidateIt
{
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^()
  {
    // Looking for serial data in user preferences.
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString* name = [userDefaults stringForKey: WDGCustomerNameKey];
    
    NSString* serial = [userDefaults stringForKey: WDGSerialKey];
    
    // If one of parameters is missing — treat it (silently) like unregistered state.
    if(!name || !serial)
    {
      dispatch_async(dispatch_get_main_queue(), ^()
      {
        self.applicationState = WDGApplicationStateUnregistered;
      });
      
      return;
    };
    
    [self complexCheckOfCustomerName: name serial: serial completionHandler: ^(WDGSerialVerdict serialVerdict)
    {
      dispatch_async(dispatch_get_main_queue(), ^()
      {
        if(serialVerdict == WDGSerialVerdictValid)
        {
          self.applicationState = WDGApplicationStateRegistered;
          
          return;
        }
        
        [self deauthorizeAccount];
        
        [[[self class] alertWithSerialVerdict: serialVerdict] runModal];
      });
    }];
  });
}

#pragma mark - Private Methods

+ (NSAlert*) corruptedQuickApplyLinkAlert
{
  NSAlert* alert = [[NSAlert alloc] init];
  
  [alert setMessageText: NSLocalizedStringFromTableInBundle(@"Corrupted Quick-Apply Link", nil, [WDGResources resourcesBundle], @"Alert title.")];
  
  [alert setInformativeText: NSLocalizedStringFromTableInBundle(@"Please enter your registration data manualy.", nil, [WDGResources resourcesBundle], @"Alert body.")];
  
  return alert;
}

+ (NSAlert*) corruptedRegistrationDataAlert
{
  NSAlert* alert = [[NSAlert alloc] init];
  
  [alert setMessageText: NSLocalizedStringFromTableInBundle(@"Serial validation fail", nil, [WDGResources resourcesBundle], @"Alert title.")];
  
  [alert setInformativeText: NSLocalizedStringFromTableInBundle(@"Your serial is corrupted. Please, try again.", nil, [WDGResources resourcesBundle], @"Alert body.")];
  
  return alert;
}

+ (NSAlert*) blacklistedRegistrationDataAlert
{
  NSAlert* alert = [[NSAlert alloc] init];
  
  [alert setMessageText: NSLocalizedStringFromTableInBundle(@"Serial validation fail", nil, [WDGResources resourcesBundle], @"Alert title.")];
  
  [alert setInformativeText: NSLocalizedStringFromTableInBundle(@"Your serial is blacklisted. Please, contact support to get a new key.", nil, [WDGResources resourcesBundle], @"Alert body.")];
  
  return alert;
}

+ (NSAlert*) piratedRegistrationDataAlert
{
  NSAlert* alert = [[NSAlert alloc] init];
  
  [alert setMessageText: NSLocalizedStringFromTableInBundle(@"Serial validation fail", nil, [WDGResources resourcesBundle], @"Alert title.")];
  
  [alert setInformativeText: NSLocalizedStringFromTableInBundle(@"It seems like you are using pirated serial.", nil, [WDGResources resourcesBundle], @"Alert body.")];
  
  return alert;
}

+ (NSAlert*) alertWithSerialVerdict: (WDGSerialVerdict) verdict
{
  NSAlert* alert = nil;
  
  switch(verdict)
  {
    // Compiler generates warning if this constant not handled in switch.
    case WDGSerialVerdictValid:
    {
      alert = nil;
      
      break;
    }
    
    case WDGSerialVerdictCorrupted:
    {
      alert = [self corruptedRegistrationDataAlert];
      
      break;
    }
    
    case WDGSerialVerdictBlacklisted:
    {
      alert = [self blacklistedRegistrationDataAlert];
      
      break;
    }
    
    case WDGSerialVerdictPirated:
    {
      alert = [self piratedRegistrationDataAlert];
      
      break;
    }
  }
  
  return alert;
}

// Lazy RegistrationWindowController constructor.
- (WDGRegistrationWindowController*) registrationWindowController
{
  if(!registrationWindowController) registrationWindowController = [WDGRegistrationWindowController new];
  
  return registrationWindowController;
}

- (void) complexCheckOfCustomerName: (NSString*) name serial: (NSString*) serial completionHandler: (SerialCheckHandler) handler
{
  NSParameterAssert(name);
  
  NSParameterAssert(serial);
  
  // Если лицензия не расшифровалась...
  if(![self isSerial: serial conformsToCustomerName: name error: NULL])
  {
    handler(WDGSerialVerdictCorrupted); return;
  }
  
  // Если лицензия найдена в одном из черных списков...
  if([self isSerialInStaticBlacklist: serial] || [self isSerialInDynamicBlacklist: serial])
  {
    handler(WDGSerialVerdictBlacklisted); return;
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
        
        result = [self verifySignature: tempSignature data: [name dataUsingEncoding: NSUTF8StringEncoding] error: error];
        
        reachedEnd = YES;
      }
    }
    
    CFRelease(tempData);
    
    CFRelease(base32DecodeTransform);
  }
  
  if(!reachedEnd)
  {
    // Control flow didn't reached end → something went wrong.
    if(error != NULL) *error = CFBridgingRelease(tempError);
  }
  
  return result;
}

- (BOOL) verifySignature: (NSData*) signature data: (NSData*) sourceData error: (NSError* __autoreleasing *) error
{
  // These parameters are mandatory.
  NSParameterAssert(signature);
  
  NSParameterAssert(sourceData);
  
  // Make sure developer didn't forget to set the public key.
  NSAssert(self.publicKeyPEM, @"DSA/ECDSA public key is not set.");
  
  CFDataRef publicKeyData = CFBridgingRetain([self.publicKeyPEM dataUsingEncoding: NSUTF8StringEncoding]);
  
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
  SecItemImport(publicKeyData, NULL, &externalFormat, &externalItemType, 0, &itemImportExportKeyParameters, NULL, &tempArray);
  
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
    if(error != NULL) *error = CFBridgingRelease(tempError);
  }
  
  return result;
}

+ (NSData*) SHA1DataWithData: (NSData*) data
{
  unsigned char hashBytes[CC_SHA1_DIGEST_LENGTH];
  
  CC_SHA1((const unsigned char*)[data bytes], (CC_LONG)[data length], (unsigned char*)hashBytes);
  
  return [NSData dataWithBytes: hashBytes length: CC_SHA1_DIGEST_LENGTH];
}

+ (NSString*) hexStringWithData: (NSData*) data
{
  NSUInteger dataLength = [data length];
  
  const unsigned char* dataBytes = [data bytes];
  
  NSMutableString* result = [NSMutableString stringWithCapacity: dataLength * 2];
  
  for(NSUInteger i = 0; i < dataLength; i++)
  {
    [result appendFormat: @"%02x", dataBytes[i]];
  }
  
  return result;
}

// Performs server check of the supplied serial.
- (WDGSerialVerdict) synchronousServerCheckWithSerial: (NSString*) serial
{
  NSParameterAssert(serial);
  
  NSString* serialCheckBase = [[NSBundle mainBundle] objectForInfoDictionaryKey: WDGServerCheckURLKey];
  
  NSData* userNameData = [NSUserName() dataUsingEncoding: NSUTF8StringEncoding];
  
  NSString* userNameHash = [[self class] hexStringWithData: [[self class] SHA1DataWithData: userNameData]];
  
  NSString* queryString = [NSString stringWithFormat: @"%@?serial=%@&account=%@", serialCheckBase, serial, userNameHash];
  
  NSMutableURLRequest* URLRequest = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: queryString]];
  
  {{
    NSString* hostAppName = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleName"];
    
    [URLRequest setValue: hostAppName? hostAppName : @"Watchdog" forHTTPHeaderField: @"User-agent"];
  }}
  
  [URLRequest setTimeoutInterval: 3.0];
  
  NSURLResponse* URLResponse = nil;
  
  NSError* error = nil;
  
  NSData* responseData = [NSURLConnection sendSynchronousRequest: URLRequest returningResponse: &URLResponse error: &error];
  
  NSString* string = [[NSString alloc] initWithData: responseData encoding: NSUTF8StringEncoding];
  
  if([string isEqualToString: @"Valid"])
  {
    return WDGSerialVerdictValid;
  }
  else if([string isEqualToString: @"Blacklisted"])
  {
    [self addSerialToDynamicBlacklist: serial];
    
    return WDGSerialVerdictBlacklisted;
  }
  else if([string isEqualToString: @"Pirated"])
  {
    [self addSerialToDynamicBlacklist: serial];
    
    return WDGSerialVerdictPirated;
  }
  
  // Not going to be too strict at this point.
  return WDGSerialVerdictValid;
}

// Checks whether specified serial is present in the static blacklist.
- (BOOL) isSerialInStaticBlacklist: (NSString*) serial
{
  NSParameterAssert(serial);
  
  return [self.serialsStaticBlacklist containsObject: serial];
}

// Checks whether specified serial is present in the dynamic blacklist.
- (BOOL) isSerialInDynamicBlacklist: (NSString*) serial
{
  NSParameterAssert(serial);
  
  NSArray* dynamicBlacklist = [[NSUserDefaults standardUserDefaults] arrayForKey: WDGDynamicBlacklistKey];
  
  return [dynamicBlacklist containsObject: serial];
}

// Adds specified serial to the dynamic blacklist.
- (void) addSerialToDynamicBlacklist: (NSString*) serial
{
  NSParameterAssert(serial);
  
  NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
  
  NSArray* dynamicBlacklist = [userDefaults arrayForKey: WDGDynamicBlacklistKey];
  
  if(!dynamicBlacklist) dynamicBlacklist = [NSArray array];
  
  [userDefaults setObject: [dynamicBlacklist arrayByAddingObject: serial] forKey: WDGDynamicBlacklistKey];
}

@end
