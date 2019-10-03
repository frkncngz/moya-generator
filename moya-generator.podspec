Pod::Spec.new do |s|
  s.name           = 'moya-generator'
  s.version        = '0.0.1'
  s.summary        = 'A tool to generate Moya Providers'
  s.homepage       = 'https://github.com/frkncngz/moya-generator'
  s.license        = { type: 'MIT', file: 'LICENSE' }
  s.author         = { 'Furkan Cengiz' => 'furkancengiz@gmail.com' }
  s.source         = { http: "#{s.homepage}/releases/download/#{s.version}/moya-generator.zip" }
  s.preserve_paths = '*'
end
