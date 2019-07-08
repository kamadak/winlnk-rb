Gem::Specification.new do |s|
  s.name = "winlnk"
  s.version = "0.0.1"
  s.authors = ["KAMADA Ken'ichi"]
  s.email = "kamada@nanohz.org"
  s.homepage = "https://github.com/kamadak/winlnk-rb"
  s.licenses = ["BSD-2-Clause"]
  s.summary = "Library to read Windows Shell Link (shortcut or .lnk) files"
  s.description = <<EOS
This is a library to parse Windows Shell Link (shortcut or .lnk) files
on non-Windows systems.
EOS

  s.files = [
    "README",
    "Rakefile",
    "lib/winlnk.rb",
    "test/local_cmd.lnk",
    "test/local_win31j.lnk",
    "test/net_win31j.lnk",
    "test/test_error.rb",
    "test/test_internal.rb",
    "test/test_specimen.rb",
  ]
  s.require_paths = ["lib"]

  s.required_ruby_version = ">= 2.0"
end
