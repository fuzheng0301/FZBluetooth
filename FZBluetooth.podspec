
Pod::Spec.new do |s|

  s.name         = "FZBluetooth"
  s.version      = "1.0.0"
  s.summary      = "Apple native Bluetooth method encapsulation."
  s.homepage     = "https://github.com/fuzheng0301/FZBluetooth"
  s.license      = "MIT"
  s.author             = { "fuzheng" => "13683568645@163.com" }
  s.source       = { :git => "http://EXAMPLE/FZBluetooth.git", :tag => s.version.to_s }
  s.platform     = :ios, "8.0"
  s.source_files  = "FZHBluetooth", "FZBluetoothExample/FzBluetoothDemo/FZHBluetooth/**/*.{h,m}"
  s.frameworks = "Foundation", "UIKit", "CoreBluetooth"

end
