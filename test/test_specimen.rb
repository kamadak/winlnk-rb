#
# Copyright (c) 2019 KAMADA Ken'ichi.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#

require "test/unit"
require "winlnk"

class TestSpecimen < Test::Unit::TestCase
  def test_local_cmd
    lnk = WinLnk.new("test/local_cmd.lnk", "Windows-31J")

    assert_equal('C:\Windows\System32\cmd with space.exe', lnk.path)
    assert_equal('This is a comment.', lnk.description)
    assert_equal('..\Windows\System32\cmd with space.exe', lnk.relative_path)
    assert_equal('C:\Windows\System32', lnk.working_directory)
    assert_equal('arg1 "arg 2"', lnk.arguments)
    assert_equal(nil, lnk.icon_location)

    assert_equal(0x2020, lnk.attributes)
    assert_equal(Time.utc(2019,  7,  1, 14, 00, 40, 918391), lnk.btime)
    assert_equal(Time.utc(2019,  7,  1, 14, 00, 40, 918391), lnk.atime)
    assert_equal(Time.utc(2014, 10, 29,  1, 28, 18, 835387), lnk.mtime)
    assert_equal(357376, lnk.file_size)
    assert_equal(0, lnk.icon_index)
    assert_equal(WinLnk::SW_SHOWNORMAL, lnk.show_cmd)
    assert_equal(0, lnk.hot_key)
  end

  def test_local_win31j
    lnk = WinLnk.new("test/local_win31j.lnk", "Windows-31J")

    # Default code page
    assert_equal('C:\Temp\リンク先.txt'.encode("Windows-31J"), lnk.path)
    # UTF-8
    assert_equal('コメント', lnk.description)
    assert_equal('.\リンク先.txt', lnk.relative_path)
    assert_equal('C:\Temp', lnk.working_directory)
    assert_equal(nil, lnk.arguments)
    assert_equal('%SystemRoot%\system32\SHELL32.dll', lnk.icon_location)

    assert_equal(0x2020, lnk.attributes)
    assert_equal(Time.utc(2019,  6, 30, 13, 51, 53, 537221), lnk.btime)
    assert_equal(Time.utc(2019,  6, 30, 13, 51, 53, 537221), lnk.atime)
    assert_equal(Time.utc(2019,  6, 30, 13, 52,  1, 861622), lnk.mtime)
    assert_equal(10, lnk.file_size)
    assert_equal(70, lnk.icon_index)
    assert_equal(WinLnk::SW_SHOWNORMAL, lnk.show_cmd)
    assert_equal(0, lnk.hot_key)
  end

  def test_net_win31j
    lnk = WinLnk.new("test/net_win31j.lnk", "Windows-31J")

    # Default code page
    assert_equal('\\\\TEST\SHARE\リンク先.txt'.encode("Windows-31J"), lnk.path)
    # UTF-8
    assert_equal(nil, lnk.description)
    assert_equal(nil, lnk.relative_path)
    assert_equal('\\\\test\share', lnk.working_directory)
    assert_equal(nil, lnk.arguments)
    assert_equal(nil, lnk.icon_location)

    assert_equal(0x80, lnk.attributes)
    assert_equal(Time.utc(2019,  7,  8, 14,  4, 50,  25776), lnk.btime)
    assert_equal(Time.utc(2019,  7,  8, 14,  5, 30, 183680), lnk.atime)
    assert_equal(Time.utc(2019,  7,  8, 14,  4, 50,  25776), lnk.mtime)
    assert_equal(10, lnk.file_size)
    assert_equal(0, lnk.icon_index)
    assert_equal(WinLnk::SW_SHOWNORMAL, lnk.show_cmd)
    assert_equal(0, lnk.hot_key)
  end
end
