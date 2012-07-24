////////////////////////////////////////////////////////////////////////////////
//  
//  RegistrationWindowController.h
//  
//  Watchdog
//  
//  Created by Konstantin Pavlikhin on 27/01/10.
//  
////////////////////////////////////////////////////////////////////////////////

@class SerialEntryController;

@class RegistrationStatusController;

@interface RegistrationWindowController : NSWindowController <NSWindowDelegate>

// Lazy SerialEntryController constructor.
- (SerialEntryController*) serialEntryController;

// Fade-in/fade-out subview switcher.
- (void) switchToSerialEntrySubview;

// Lazy RegistrationStatusController constructor.
- (RegistrationStatusController*) registrationStatusController;

// Fade-in/fade-out subview switcher.
- (void) switchToRegistrationStatusSubview;

@end
