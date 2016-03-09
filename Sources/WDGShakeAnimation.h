//
//  WDGShakeAnimation.h
//  Watchdog
//
//  Created by Konstantin Pavlikhin on 27/01/10.
//  Copyright (c) 2016 Konstantin Pavlikhin. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

// numOfShakes = 4; duration = 0.4; vigour = 0.05;

// [window setAnimations: [NSDictionary dictionaryWithObject: WDGShakeAnimation([window frame], 4, 0.4, 0.05) forKey: @"frameOrigin"]];

// [[window animator] setFrameOrigin: [window frame].origin];

CAKeyframeAnimation* WDGShakeAnimation(NSRect frame, int numOfShakes, double duration, double vigour);
