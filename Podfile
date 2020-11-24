# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

inhibit_all_warnings!
install! 'cocoapods', :disable_input_output_paths => true

target 'Protein' do
  use_frameworks!

  pod 'FLEX', :configurations => ['Debug']
  pod 'LookinServer', :configurations => ['Debug']

  # Pods for Protein

  pod 'Bugsnag'

  pod 'WCDB.swift'
#  pod 'HWPanModal'
  pod 'SnapKit'
  pod 'SDWebImage'
  pod 'LTMorphingLabel'

  pod 'DropDown'

  pod 'JGProgressHUD'
#  pod 'ActivityIndicatorView' # Replace should be greate

  pod 'JJFloatingActionButton'

  pod 'Down'
  pod 'Cosmos'
  pod 'FLAnimatedImage'

# pod 'FanMenu' # may be used later in download
# pod 'StepProgressView' # may be used later in tasks https://github.com/yonat/StepProgressView
# pod 'RadioGroup' # may be used later in installed view controller https://github.com/yonat/RadioGroup
# source 'https://github.com/CocoaPods/Specs.git'
# pod 'TVButton', '~> 1.0' # may be used later in home news
# pod "Macaw", "0.9.6" # may be used later in data drawing https://github.com/exyte/Macaw-Examples

  target 'ProteinTests' do
    inherit! :search_paths

  end

  target 'ProteinUITests' do

  end

end

target 'Protein WatchKit App' do
  use_frameworks!
  platform :watchos, '4.0'

	pod 'WCDB'


end

target 'Protein WatchKit Extension' do
  use_frameworks!
  platform :watchos, '4.0'

	pod 'WCDB'

end
