////////////////////////////////////////////////////////////////////////////////
//  
//  RegistrationWindowController.h
//  
//  Watchdog
//  
//  Created by Konstantin Pavlikhin on 27/01/10.
//  
////////////////////////////////////////////////////////////////////////////////

@class WDSerialEntryController;

@class WDRegistrationStatusController;

@interface WDRegistrationWindowController : NSWindowController <NSWindowDelegate>

// Lazy WDSerialEntryController constructor.
- (WDSerialEntryController*) serialEntryController;

// Fade-in/fade-out subview switcher.
- (void) switchToSerialEntrySubview;

// Lazy WDRegistrationStatusController constructor.
- (WDRegistrationStatusController*) registrationStatusController;

// Fade-in/fade-out subview switcher.
- (void) switchToRegistrationStatusSubview;

@end
