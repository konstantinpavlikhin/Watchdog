////////////////////////////////////////////////////////////////////////////////
//  
//  LicenseVerifier.h
//  
//  Watchdog
//  
//  Created by Konstantin Pavlikhin on 27/01/10.
//  
////////////////////////////////////////////////////////////////////////////////

#include "openssl-1.0.0e/dsa.h"

@interface LicenseVerifier : NSObject
{
  DSA* publicKey;
}

// Инициализирует проверятор открытым ключем.
- (id) initWithPublicKeyInHexForm: (NSString*) key;

// Проверяет - соответствует ли подпись введенному имени.
- (BOOL) isLicenseKeyInBase32: (NSString*) licenseKeyInBase32 conformsToCustomerName: (NSString*) customerName;

@end
