local bit = require "bit"

local M = {}

--- Binary search in an array-like structure.
--- Works with both 0-based ffi arrays and 1-based Lua tables.
--- @param a any Array-like with bracket indexing
--- @param from_index number Start index (inclusive)
--- @param to_index number End index (exclusive)
--- @param key number Value to search for
--- @return number Index if found, or -(insertion_point + 1) if not
function M.binary_search(a, from_index, to_index, key)
  local low = from_index
  local high = to_index - 1
  while low <= high do
    local mid = bit.rshift(low + high, 1)
    local mid_val = a[mid]
    if mid_val < key then
      low = mid + 1
    elseif mid_val > key then
      high = mid - 1
    else
      return mid
    end
  end
  return -(low + 1)
end

--- Count the number of set bits in a 32-bit integer (popcount).
function M.bit_count(i)
  i = i - bit.band(bit.rshift(i, 1), 0x55555555)
  i = bit.band(i, 0x33333333) + bit.band(bit.rshift(i, 2), 0x33333333)
  i = bit.band(i + bit.rshift(i, 4), 0x0f0f0f0f)
  i = i + bit.rshift(i, 8)
  i = i + bit.rshift(i, 16)
  return bit.band(i, 0x3f)
end

--- Count the number of trailing zero bits in a 32-bit integer.
function M.number_of_trailing_zeros(i)
  if i == 0 then
    return 32
  end
  local n = 0
  if bit.band(i, 0x0000FFFF) == 0 then
    n = n + 16
    i = bit.rshift(i, 16)
  end
  if bit.band(i, 0x000000FF) == 0 then
    n = n + 8
    i = bit.rshift(i, 8)
  end
  if bit.band(i, 0x0000000F) == 0 then
    n = n + 4
    i = bit.rshift(i, 4)
  end
  if bit.band(i, 0x00000003) == 0 then
    n = n + 2
    i = bit.rshift(i, 2)
  end
  if bit.band(i, 0x00000001) == 0 then
    n = n + 1
  end
  return n
end

--- Iterate over Unicode code points in a UTF-8 string.
--- @param s string
--- @return fun(): number|nil code point iterator
function M.utf8_iter(s)
  local i = 1
  return function()
    if i > #s then
      return nil
    end
    local b = s:byte(i)
    local cp, len
    if b < 0x80 then
      cp, len = b, 1
    elseif b < 0xE0 then
      cp = bit.band(b, 0x1F)
      len = 2
    elseif b < 0xF0 then
      cp = bit.band(b, 0x0F)
      len = 3
    else
      cp = bit.band(b, 0x07)
      len = 4
    end
    for j = 2, len do
      cp = bit.bor(bit.lshift(cp, 6), bit.band(s:byte(i + j - 1), 0x3F))
    end
    i = i + len
    return cp
  end
end

--- Convert a Unicode code point to a UTF-8 string.
--- @param cp number
--- @return string
function M.utf8_char(cp)
  if cp < 0x80 then
    return string.char(cp)
  elseif cp < 0x800 then
    return string.char(bit.bor(0xC0, bit.rshift(cp, 6)), bit.bor(0x80, bit.band(cp, 0x3F)))
  elseif cp < 0x10000 then
    return string.char(
      bit.bor(0xE0, bit.rshift(cp, 12)),
      bit.bor(0x80, bit.band(bit.rshift(cp, 6), 0x3F)),
      bit.bor(0x80, bit.band(cp, 0x3F))
    )
  else
    return string.char(
      bit.bor(0xF0, bit.rshift(cp, 18)),
      bit.bor(0x80, bit.band(bit.rshift(cp, 12), 0x3F)),
      bit.bor(0x80, bit.band(bit.rshift(cp, 6), 0x3F)),
      bit.bor(0x80, bit.band(cp, 0x3F))
    )
  end
end

--- Convert a UTF-8 string to an array of code points (1-based).
--- @param s string
--- @return number[]
function M.to_codepoints(s)
  local result = {}
  for cp in M.utf8_iter(s) do
    result[#result + 1] = cp
  end
  return result
end

--- Read a big-endian uint32 from a binary string at 0-based byte offset.
function M.read_u32(data, offset)
  local b1, b2, b3, b4 = data:byte(offset + 1, offset + 4)
  return b1 * 0x1000000 + b2 * 0x10000 + b3 * 0x100 + b4
end

--- Read a big-endian int32 from a binary string at 0-based byte offset.
function M.read_i32(data, offset)
  local v = M.read_u32(data, offset)
  if v >= 0x80000000 then
    return v - 0x100000000
  end
  return v
end

--- Read a big-endian uint16 from a binary string at 0-based byte offset.
function M.read_u16(data, offset)
  local b1, b2 = data:byte(offset + 1, offset + 2)
  return b1 * 0x100 + b2
end

--- Read a uint8 from a binary string at 0-based byte offset.
function M.read_u8(data, offset)
  return data:byte(offset + 1)
end

return M
