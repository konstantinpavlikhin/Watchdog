Pod::Spec.new do |spec|

  spec.name = 'Watchdog'

  spec.version = '0.1.0'

  spec.author = {'Konstantin Pavlikhin' => 'k.pavlikhin@gmail.com'}

  spec.social_media_url = 'https://twitter.com/kpavlikhin'

  spec.license = {:type => 'MIT', :file => 'License.md'}

  spec.homepage = 'https://github.com/konstantinpavlikhin/Watchdog'

  spec.source = {:git => 'https://github.com/konstantinpavlikhin/Watchdog.git', :tag => "#{spec.version}"}

  spec.summary = 'Simple registration framework for OS X apps. DSA/ECDSA support. No OpenSSL required.'

  spec.platform = :osx, "10.8"

  spec.osx.deployment_target = "10.8"

  spec.requires_arc = true

  spec.frameworks = 'Cocoa', 'Security', 'QuartzCore'

  spec.source_files = "*.{h,m}"

  spec.public_header_files = "Watchdog.h"

  spec.resource_bundles = {'WatchdogResources' => 'Resources/*.{xib,lproj}'}

end
