//
//  LicenseVerifier.m
//  Singlemizer
//
//  Created by Константин Павлихин on 27.01.10.
//  Copyright 2010 Minimalistic Dev. All rights reserved.
//

#import "LicenseVerifier.h"

#include "openssl-1.0.0e/pem.h"

@implementation LicenseVerifier

- (id) initWithPublicKeyInHexForm: (NSString*) key
{
  self = [super init];
  
  if(!self) return nil;
  
  publicKey = DSA_new(); if(!publicKey) return nil;
  
  NSData* publicKeyData = [NSData dataWithHexString: key]; if(!publicKeyData) return nil;
  
  const unsigned char* publicKeyBytes = [publicKeyData bytes]; // Deprecated? WTF?
  
  publicKey = d2i_DSA_PUBKEY(&publicKey, &publicKeyBytes, [publicKeyData length]); if(!publicKey) return nil;
  
  return self;
}

- (void) dealloc
{
  DSA_free(publicKey);
  
  [super dealloc];
}

- (BOOL) isLicenseKeyInBase32: (NSString*) licenseKeyInBase32 conformsToCustomerName: (NSString*) customerName
{
  // Проверяем входные данные.
	if([licenseKeyInBase32 length] == 0 || [customerName length] == 0) return NO;
	
  // Декодируем лицензионный ключ из base32.
	NSData* licenseKeyData = [NSData dataWithBase32String: licenseKeyInBase32]; if(!licenseKeyData) return NO;
  
  // Хэшируем имя покупателя.
	NSData* customerNameHash = [[customerName dataUsingEncoding: NSUTF8StringEncoding] SHA1Data]; if(!customerNameHash) return NO;
  
  // Проверяем цифровую подпись.
  return DSA_verify(0, [customerNameHash bytes], [customerNameHash length], [licenseKeyData bytes], [licenseKeyData length], publicKey);
}

@end
