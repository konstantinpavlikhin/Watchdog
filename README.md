# Watchdog

Watchdog is a simple registration framework for OS X apps.

## Watchdog features
* Drop-in component for application registration. Watchdog has clear API, trivial to install to your project.
* No heavyweight dependancies — framework doesn't rely on ugly OpenSSL library and uses modern Security.framework APIs.
* Watchdog utilizes robust and secure industry standart DSA/ECDSA signature algorithms.
* Watchdog seamlessly supports both DSA and ECDSA serials — just set an appropriate public key.

## What Watchdog is not

Watchdog has nothing to do with with trial periods or evaluation launches count. It's up to you to implement an appropriate `TrialController` with behavior specific to your domain. There are numerous ways you can implement a trial. For example, some applications allow limited time of an unrestricted app usage, some allow limited number of launches in trial mode, some just restrict feature set and so on... There is no possibility (an need) to abstract this stuff into Watchdog.

## Adding Watchdog to your project

1. Add Watchdog to your project as a submodule.
  ```
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
<key>WDGBuyOnlineURL</key>
<string>http://applicationapp.com/order</string>

<!-- The URL of the registration support page. -->
<key>WDGSupportURL</key>
<string>http://applicationapp.com/support/register</string>

<!-- The URL of the serial key validation script. -->
<key>WDGServerCheckURL</key>
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

### `WDGRegistrationController` Singleton

At the launch time of your app (`-applicationDidFinishLaunching:`) request the `WDGRegistrationController` singleton instance and set its properies.

```objective-c
WDGRegistrationController* SRC = [WDGRegistrationController sharedRegistrationController];
```

Set the `publicKeyPEM` property to your application' DSA/ECDSA public key:
```objective-c
...
SRC.publicKeyPEM = @"-----BEGIN PUBLIC KEY-----\n ... -----END PUBLIC KEY-----";
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
[SRC addObserver: self forKeyPath: @"applicationState" options: NSKeyValueObservingOptionInitial context: NULL];
```

### Registering an app with concrete customer name & serial

Call `-registerWithCustomerName:serial:handler:` to asynchronously register application with concrete name and serial pair.

```objective-c
...
[SRC registerWithCustomerName: @"John" name serial: @"GAWRYTUILKJHVBNB..." handler: ^(WDGSerialVerdict verdict){ ... }];
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

`applicationname` is a non-localized, lowercased name of your app, without any spaces. `CUSTOMERNAME` stands for Base32 encoded customer name and SERIAL is an actual serial (which is itself a Base32 encoded DSA/ECDSA signature of the customer' name).

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

## Generating Keys

Choose an appropriate key length to keep a good ballance between security and length of a resulting serial.

### Example Serials

**Customer Name**:  
John Appleseed

**1024 bit DSA serial**:  
GAWAEFA46ZQC6LB32U4S4OAPKMAY3DQP5FHSLEYCCQFTP4ZLD7EM5IJTQUX7NZVPLVXN7WYH3M

**2048 bit DSA serial**:  
GAXAEFIAX2ZAZRGNXXBACEX4IIHEHSHSM66NUTVMAIKQB4UXRWTDMGV6L7RHCUYITVQYGKB5FS5S4

Compared to currently prevalent cryptosystems such as RSA and DSA, ECDSA offers equivalent security with smaller key sizes.

**192 bit ECDSA serial (comparable to 1024 bit DSA)**:  
GA2QEGAYX46LAYMZQSAFRCFWHC4FU73OLVH3HKKK3LM4GAQZADZNC3PVNFQIXA5EUZE5NJMTHDOIDH2YOTQGMSO2

**384 bit ECDSA serial (comparable to 7680 bit DSA)**:  
GBSQEMIA5K734JXT4ZEECT3MKTYD5MCYWZOXRZJ646R2AWYPN4ZXCFYZWNIHX4336BE5VFTY7VR4VVDQK2KNUARQMS3S3NAUNGPUIQ536RBVJOQUC2SQBIGLVC5LQKV3VCX7D6WTKNCKE3NMGMBCS4CC5DGMBOD6UMS4Q

TODO: citation needed.

### DSA Keys

Generate a DSA private key:  
`$ openssl dsaparam -genkey 2048 -noout -out DSAPrivateKey.pem`

Check components of the generated private key:  
`$ openssl dsa -in DSAPrivateKey.pem -text -noout`

Extract public key from the private key:  
`$ openssl dsa -in DSAPrivateKey.pem -pubout -outform PEM -out DSAPublicKey.pem`

### ECDSA Keys

List all available curves:  
`$ openssl ecparam -list_curves`

Generate an ECDSA private key:  
`$ openssl ecparam -genkey -name secp521r1 -noout -out ECDSAPrivateKey.pem`

Check components of the generated private key:  
`$ openssl ec -in ECDSAPrivateKey.pem -text -noout`

Extract public key from the private key:  
`$ openssl ec -in ECDSAPrivateKey.pem -pubout -outform PEM -out ECDSAPublicKey.pem`

## Important asymmetric cryptography notice

Keep your application' private key in a really safe place and make sure you have a reliable backup. If you lose your private key you no longer be able to generate new serials for your app. If your private key will be compromised, bad, really bad things will happen: anyone will be able to produce valid serials on their own so you most probably will have to change public key, embedded in your app. You have been warned!

## Sandboxing

If you adding Watchdog to a sandboxed app you should put the following lines in your `ApplicationName.entitlements`:

```xml
<key>com.apple.security.network.client</key>
<true/>
```

## FAQ

- **Q: How bulletproof Watchdog is?**

    A: Objective-C by its nature is very dynamic and reflective. Rich metadata is preserved after compilation: class hierarchies, method signatures, strings, NIBs and so on... Tools like [class-dump](https://github.com/nygard/class-dump) and [Hopper](http://www.hopperapp.com) allow to teardown your application to the atomic building blocks and even reconstruct it in pseudocode. There is no way to hide or protect your algorithms from an educated computer engineer.

- **Q: If Objective-C is so dynamic, why use it at all in a registration framework?**

    A: Let's face the facts. Everybody loves simple high-level Cocoaesque-APIs that are no brainer. Even if you implement your registration handling code in a pure Assembler, smartasses torrenting you lovely app is just a matter of time (less) and demand (more). Every DRM system will be broken (think of iOS Jailbreak, numerous keygens, appname[k] torrents and so on...). We just have to keep honest people honest, without treating them like criminals and turning their app activation experience into hell.

## License

Watchdog is released under the MIT license. See [LICENSE.md](https://github.com/konstantinpavlikhin/Watchdog/blob/master/LICENSE.md).
