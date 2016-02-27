//
//  WDGShakeAnimation.m
//  Watchdog
//
//  Created by Konstantin Pavlikhin on 27/01/10.
//  Copyright (c) 2016 Konstantin Pavlikhin. All rights reserved.
//

#import "WDGShakeAnimation.h"

CAKeyframeAnimation* shakeAnimation(NSRect frame, int numOfShakes, double duration, double vigour)
{
  CAKeyframeAnimation* shakeAnim = [CAKeyframeAnimation animation];
  
  CGMutablePathRef shakePath = CGPathCreateMutable();
  
  CGPathMoveToPoint(shakePath, NULL, NSMinX(frame), NSMinY(frame));
  
  for(int index = 0; index < numOfShakes; ++index)
  {
    CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) - frame.size.width * vigour, NSMinY(frame));
    
    CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) + frame.size.width * vigour, NSMinY(frame));
  }
  
  CGPathCloseSubpath(shakePath);
  
  [shakeAnim setPath: shakePath];
  
  CFRelease(shakePath);
  
  [shakeAnim setDuration: duration];
  
  return shakeAnim;
}
