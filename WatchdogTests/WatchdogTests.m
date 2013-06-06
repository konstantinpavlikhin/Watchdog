//
//  WatchdogTests.m
//  WatchdogTests
//
//  Created by Konstantin Pavlikhin on 6/5/13.
//  Copyright (c) 2013 Konstantin Pavlikhin. All rights reserved.
//

#import "WatchdogTests.h"

#import "Specta.h"

#define EXP_SHORTHAND

#import "Expecta.h"

#import "WDRegistrationController+Private.h"

SpecBegin(WDRegistrationController)

describe(@"WDRegistrationController", ^
{
  it(@"should accept valid serials", ^
  {
    WDRegistrationController* SRC = [WDRegistrationController sharedRegistrationController];
    
    NSArray* prefixes = @[@"secp384r1", @"secp521r1", @"1024", @"2048"];
    
    [prefixes enumerateObjectsUsingBlock: ^(NSString* prefix, NSUInteger idx, BOOL* stop)
    {
      NSString* publicPEMName = [prefix stringByAppendingString: @"-public"];
      
      NSString* publicPEMPath = [[NSBundle bundleForClass: [self class]] pathForResource: publicPEMName ofType: @"pem" inDirectory: nil];
      
      SRC.DSAPublicKeyPEM = [NSString stringWithContentsOfFile: publicPEMPath encoding: NSUTF8StringEncoding error: NULL];
      
      NSString* dataName = [prefix stringByAppendingString: @"-data"];
      
      NSString* dataPath = [[NSBundle bundleForClass: [self class]] pathForResource: dataName ofType: @"plist" inDirectory: nil];
      
      NSArray* dataArray = [NSPropertyListSerialization propertyListWithData: [NSData dataWithContentsOfFile: dataPath] options: 0 format: 0 error: NULL];
      
      [dataArray enumerateObjectsUsingBlock: ^(NSDictionary* customer, NSUInteger idx, BOOL* stop)
      {
        expect([SRC isSerial: customer[@"Serial"] conformsToCustomerName: customer[@"Name"] error: NULL]).to.equal(YES);
      }];
    }];
  });
});

SpecEnd
