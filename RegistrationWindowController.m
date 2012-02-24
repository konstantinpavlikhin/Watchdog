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

#import <QuartzCore/CoreAnimation.h>

#import "LicenseController.h"

#import "LicenseEnterController.h"

#import "LicenseStatusController.h"

@implementation RegistrationWindowController

- (id) init
{
  /*
  // Настраиваем HUD-панель регистрации.
  NSPanel* registrationPanel = [[[NSPanel alloc] initWithContentRect: NSZeroRect styleMask: 0 backing: 0 defer: NO] autorelease];
  
  [registrationPanel setDelegate: self];
  
  [registrationPanel setContentSize: NSMakeSize(480.0, 270.0)];
  
  [registrationPanel setStyleMask: NSHUDWindowMask | NSTitledWindowMask | NSUtilityWindowMask | NSClosableWindowMask];
  
  [registrationPanel setBackingType: NSBackingStoreBuffered];
  
  [registrationPanel setHidesOnDeactivate: NO];
  
  enableBlurForWindow(registrationPanel);
  
  // Настраиваем анимацию смены подвидов.
  CATransition* fadeTransition = [CATransition animation];
  
  [fadeTransition setType: kCATransitionFade];
  
  [fadeTransition setDuration: 0.3];
  
  NSDictionary* animations = [NSDictionary dictionaryWithObject: fadeTransition forKey: @"subviews"];
  
  [[registrationPanel contentView] setAnimations: animations];
  
  [[registrationPanel contentView] setWantsLayer: YES];
  */
  
  // Возвращаем контроллер с окошком.
  //self = [super initWithWindow: registrationPanel];
  self = [super initWithWindowNibName: @"LicenseWindow"];
  
  return self;
}

- (void) dealloc
{
  [licenseEnterController release];
  
  [licenseStatusController release];
  
  [super dealloc];
}

- (void) windowDidLoad
{
  // Настраиваем анимацию смены подвидов.
  CATransition* fadeTransition = [CATransition animation];
  
  [fadeTransition setType: kCATransitionFade];
  
  [fadeTransition setDuration: 0.3];
  
  NSDictionary* animations = [NSDictionary dictionaryWithObject: fadeTransition forKey: @"subviews"];
  
  [[self.window contentView] setAnimations: animations];
  
  [[self.window contentView] setWantsLayer: YES];
}

- (IBAction) showWindow: (id) sender
{
  [[[self window] contentView] setSubviews: [NSArray array]];
  
  ApplicationStatus appStatus = [[LicenseController sharedLicenseController] applicationStatus];
  
  if(appStatus == RegisteredApplicationStatus)
  {
    [self switchToLicenseStatusSubview];
  }
  else if(appStatus == UnregisteredApplicationStatus)
  {
    [self switchToLicenseEnterSubview];
  }
  
  // Если окно закрыто, то показываем его по визуальному центру экрана.
  if(![[self window] isVisible]) [[self window] center];
  
  [super showWindow: sender];
}

- (LicenseEnterController*) licenseEnterController
{
  if(!licenseEnterController)
  {
    licenseEnterController = [[LicenseEnterController alloc] init];
    
    licenseEnterController.windowController = self;
  }
  
  return licenseEnterController;
}

- (LicenseStatusController*) licenseStatusController
{
  if(!licenseStatusController)
  {
    licenseStatusController = [LicenseStatusController new];
    
    licenseEnterController.windowController = self;
  }
  
  return licenseStatusController;
}

- (void) switchToLicenseStatusSubview
{
  NSArray* contentViewSubviews = [[[self window] contentView] subviews];
  
  if([contentViewSubviews containsObject: [licenseEnterController view]])
  {
    [[[[self window] contentView] animator] replaceSubview: [licenseEnterController view] with: [[self licenseStatusController] view]];
  }
  else
  {
    [[[self window] contentView] addSubview: [[self licenseStatusController] view]];
  }
  
  [licenseEnterController setWindowController: nil];
  
  [licenseStatusController setWindowController: self];
  
  [licenseStatusController viewDidAppear];
  
  [self.window makeFirstResponder: licenseStatusController.dismissButton];
}

- (void) switchToLicenseEnterSubview
{
  NSArray* contentViewSubviews = [[[self window] contentView] subviews];
  
  if([contentViewSubviews containsObject: [licenseStatusController view]])
  {
    [[[[self window] contentView] animator] replaceSubview: [licenseStatusController view] with: [[self licenseEnterController] view]];
  }
  else
  {
    [[[self window] contentView] addSubview: [[self licenseEnterController] view]];
  }
  
  [licenseStatusController setWindowController: nil];
  
  [licenseEnterController setWindowController: self];
  
  [self.window makeFirstResponder: licenseEnterController.customerName];
}

@end
