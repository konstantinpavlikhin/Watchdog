Pod::Spec.new do |spec|

  spec.name = 'Watchdog'

  spec.version = '0.0.0'

  spec.cocoapods_version = '>= 0.36'

  spec.authors = {'Konstantin Pavlikhin' => 'k.pavlikhin@gmail.com'}

  spec.social_media_url = 'https://twitter.com/kpavlikhin'

  spec.license = {:type => 'MIT', :file => 'LICENSE.md'}

  spec.homepage = 'https://github.com/konstantinpavlikhin/Watchdog'

  spec.source = {:git => 'https://github.com/konstantinpavlikhin/Watchdog.git', :tag => "v#{spec.version}"}

  spec.summary = 'Simple registration framework for OS X apps. DSA/ECDSA support. No OpenSSL required.'

  spec.platform = :osx, '10.11'

  spec.osx.deployment_target = '10.8'

  spec.requires_arc = true

  spec.frameworks = 'Cocoa', 'Foundation', 'AppKit', 'Security', 'QuartzCore'

  spec.module_name = 'Watchdog'

  spec.source_files = 'Sources/*.{h,m}'

  spec.public_header_files = 'Sources/*.h'

  spec.private_header_files = 'Sources/*+Private.h'

  spec.resources = 'Resources/*'

  spec.exclude_files = 'Resources/Watchdog-Info.plist'

end
