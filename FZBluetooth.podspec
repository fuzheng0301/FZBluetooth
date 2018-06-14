
Pod::Spec.new do |s|

  s.name         = "FZBluetooth"
  s.version      = "1.0.2"
  s.summary      = "FZBluetooth is An extension based on system Bluetooth method development."
  s.description  = <<-DESC
An extension based on the system Bluetooth library, including Bluetooth basic functions such as lookup, connection, writing, and response. It is more convenient and lightweight to use after encapsulation.
                   DESC
  s.homepage     = "https://github.com/fuzheng0301/FZBluetooth"
  s.license      = "MIT"
  s.author             = { "fuzheng" => "13683568645@163.com" }
  s.platform     = :ios, "8.0"
  s.source       = { :git => "https://github.com/fuzheng0301/FZBluetooth.git", :tag => "#{s.version}" }
  s.frameworks = "UIKit", "CoreBluetooth", "Foundation"
  s.source_files  = "FZHBluetooth", "FZBluetoothExample/FzBluetoothDemo/FZHBluetooth/**/*.{h,m}"


end
