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

// Fade-in/fade-out subview switcher.
- (void) switchToRegistrationStatusSubview
{
  NSView* contentView = self.window.contentView;
  
  if([[contentView subviews] containsObject: [serialEntryController view]])
  {
    [[contentView animator] replaceSubview: [serialEntryController view] with: [[self registrationStatusController] view]];
  }
  else
  {
    [contentView addSubview: [[self registrationStatusController] view]];
  }
  
  [self.window makeFirstResponder: registrationStatusController.dismissButton];
}

// Fade-in/fade-out subview switcher.
- (void) switchToSerialEntrySubview
{
  NSView* contentView = self.window.contentView;
  
  if([[contentView subviews] containsObject: [registrationStatusController view]])
  {
    [[contentView animator] replaceSubview: [registrationStatusController view] with: [[self serialEntryController] view]];
  }
  else
  {
    [[[self window] contentView] addSubview: [[self serialEntryController] view]];
  }
  
  [self.window makeFirstResponder: serialEntryController.customerName];
}

@end
