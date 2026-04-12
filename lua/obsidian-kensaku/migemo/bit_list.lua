local ffi = require "ffi"
local bit = require "bit"

local BitList = {}
BitList.__index = BitList

function BitList.new(size)
  local self = setmetatable({}, BitList)
  self.words = ffi.new("uint32_t[?]", bit.rshift(size + 31, 5))
  self._size = size
  return self
end

function BitList:get(pos)
  return bit.band(bit.rshift(self.words[bit.rshift(pos, 5)], bit.band(pos, 31)), 1) == 1
end

function BitList:set(pos, value)
  local idx = bit.rshift(pos, 5)
  local mask = bit.lshift(1, bit.band(pos, 31))
  if value then
    self.words[idx] = bit.bor(self.words[idx], mask)
  else
    self.words[idx] = bit.band(self.words[idx], bit.bnot(mask))
  end
end

return BitList
