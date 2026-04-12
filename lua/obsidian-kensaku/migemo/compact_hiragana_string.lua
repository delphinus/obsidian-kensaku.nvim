local M = {}

function M.decode_byte(c)
  if c == 0x00 then
    return 0
  end
  if 0x20 <= c and c <= 0x7e then
    return c
  end
  if 0xa1 <= c and c <= 0xf6 then
    return c + 0x3040 - 0xa0
  end
  if c == 0xf7 then
    return 0x30fc -- ー
  end
  error("CompactHiraganaString: invalid byte: " .. c)
end

return M
