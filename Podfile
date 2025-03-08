platform :ios, '16.0'
use_frameworks!

target 'Hackers' do
  pod 'GoogleMLKit/Translate', '3.2.0'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|

          # Set build settings
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.0'

          # Fix DT_TOOLCHAIN_DIR error
          xcconfig_path = config.base_configuration_reference.real_path
          xcconfig = File.read(xcconfig_path)
          xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
          File.open(xcconfig_path, "w") { |file| file << xcconfig_mod }

        end
    end
end
