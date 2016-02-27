//
//  WDGResources.m
//  Watchdog
//
//  Created by Konstantin Pavlikhin on 01.03.14.
//  Copyright (c) 2016 Konstantin Pavlikhin. All rights reserved.
//

#import "WDGResources.h"

@implementation WDGResources

+ (NSBundle*) resourcesBundle
{
  return [NSBundle bundleForClass: [self class]];
}

@end
