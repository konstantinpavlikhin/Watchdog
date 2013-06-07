////////////////////////////////////////////////////////////////////////////////
//  
//  RegistrationWindowController.m
//  
//  Watchdog
//  
//  Created by Konstantin Pavlikhin on 27/01/10.
//  
////////////////////////////////////////////////////////////////////////////////

#import "WDRegistrationWindowController.h"

#import "WDRegistrationController.h"

#import "WDSerialEntryController.h"

#import "WDRegistrationStatusController.h"

#import <QuartzCore/CoreAnimation.h>

@implementation WDRegistrationWindowController
{
  WDSerialEntryController* serialEntryController;
  
  WDRegistrationStatusController* registrationStatusController;
}

- (id) init
{
  self = [super initWithWindowNibName: @"WDRegistrationWindow"];
  
  if(!self) return nil;
  
  // Immediately starting to observe WDRegistrationController's applicationState property.
  [[WDRegistrationController sharedRegistrationController] addObserver: self forKeyPath: ApplicationStateKeyPath options: NSKeyValueObservingOptionInitial context: NULL];
  
  return self;
}

- (void) dealloc
{
  // Terminating the observation.
  [[WDRegistrationController sharedRegistrationController] removeObserver: self forKeyPath: ApplicationStateKeyPath];
}

- (void) observeValueForKeyPath: (NSString*) keyPath ofObject: (id) object change: (NSDictionary*) change context: (void*) context
{
  WDRegistrationController* SRC = [WDRegistrationController sharedRegistrationController];
  
  if(object == SRC && [keyPath isEqualToString: ApplicationStateKeyPath])
  {
    SRC.applicationState == RegisteredApplicationState? [self switchToRegistrationStatusSubview] : [self switchToSerialEntrySubview];
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
- (WDSerialEntryController*) serialEntryController
{
  if(!serialEntryController)
  {
    serialEntryController = [WDSerialEntryController new];
    
    serialEntryController.windowController = self;
  }
  
  return serialEntryController;
}

// Lazy WDRegistrationStatusController constructor.
- (WDRegistrationStatusController*) registrationStatusController
{
  if(!registrationStatusController)
  {
    registrationStatusController = [WDRegistrationStatusController new];
    
    registrationStatusController.windowController = self;
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
  
  [serialEntryController setWindowController: nil];
  
  [registrationStatusController setWindowController: self];
  
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
  
  [registrationStatusController setWindowController: nil];
  
  [serialEntryController setWindowController: self];
  
  [self.window makeFirstResponder: serialEntryController.customerName];
}

@end
