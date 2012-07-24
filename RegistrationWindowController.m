////////////////////////////////////////////////////////////////////////////////
//  
//  RegistrationWindowController.m
//  
//  Watchdog
//  
//  Created by Konstantin Pavlikhin on 27/01/10.
//  
////////////////////////////////////////////////////////////////////////////////

#import "RegistrationWindowController.h"

#import "RegistrationController.h"

#import "SerialEntryController.h"

#import "RegistrationStatusController.h"

#import <QuartzCore/CoreAnimation.h>

NSString* const ApplicationStateKeyPath = @"applicationState";

@implementation RegistrationWindowController
{
  SerialEntryController* serialEntryController;
  
  RegistrationStatusController* registrationStatusController;
}

- (id) init
{
  self = [super initWithWindowNibName: @"RegistrationWindow"];
  
  if(!self) return nil;
  
  // Starting to observe RegistrationController's applicationState property.
  [[RegistrationController sharedRegistrationController] addObserver: self forKeyPath: ApplicationStateKeyPath options: 0 context: NULL];
  
  return self;
}

- (void) dealloc
{
  // Terminating the observation.
  [[RegistrationController sharedRegistrationController] removeObserver: self forKeyPath: ApplicationStateKeyPath];
  
  [serialEntryController release], serialEntryController = nil;
  
  [registrationStatusController release], registrationStatusController = nil;
  
  [super dealloc];
}

- (void) observeValueForKeyPath: (NSString*) keyPath ofObject: (id) object change: (NSDictionary*) change context: (void*) context
{
  RegistrationController* SRC = [RegistrationController sharedRegistrationController];
  
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

- (SerialEntryController*) serialEntryController
{
  if(!serialEntryController)
  {
    serialEntryController = [SerialEntryController new];
    
    serialEntryController.windowController = self;
  }
  
  return serialEntryController;
}

- (RegistrationStatusController*) registrationStatusController
{
  if(!registrationStatusController)
  {
    registrationStatusController = [RegistrationStatusController new];
    
    registrationStatusController.windowController = self;
  }
  
  return registrationStatusController;
}

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
