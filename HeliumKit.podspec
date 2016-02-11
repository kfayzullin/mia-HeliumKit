Pod::Spec.new do |spec|
  spec.name         = 'HeliumKit'
  spec.version = '1.0.0'
  spec.license      = { :type => 'MIT' }
  spec.homepage     = 'https://github.com/7factory/HeliumKit'
  spec.authors      = { 'CMPS' => 'cmps@sevenventures.de' }
  spec.summary      = 'Swift framework for accessing a miajs backend.'
  spec.source       = { :git => 'git@github.com:7factory/HeliumKit.git', :tag => spec.version.to_s }
  spec.platform     = :ios
  spec.ios.deployment_target = '8.0'
  spec.tvos.deployment_target = '9.0'
  spec.source_files = 'HeliumKit/**/*.swift'
  spec.dependency 'mia-HydrogenKit', '1.0.0'
end

