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
  it(@"should differentiate valid serials from corrupted", ^
  {
    WDRegistrationController* SRC = [WDRegistrationController sharedRegistrationController];
    
    NSString* path = [[NSBundle bundleForClass: [self class]] pathForResource: @"SamplePublicKey" ofType: @"pem" inDirectory: nil];
    
    SRC.DSAPublicKeyPEM = [NSString stringWithContentsOfFile: path encoding: NSUTF8StringEncoding error: NULL];
    
    expect([SRC isSerial: @"GAWAEFAT2C5CQLRALLUX4DZ2YU6XFSD3YRRTCYICCRZQ6M4ONA4253TRAX3DNFLODY76TCYJ2Y" conformsToCustomerName: @"Konstantin Pavlikhin" error: NULL]).to.equal(YES);
    
    //expect([SRC isSerial: @"AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" conformsToCustomerName: @"Konstantin Pavlikhin" error: NULL]).to.equal(NO);
    
    expect([SRC isSerial: @"GAWAEFAT2C5CQLRALLUX4DZ2YU6XFSD3YRRTCYICCRZQ6M4ONA4253TRAX3DNFLODY76TCYJ2Y" conformsToCustomerName: @"Somebody Else" error: NULL]).to.equal(NO);
  });
});

SpecEnd
