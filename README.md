
# Watchdog

Watchdog is a simple application registration framework based on the DSA signature algorithm.


# Configuring Watchdog

At the launch time of your app (-applicationDidFinishLaunching?) request the RegistrationController singleton instance and then set its properies. The only mandatory property is DSAPublicKeyPEM.


## Registering application

To register application call -registerWithQuickApplyLink: or -registerWithCustomerName:serial:handler: method of the RegistrationController class.


## Performing validation

To validate application state call -checkForStoredSerialAndValidateIt method of the RegistrationController class. This is most commonly made only once during the application startup.


## Accessing current application state

Watchdog relies on the Objective-C/Cocoa Key-Value Observing mechanism to deliver information about app state changes (Registered/Unregistered/Unknown). Register your application delegate object (or any other object you think is more appropriate, like TrialController and so on) as an observer of the applicationState property of the RegistrationController and make corresponding actions like blocking some part of your app if trial is over.


## Watchdog GUI Behavior

* First launch of the newely downloaded (and unregistered) application.
  Nothing visible happens.

* Second (and every subsequent) launch of the downloaded (and unregistered) application.
  Nothing visible happens.

* User follows a Quick-Apply link.
  If registration data is incorrect error alert is displayed and app stays in unregistered state. If customer name conforms to the serial registration window is displayed with the status view.

* User clicks "Registration..." menu item at the top of the screen.
  Registration window is shown with the appropriate view (serial entry or registration status).

* Application launches with no customer name & serial stored in user defaults.
  Application silently goes to the unregistered state.

* Application launches with stored customer name & serial and verification shows its incorrect.
  Error alert is displayed and application is set to the unregistered state.

* Application is correctly registered but -deauthorizeAccount method is called.
  Application silently goes to the unregistered state.

* Application is correctly registered but user follows a corrupted Quick-Apply Link.
  Application is deauthorized and error alert is displayed.
