Pod::Spec.new do |spec|
  spec.name                   = 'PeekKit'
  spec.version                = "1.0.0"
  spec.summary                = "Opens a random web page. That is the whole feature."
  spec.description            = <<-DESC
                                  PeekKit picks a page at random and shows it in a web view. It exists so a release pipeline has something small to build, sign and ship.
                                  DESC
  spec.homepage               = "https://example.com"
  spec.license                = "MIT"
  spec.author                 = { "PeekKit" => "peekkit@example.com" }
  spec.source                 = { :git => 'https://github.com/example/test-sdk.git', :tag => spec.version.to_s }
  spec.ios.deployment_target  = '12.0'
  spec.source_files           = 'PeekKit/Classes/**/*'
  spec.swift_version          = '5.0'
  spec.swift_versions         = ['5.0']
end
