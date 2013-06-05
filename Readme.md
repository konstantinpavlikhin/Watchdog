# Watchdog

Watchdog is a simple application registration framework based on the DSA signature.

## What Watchdog is not

Watchdog has nothing to do with with trial periods or evaluation launches count. It's up to you to implement an appropriate `TrialController` with behavior specific to your domain. There are numerous ways you can implement a trial. For example, some applications allow limited time of an unrestricted app usage, some allow limited number of launches when in trial mode, some just restrict feature set and so on... There is no possibility (an need) to abstract this stuff into Watchdog.

## Adding Watchdog to your project

1. Add Watchdog to your project as a submodule.
```bash
$ cd ~/Development/Application
$ git submodule add https://github.com/konstantinpavlikhin/Watchdog.git
$ git submodule update --init --recursive
```
2. Setup a dependency between your project and Watchdog
  * Find `Watchdog.xcodeproj` inside of the cloned repository directory and drag it into the Xcode' Project Navigator.
  * Configure your application target to be dependent on Watchdog.framework.
  * Link your application with the Watchdog.framework.
  * Add a "Copy Frameworks" build phase and add Watchdog.framework there.

## Configuring Watchdog

#### `ApplicationName-Info.plist`

Watchdog requires you to define the following keys in your `ApplicationName-Info.plist` file:

```xml
<!-- The URL of the application purchasing page. -->
<key>WDBuyOnlineURL</key>
<string>http://applicationapp.com/order</string>

<!-- The URL of the registration support page. -->
<key>WDSupportURL</key>
<string>http://applicationapp.com/support/register</string>

<!-- The URL of the serial key validation script. -->
<key>WDServerCheckURL</key>
<string>http://applicationapp/verify</string>

<!-- Custom URL scheme to inject customer name and a serial into the app. -->
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Viewer</string>
    <key>CFBundleURLIconFile</key>
    <string>SomeIcon.icns</string>
    <key>CFBundleURLName</key>
    <string>com.applicationapp.watchdog</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>lowercasedappname-wd</string>
    </array>
  </dict>
</array>
```

### `RegistrationController` Singleton

At the launch time of your app (`-applicationDidFinishLaunching:`) request the `RegistrationController` singleton instance and set its properies.

```objective-c
RegistrationController* SRC = [RegistrationController sharedRegistrationController];
```

Set the `DSAPublicKeyPEM` property to your application' DSA public key:
```objective-c
...
SRC.DSAPublicKeyPEM = @"-----BEGIN PUBLIC KEY-----\n ... -----END PUBLIC KEY-----";
```

Set the `serialsStaticBlacklist` property to the array of blacklisted serials (if you have some):
```objective-c
...
SRC.serialsStaticBlacklist = @(@"GAXAEFIAQCDINLKOVR4F6XFQUREC4RKX536WUFNFAIKQBCNWZF73M3YJCRWC76LRB3EUPD7D7SAWW", ...);
```

## Using Watchdog

### Observing states

Watchdog relies on a Key-Value Observing (KVO) mechanism to deliver information about application state changes. Add a relevant object as an observer of `applicationState` property to receive notifications when app transitions between `Unknown|Unregistered|Registered` states.

```objective-c
...
[SRC addObserver: self forKeyPath: ApplicationStateKeyPath options: NSKeyValueObservingOptionInitial context: NULL];
```

### Registering an app with concrete customer name & serial

Call `-registerWithCustomerName:serial:handler:` to asynchronously register application with concrete name and serial pair.

```objective-c
...
[SRC registerWithCustomerName: @"John" name serial: @"GAWRYTUILKJHVBNB..." handler: ^(enum SerialVerdict verdict){ ... }];
```

### Performing validation of a stored serial

Call `-checkForStoredSerialAndValidateIt` to asynchronously validate registration data, stored in User Defaults. This is most probably should be made only once during the application startup.

```objective-c
...
[SRC checkForStoredSerialAndValidateIt];
```

### Wiping out stored registration data

Call `-deauthorizeAccount` to remove registration data from User Defaults and turn an app into the unregistered state.

```objective-c
...
[SRC deauthorizeAccount];
```

## Watchdog Behavior

**Application launches with no customer name and no serial stored in user defaults**  
  → Application silently goes to the unregistered state.

**User clicks "Registration..." menu item at the top of the screen**  
  → Registration window is shown with the appropriate view (serial entry or registration status).

**Application launches with stored customer name and serial and verification shows its incorrect**  
  → Error alert is displayed and application is set to the unregistered state.

**Application is correctly registered but `-deauthorizeAccount` method is called**  
  → Application silently goes to the unregistered state.

**User follows a Quick-Apply link**  
  → If registration data is incorrect error alert is displayed and app stays in unregistered state. If customer name conforms to the serial registration window is displayed with the status view.

**Application is correctly registered but user follows a corrupted Quick-Apply Link**  
  → Application is deauthorized and error alert is displayed.

## Quick-Apply Links

Instead of torturing customers with long serial keys consider using Quick-Apply Links to activate your apps.

Quick-Apply Link consists of the following parts:  
`applicationname-wd://CUSTOMERNAME:SERIAL`

`applicationname` is a non-localized, lowercased name of your app, without any spaces. `CUSTOMERNAME` stands for Base32 encoded customer name and SERIAL is an actual serial (which is itself a Base32 encoded DSA signature of the customer' name).

**HINT**: Consider redirecting customers after successfull purchases to the corresponding Quick-Apply links to make seamless and trouble-free app-activation experiences.

## Serials Blacklists
### Static Blacklist

TODO:!

### Dynamic Blacklist

TODO:!

## Requirements

Watchdog utilizes Base Internationalization technology, thats why its minimum SDK is 10.8.

## Localization

Watchdog' UI is currently localized to English and Russian.

## Important asymmetric cryptography notice

Keep your application' private key in a really safe place and make sure you have a reliable backup. If you lose your private key you no longer be able to generate new serials for your app. If your private key will be compromised, bad, really bad things will happen: anyone will be able to produce valid serials on their own so you most probably will have to change public key, embedded in your app. You have been warned!

## FAQ

This framework is probably not a bullet proof in terms of piracy?

## License

Watchdog is released under the MIT license. See [License.md](https://github.com/konstantinpavlikhin/Watchdog/blob/master/License.md).
