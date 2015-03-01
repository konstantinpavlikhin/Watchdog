//
//  WDGRegistrationWindowController.m
//  Watchdog
//
//  Created by Konstantin Pavlikhin on 27/01/10.
//  Copyright (c) 2015 Konstantin Pavlikhin. All rights reserved.
//

#import "WDGRegistrationWindowController.h"

#import "WDGRegistrationController.h"

#import "WDGSerialEntryController.h"

#import "WDGRegistrationStatusController.h"

#import "WDGResources.h"

#import <QuartzCore/CoreAnimation.h>

@implementation WDGRegistrationWindowController
{
  WDGSerialEntryController* serialEntryController;
  
  WDGRegistrationStatusController* registrationStatusController;
}

- (id) init
{
  NSString* path = [[WDGResources resourcesBundle] pathForResource: @"WDGRegistrationWindow" ofType: @"nib"];
  
  self = [super initWithWindowNibPath: path owner: self];
  
  if(!self) return nil;
  
  // Immediately starting to observe WDRegistrationController's applicationState property.
  [[WDGRegistrationController sharedRegistrationController] addObserver: self forKeyPath: ApplicationStateKeyPath options: NSKeyValueObservingOptionInitial context: NULL];
  
  return self;
}

- (void) dealloc
{
  // Terminating the observation.
  [[WDGRegistrationController sharedRegistrationController] removeObserver: self forKeyPath: ApplicationStateKeyPath];
}

- (void) observeValueForKeyPath: (NSString*) keyPath ofObject: (id) object change: (NSDictionary*) change context: (void*) context
{
  WDGRegistrationController* SRC = [WDGRegistrationController sharedRegistrationController];
  
  if(object == SRC && [keyPath isEqualToString: ApplicationStateKeyPath])
  {
    SRC.applicationState == WDGRegisteredApplicationState? [self switchToRegistrationStatusSubview] : [self switchToSerialEntrySubview];
  }
}

- (void) windowDidLoad
{
  // Adjusting subview change animation.
  CATransition* fadeTransition = [CATransition animation];
  
  [fadeTransition setType: kCATransitionFade];
  
  [fadeTransition setDuration: 0.3];
  
  NSDictionary* animations = [NSDictionary dictionaryWithObject: fadeTransition forKey: @"subviews"];
  
  [[self.window contentView] setAnimations: animations];
  
  [[self.window contentView] setWantsLayer: YES];
}

- (IBAction) showWindow: (id) sender
{
  // If the window is closed — showing it at the visual center of the screen.
  if(![[self window] isVisible]) [[self window] center];
  
  [super showWindow: sender];
}

// Lazy WDSerialEntryController constructor.
- (WDGSerialEntryController*) serialEntryController
{
  if(!serialEntryController)
  {
    serialEntryController = [WDGSerialEntryController new];
  }
  
  return serialEntryController;
}

// Lazy WDRegistrationStatusController constructor.
- (WDGRegistrationStatusController*) registrationStatusController
{
  if(!registrationStatusController)
  {
    registrationStatusController = [WDGRegistrationStatusController new];
  }
  
  return registrationStatusController;
}

- (void) switchToRegistrationStatusSubview
{
  NSView* contentView = self.window.contentView;
  
  if([contentView.subviews containsObject: serialEntryController.view])
  {
    [serialEntryController.view removeFromSuperview];
  }
  
  [self registrationStatusController].view.translatesAutoresizingMaskIntoConstraints = NO;
  
  [self.window.contentView addSubview: [self registrationStatusController].view];
  
  {{
    NSDictionary* views = @{@"registrationStatus": [self registrationStatusController].view};
    
    [contentView addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[registrationStatus]|" options: 0 metrics: nil views: views]];
    
    [contentView addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[registrationStatus]|" options: 0 metrics: nil views: views]];
  }}
  
  [self.window makeFirstResponder: registrationStatusController.dismissButton];
}

- (void) switchToSerialEntrySubview
{
  NSView* contentView = self.window.contentView;
  
  if([contentView.subviews containsObject: registrationStatusController.view])
  {
    [registrationStatusController.view removeFromSuperview];
  }
  
  [self serialEntryController].view.translatesAutoresizingMaskIntoConstraints = NO;
  
  [self.window.contentView addSubview: [self serialEntryController].view];
  
  {{
    NSDictionary* views = @{@"serialEntry": [self serialEntryController].view};
    
    [contentView addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"H:|[serialEntry]|" options: 0 metrics: nil views: views]];
    
    [contentView addConstraints: [NSLayoutConstraint constraintsWithVisualFormat: @"V:|[serialEntry]|" options: 0 metrics: nil views: views]];
  }}
  
  [self.window makeFirstResponder: serialEntryController.customerName];
}

@end
