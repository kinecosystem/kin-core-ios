Pod::Spec.new do |s|
  s.name             = 'KinCoreSDK'
  s.version          = '0.7.15'
  s.summary          = 'Pod for the KIN Core SDK.'

  s.description      = <<-DESC
  Initial pod for the KIN SDK.
                       DESC

  s.homepage         = 'https://github.com/kinfoundation/kin-core-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author           = { 'Kin Foundation' => 'kin@kik.com' }
  s.source           = { :git => 'https://github.com/kinfoundation/kin-core-ios.git', :tag => "#{s.version}", :submodules => true }

  s.source_files     = 'KinSDK/KinSDK/source/*.swift',
                       'KinSDK/KinSDK/source/third-party/keychain-swift/KeychainSwift/*.swift'

  s.dependency 'StellarKit', '0.3.11'
  s.dependency 'Sodium', '0.7.0'

  s.ios.deployment_target = '8.0'
  s.swift_version = "4.2"
  s.platform = :ios, '8.0'
end
