//
//  WDResources.m
//  Watchdog
//
//  Created by Konstantin Pavlikhin on 01.03.14.
//  Copyright (c) 2014 Konstantin Pavlikhin. All rights reserved.
//

#import "WDResources.h"

@implementation WDResources

+ (NSBundle*) resourcesBundle
{
  return [NSBundle bundleForClass: [self class]];
}

@end
