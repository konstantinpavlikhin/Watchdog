//
//  WDGExplanationLabel.m
//  Watchdog
//
//  Created by Konstantin Pavlikhin on 01.03.15.
//  Copyright (c) 2016 Konstantin Pavlikhin. All rights reserved.
//

#import "WDGExplanationLabel.h"

@implementation WDGExplanationLabel

- (void) layout
{
  [self setPreferredMaxLayoutWidth: self.frame.size.width];
  
  [super layout];
}

@end
