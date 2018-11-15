Pod::Spec.new do |s|
  s.name             = 'KinCoreSDK'
  s.version          = '0.7.10'
  s.summary          = 'Pod for the KIN Core SDK.'

  s.description      = <<-DESC
  Initial pod for the KIN SDK.
                       DESC

  s.homepage         = 'https://github.com/kinfoundation/kin-core-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author           = { 'Kin Foundation' => 'kin@kik.com' }
  s.source           = { :git => 'https://github.com/kinfoundation/kin-core-ios.git', :tag => "#{s.version}", :submodules => true  }

  s.source_files     = 'KinSDK/KinSDK/source/*.swift',
                       'KinSDK/KinSDK/source/third-party/keychain-swift/KeychainSwift/*.swift',
                       'KinSDK/KinSDK/source/third-party/swift-sodium/Sodium/*.{swift,h}',
                       'KinSDK/KinSDK/source/third-party/swift-sodium/Sodium/libsodium/*.h'

  s.preserve_paths   = 'KinSDK/KinSDK/source/third-party/swift-sodium/Sodium/libsodium/module.modulemap',
                       'KinSDK/KinSDK/source/third-party/swift-sodium/Sodium/libsodium/libsodium-ios.a'

  s.vendored_library      = 'KinSDK/KinSDK/source/third-party/swift-sodium/Sodium/libsodium/libsodium-ios.a'
  s.private_header_files  = 'KinSDK/KinSDK/source/third-party/swift-sodium/Sodium/libsodium/*.h'

  s.pod_target_xcconfig   = {
    'SWIFT_INCLUDE_PATHS' => '$(PODS_TARGET_SRCROOT)/KinSDK/KinSDK/source/third-party/swift-sodium/Sodium/libsodium',
    'OTHER_LDFLAGS' => '-lsodium-ios',
    'LIBRARY_SEARCH_PATHS' => '$(PODS_TARGET_SRCROOT)/KinSDK/KinSDK/source/third-party/swift-sodium/Sodium/libsodium'
  }

  s.dependency 'StellarKit', '0.3.6'

  s.ios.deployment_target = '8.0'
  s.swift_version = "3.2"
  s.platform = :ios, '8.0'
end
