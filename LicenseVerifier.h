//
//  LicenseVerifier.h
//  Singlemizer
//
//  Created by Константин Павлихин on 27.01.10.
//  Copyright 2010 Minimalistic Development. All rights reserved.
//

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
