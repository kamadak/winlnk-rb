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

class TestInternal < Test::Unit::TestCase
  def test_filetime2posixtime
    # A dummy file.
    lnk = WinLnk.new("test/local_cmd.lnk", "US-ASCII")
    assert_equal(Time.utc(1970, 1, 1, 0, 0, 0),
                 lnk.send(:filetime2posixtime, 116444736000000000))
    assert_equal(Time.utc(1970, 1, 1, 0, 0, 0),
                 lnk.send(:filetime2posixtime, 116444736000000009))
    assert_equal(Time.utc(1970, 1, 1, 0, 0, 0, 1),
                 lnk.send(:filetime2posixtime, 116444736000000010))
    assert_equal(Time.utc(1970, 1, 1, 0, 0, 0, 999999),
                 lnk.send(:filetime2posixtime, 116444736009999990))
    assert_equal(Time.utc(1970, 1, 1, 0, 0, 0, 999999),
                 lnk.send(:filetime2posixtime, 116444736009999999))
    assert_equal(Time.utc(1970, 1, 1, 0, 0, 1),
                 lnk.send(:filetime2posixtime, 116444736010000000))
    assert_equal(Time.utc(2014, 6, 21, 4, 36, 55),
                 lnk.send(:filetime2posixtime, 130477990150000000))
  end

  def test_asciz
    lnk = WinLnk.new("test/local_cmd.lnk", "US-ASCII")
    asciz = ->(data, off) do
      lnk.instance_variable_set(:@data, data)
      return lnk.send(:asciz, off)
    end

    assert_equal("abc", asciz.call("abc\0def\0".b, 0))
    assert_equal("bc", asciz.call("abc\0def\0".b, 1))
    assert_equal("", asciz.call("abc\0def\0".b, 3))
    assert_equal("def", asciz.call("abc\0def\0".b, 4))
    assert_equal("", asciz.call("abc\0def\0".b, 7))
    assert_raise(WinLnk::ParseError) { asciz.call("abc\0def\0".b, 8) }
    assert_raise(WinLnk::ParseError) { asciz.call("".b, 1) }
    assert_raise(WinLnk::ParseError) { asciz.call("abc".b, 0) }
  end

  def test_utf16z
    lnk = WinLnk.new("test/local_cmd.lnk", "US-ASCII")
    utf16z = ->(data, off) do
      lnk.instance_variable_set(:@data, data)
      return lnk.send(:utf16z, off)
    end

    assert_equal("ab", utf16z.call("a\0b\0\0\0c\0d\0\0\0".b, 0))
    assert_equal("ab", utf16z.call("\0a\0b\0\0\0c\0d\0\0\0".b, 1))
    assert_equal("cd", utf16z.call("a\0b\0\0\0c\0d\0\0\0".b, 6))
    assert_equal("abc\0\0def".encode("UTF-8", "UTF-16LE"),
                 utf16z.call("abc\0\0def\0\0".b, 0))
    assert_equal("", utf16z.call("\0\0".b, 0))
    assert_equal("a", utf16z.call("\n\0a\0\0\0".b, 2))
    assert_raise(WinLnk::ParseError) { utf16z.call("\0", 0) }
    assert_raise(WinLnk::ParseError) { utf16z.call("", 0) }
    assert_raise(WinLnk::ParseError) { utf16z.call("", 1) }
  end
end
