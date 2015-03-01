//
//  AppDelegate.m
//  Sample
//
//  Created by Konstantin Pavlikhin on 02.03.14.
//  Copyright (c) 2015 Konstantin Pavlikhin. All rights reserved.
//

#import "AppDelegate.h"

#import "../Watchdog.h"

@implementation AppDelegate

// Name:
// John Appleseed

// Serial:
// GBSQEMIA5K734JXT4ZEECT3MKTYD5MCYWZOXRZJ646R2AWYPN4ZXCFYZWNIHX4336BE5VFTY7VR4VVDQK2KNUARQMS3S3NAUNGPUIQ536RBVJOQUC2SQBIGLVC5LQKV3VCX7D6WTKNCKE3NMGMBCS4CC5DGMBOD6UMS4Q===

- (void) applicationDidFinishLaunching: (NSNotification*) aNotification
{
  WDGRegistrationController* rc = [WDGRegistrationController sharedRegistrationController];
  
  NSMutableString* string = [NSMutableString string];
  
  [string appendString: @"-----BEGIN PUBLIC KEY-----\n"];
  
  [string appendString: @"MHYwEAYHKoZIzj0CAQYFK4EEACIDYgAECGfTRULbwMBUmw007OTW+VyHi/SnHXX8\n"];
  
  [string appendString: @"cSPgyb2gH+sUuQ7NYpay+3BIBHyzxh/x9PcdrHOGFwd0lVqP6y6wzPUMy4rHNO4W\n"];
  
  [string appendString: @"UZn1CvVGKuuwNoCDjAo4UqBQbuUwH9Ho"];
  
  [string appendString: @"-----END PUBLIC KEY-----"];
  
  rc.publicKeyPEM = string;
  
  [rc showRegistrationWindow: self];
}

@end
