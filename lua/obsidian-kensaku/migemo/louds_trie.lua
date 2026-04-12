local utils = require "obsidian-kensaku.migemo.utils"

local LOUDSTrie = {}
LOUDSTrie.__index = LOUDSTrie

--- @param bit_vector table BitVector instance
--- @param edges ffi.cdata* uint16_t array (0-based)
--- @param edges_len number
function LOUDSTrie.new(bit_vector, edges, edges_len)
  local self = setmetatable({}, LOUDSTrie)
  self.bit_vector = bit_vector
  self.edges = edges
  self.edges_len = edges_len
  return self
end

function LOUDSTrie:parent(x)
  return self.bit_vector:rank(self.bit_vector:select(x, true), false)
end

function LOUDSTrie:first_child(x)
  local y = self.bit_vector:select(x, false) + 1
  if self.bit_vector:get(y) then
    return self.bit_vector:rank(y, true) + 1
  else
    return -1
  end
end

function LOUDSTrie:traverse(index, c)
  local fc = self:first_child(index)
  if fc == -1 then
    return -1
  end
  local child_start_bit = self.bit_vector:select(fc, true)
  local child_end_bit = self.bit_vector:next_clear_bit(child_start_bit)
  local child_size = child_end_bit - child_start_bit
  local result = utils.binary_search(self.edges, fc, fc + child_size, c)
  return result >= 0 and result or -1
end

function LOUDSTrie:lookup(key)
  local node_index = 1
  for cp in utils.utf8_iter(key) do
    node_index = self:traverse(node_index, cp)
    if node_index == -1 then
      break
    end
  end
  return node_index >= 0 and node_index or -1
end

function LOUDSTrie:reverse_lookup(index)
  if index <= 0 or index >= self.edges_len then
    error("LOUDSTrie: index out of range: " .. index)
  end
  local chars = {}
  while index > 1 do
    chars[#chars + 1] = self.edges[index]
    index = self:parent(index)
  end
  local result = {}
  for i = #chars, 1, -1 do
    result[#result + 1] = utils.utf8_char(chars[i])
  end
  return table.concat(result)
end

function LOUDSTrie:predictive_search(index)
  local results = {}
  local lower = index
  local upper = index + 1
  while upper - lower > 0 do
    for i = lower, upper - 1 do
      results[#results + 1] = i
    end
    lower = self.bit_vector:rank(self.bit_vector:select(lower, false) + 1, true) + 1
    upper = self.bit_vector:rank(self.bit_vector:select(upper, false) + 1, true) + 1
  end
  return results
end

return LOUDSTrie
