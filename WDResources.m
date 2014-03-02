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
  NSURL* bundleURL = [[NSBundle mainBundle] URLForResource: @"WatchdogResources" withExtension: @"bundle"];
  
  return [NSBundle bundleWithURL: bundleURL];
}

@end
