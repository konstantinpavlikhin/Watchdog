////////////////////////////////////////////////////////////////////////////////
//  
//  RegistrationWindowController.h
//  
//  Watchdog
//  
//  Created by Konstantin Pavlikhin on 27/01/10.
//  
////////////////////////////////////////////////////////////////////////////////

@class LicenseEnterController;

@class LicenseStatusController;

@interface RegistrationWindowController : NSWindowController <NSWindowDelegate>
{
  LicenseEnterController* licenseEnterController;
  
  LicenseStatusController* licenseStatusController;
}

// Лениво конструирует licenseEnterController.
- (LicenseEnterController*) licenseEnterController;

// Лениво конструирует licenseStatusController.
- (LicenseStatusController*) licenseStatusController;

// Переключает виды с fade-анимацией.
- (void) switchToLicenseStatusSubview;

- (void) switchToLicenseEnterSubview;

@end
