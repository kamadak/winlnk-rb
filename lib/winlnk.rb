#
# Copyright (c) 2014 KAMADA Ken'ichi.
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

# This is a library to parse Windows Shell Link (shortcut or .lnk) files
# on non-Windows systems.
class WinLnk
  MAGIC = "\x4c\x00\x00\x00".b
  CLSID = "\x01\x14\x02\x00\x00\x00\x00\x00\xc0\x00\x00\x00\x00\x00\x00\x46".b

  FLAG_HAS_LINK_TARGET_ID_LIST = 1 << 0
  FLAG_HAS_LINK_INFO = 1 << 1
  FLAG_HAS_NAME = 1 << 2
  FLAG_HAS_RELATIVE_PATH = 1 << 3
  FLAG_HAS_WORKING_DIR = 1 << 4
  FLAG_HAS_ARGUMENTS = 1 << 5
  FLAG_HAS_ICON_LOCATION = 1 << 6
  FLAG_IS_UNICODE = 1 << 7

  ATTR_READONLY = 1 << 0
  ATTR_HIDDEN = 1 << 1
  ATTR_SYSTEM = 1 << 2
  ATTR_DIRECTORY = 1 << 4
  ATTR_ARCHIVE = 1 << 5
  ATTR_NORMAL = 1 << 7
  ATTR_TEMPORARY = 1 << 8
  ATTR_SPARSE_FILE = 1 << 9
  ATTR_REPARSE_POINT = 1 << 10
  ATTR_COMPRESSED = 1 << 11
  ATTR_OFFLINE = 1 << 12
  ATTR_NOT_CONTENT_INDEXED = 1 << 13
  ATTR_ENCRYPTED = 1 << 14

  SW_SHOWNORMAL = 1
  SW_SHOWMAXIMIZED = 3
  SW_SHOWMINNOACTIVE = 7

  LI_FLAG_LOCAL = 1 << 0
  LI_FLAG_NETWORK = 1 << 1

  @@debug = nil

  attr_reader :flags, :path,
    :description, :relative_path, :working_directory,
    :arguments, :icon_location

  def initialize(pathname, codepage)
    @codepage = codepage
    @data = open(pathname, "rb:ASCII-8BIT") { |f| f.read }
    off = read_header()
    printf("Link flags: %b\n", @flags) if @@debug

    if @flags & FLAG_HAS_LINK_TARGET_ID_LIST != 0
      off = read_id_list(off)
    end

    if @flags & FLAG_HAS_LINK_INFO != 0
      off = read_link_info(off)
    end

    if @flags & FLAG_HAS_NAME != 0
      @description, off = read_string(off)
    end
    if @flags & FLAG_HAS_RELATIVE_PATH != 0
      @relative_path, off = read_string(off)
    end
    if @flags & FLAG_HAS_WORKING_DIR != 0
      @working_directory, off = read_string(off)
    end
    if @flags & FLAG_HAS_ARGUMENTS != 0
      @arguments, off = read_string(off)
    end
    if @flags & FLAG_HAS_ICON_LOCATION != 0
      @icon_location, off = read_string(off)
    end

    remove_instance_variable(:@data)
  end

  private

  def read_header()
    raise ParseError.new("Not a shell link file") if data(0x00, 4) != MAGIC
    raise ParseError.new("CLSID mismatch") if data(0x04, 16) != CLSID
    @flags, @attributes = data(0x14, 8).unpack("V2")
    times = data(0x1c, 24).unpack("V6")
    @btime = filetime2posixtime(times[1] << 32 | times[0])
    @atime = filetime2posixtime(times[3] << 32 | times[2])
    @mtime = filetime2posixtime(times[5] << 32 | times[4])
    @file_size, @icon_index, @show_cmd, @hot_key = data(0x34, 16).unpack("V3v")
    reserved = data(0x44, 8).unpack("vV2")
    return 0x4c
  end

  def filetime2posixtime(filetime)
    # Windows FILETIME is the time from 1601-01-01 in 100-nanosecond unit.
    filetime -= 116444736000000000
    return Time.at(filetime / 10000000, filetime % 10000000 / 10)
  end

  def read_id_list(off)
    @id_list = []
    len, = data(off, 2).unpack("v")
    off += 2
    nextoff = off + len
    loop do
      itemlen, = data(off, 2).unpack("v")
      return nextoff if itemlen == 0
      @id_list.push(data(off + 2, itemlen - 2))
      off += itemlen
    end
  end

  def read_link_info(off)
    len, = data(off, 4).unpack("V")
    raise ParseError.new("Too short LinkInfo") if len < 0x1c
    header_len, li_flags, vol_id_off, base_path_off,
      net_rel_link_off, suffix_off = data(off + 4, 24).unpack("V6")
    if @@debug
      printf("LinkInfo header size: %u\n", header_len)
      printf("LinkInfo flags: %b\n", li_flags)
    end

    if li_flags & LI_FLAG_LOCAL != 0
      base_path, = data_all(off + base_path_off).unpack("Z*")
      suffix, = data_all(off + suffix_off).unpack("Z*")
      @path = (base_path + suffix).force_encoding(@codepage)
    end
    if li_flags & LI_FLAG_NETWORK != 0
      # Parse the CommonNetworkRelativeLink structure.
      net_name_off, = data(off + net_rel_link_off + 8, 2).unpack("v")
      net_name, = data_all(off + net_rel_link_off + net_name_off).unpack("Z*")
      suffix, = data_all(off + suffix_off).unpack("Z*")
      @path = (net_name + "\\" + suffix).force_encoding(@codepage)
    end
    return off + len
  end

  def read_string(off)
    len, = data(off, 2).unpack("v")
    if @flags & FLAG_IS_UNICODE != 0
      # UTF-16.
      len *= 2
      return data(off + 2, len).force_encoding("UTF-16LE"), off + len + 2
    else
      # The system default code page.
      return data(off + 2, len).force_encoding(@codepage), off + len + 2
    end
  end

  def data(off, len)
    raise ParseError.new("Truncated file") if @data.size < off + len
    return @data[off, len]
  end

  def data_all(off)
    raise ParseError.new("Truncated file") if @data.size < off
    return @data[off..-1]
  end

  class ParseError < StandardError
  end
end
