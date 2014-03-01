////////////////////////////////////////////////////////////////////////////////
//  
//  ShakeAnimation.h
//  
//  KPToolbox
//  
//  Created by Konstantin Pavlikhin on unknown.
//  
////////////////////////////////////////////////////////////////////////////////

#import <QuartzCore/QuartzCore.h>

// numOfShakes = 4; duration = 0.4; vigour = 0.05;

// [window setAnimations: [NSDictionary dictionaryWithObject: shakeAnimation([window frame], 4, 0.4, 0.05) forKey: @"frameOrigin"]];

// [[window animator] setFrameOrigin: [window frame].origin];

CAKeyframeAnimation* shakeAnimation(NSRect frame, int numOfShakes, double duration, double vigour);
