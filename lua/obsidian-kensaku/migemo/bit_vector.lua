local ffi = require "ffi"
local bit = require "bit"
local utils = require "obsidian-kensaku.migemo.utils"

local BitVector = {}
BitVector.__index = BitVector

--- @param words ffi.cdata* uint32_t array (0-based, paired as 64-bit words)
--- @param size_in_bits number
function BitVector.new(words, size_in_bits)
  local self = setmetatable({}, BitVector)
  local expected_len = bit.rshift(size_in_bits + 63, 6) * 2
  -- Pad with 2 extra words for safe boundary access in rank()
  local padded = ffi.new("uint32_t[?]", expected_len + 2)
  ffi.copy(padded, words, expected_len * ffi.sizeof "uint32_t")
  self.words = padded
  self._words_len = expected_len
  self.size_in_bits = size_in_bits

  local lb_len = bit.rshift(size_in_bits + 511, 9)
  self.lb = ffi.new("uint32_t[?]", lb_len)
  local sb_len = lb_len * 8
  self.sb = ffi.new("uint16_t[?]", sb_len)

  local sum = 0
  local sum_in_lb = 0
  local half_words = bit.rshift(expected_len, 1)
  for i = 0, sb_len - 1 do
    local bc = 0
    if i < half_words then
      bc = utils.bit_count(padded[i * 2]) + utils.bit_count(padded[i * 2 + 1])
    end
    self.sb[i] = sum_in_lb
    sum_in_lb = sum_in_lb + bc
    if bit.band(i, 7) == 7 then
      self.lb[bit.rshift(i, 3)] = sum
      sum = sum + sum_in_lb
      sum_in_lb = 0
    end
  end

  return self
end

function BitVector:rank(pos, b)
  local count1 = self.sb[bit.rshift(pos, 6)] + self.lb[bit.rshift(pos, 9)]
  local pos_in_dword = bit.band(pos, 63)
  if pos_in_dword >= 32 then
    count1 = count1 + utils.bit_count(self.words[bit.band(bit.rshift(pos, 5), 0xFFFFFFFE)])
  end
  local pos_in_word = bit.band(pos, 31)
  local mask = bit.rshift(0x7FFFFFFF, 31 - pos_in_word)
  count1 = count1 + utils.bit_count(bit.band(self.words[bit.rshift(pos, 5)], mask))
  if b then
    return count1
  else
    return pos - count1
  end
end

function BitVector:select(count, b)
  local lb_index = self:_lower_bound_lb(count, b) - 1
  if lb_index == -1 then
    return 0
  end
  local count_in_lb
  if b then
    count_in_lb = count - self.lb[lb_index]
  else
    count_in_lb = count - (512 * lb_index - self.lb[lb_index])
  end
  local sb_index = self:_lower_bound_sb(count_in_lb, lb_index * 8, lb_index * 8 + 8, b) - 1
  local count_in_sb
  if b then
    count_in_sb = count_in_lb - self.sb[sb_index]
  else
    count_in_sb = count_in_lb - (64 * bit.band(sb_index, 7) - self.sb[sb_index])
  end
  local word_l = self.words[sb_index * 2]
  local word_u = self.words[sb_index * 2 + 1]
  if not b then
    word_l = bit.bnot(word_l)
    word_u = bit.bnot(word_u)
  end
  local lower_bc = utils.bit_count(word_l)
  local i = 0
  if count_in_sb > lower_bc then
    word_l = word_u
    count_in_sb = count_in_sb - lower_bc
    i = 32
  end
  while count_in_sb > 0 do
    count_in_sb = count_in_sb - bit.band(word_l, 1)
    word_l = bit.rshift(word_l, 1)
    i = i + 1
  end
  return sb_index * 64 + (i - 1)
end

function BitVector:_lower_bound_lb(key, b)
  local lb_len = bit.rshift(self.size_in_bits + 511, 9)
  local high = lb_len
  local low = -1
  if b then
    while high - low > 1 do
      local mid = bit.rshift(high + low, 1)
      if self.lb[mid] < key then
        low = mid
      else
        high = mid
      end
    end
  else
    while high - low > 1 do
      local mid = bit.rshift(high + low, 1)
      if 512 * mid - self.lb[mid] < key then
        low = mid
      else
        high = mid
      end
    end
  end
  return high
end

function BitVector:_lower_bound_sb(key, from_index, to_index, b)
  local high = to_index
  local low = from_index - 1
  if b then
    while high - low > 1 do
      local mid = bit.rshift(high + low, 1)
      if self.sb[mid] < key then
        low = mid
      else
        high = mid
      end
    end
  else
    while high - low > 1 do
      local mid = bit.rshift(high + low, 1)
      if 64 * bit.band(mid, 7) - self.sb[mid] < key then
        low = mid
      else
        high = mid
      end
    end
  end
  return high
end

function BitVector:next_clear_bit(from_index)
  local u = bit.rshift(from_index, 5)
  local word = bit.band(bit.bnot(self.words[u]), bit.lshift(-1, from_index))
  while true do
    if word ~= 0 then
      return u * 32 + utils.number_of_trailing_zeros(word)
    end
    u = u + 1
    if u == self._words_len then
      return -1
    end
    word = bit.bnot(self.words[u])
  end
end

function BitVector:get(pos)
  return bit.band(bit.rshift(self.words[bit.rshift(pos, 5)], bit.band(pos, 31)), 1) == 1
end

function BitVector:size()
  return self.size_in_bits
end

return BitVector
