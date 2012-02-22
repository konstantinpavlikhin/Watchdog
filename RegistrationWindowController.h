//
//  RegistrationWindowController.h
//  Singlemizer
//
//  Created by Константин Павлихин on 27.01.10.
//  Copyright 2010 Minimalistic Dev. All rights reserved.
//

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
