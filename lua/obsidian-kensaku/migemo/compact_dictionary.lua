local ffi = require "ffi"
local bit = require "bit"
local utils = require "obsidian-kensaku.migemo.utils"
local BitVector = require "obsidian-kensaku.migemo.bit_vector"
local BitList = require "obsidian-kensaku.migemo.bit_list"
local LOUDSTrie = require "obsidian-kensaku.migemo.louds_trie"
local hiragana = require "obsidian-kensaku.migemo.compact_hiragana_string"

local CompactDictionary = {}
CompactDictionary.__index = CompactDictionary

--- Load a compact dictionary from a binary file.
--- @param path string Path to the migemo-compact-dict file
--- @return table CompactDictionary instance
function CompactDictionary.load(path)
  local f = io.open(path, "rb")
  if not f then
    error("CompactDictionary: cannot open file: " .. path)
  end
  local data = f:read "*a"
  f:close()
  return CompactDictionary.new(data)
end

--- Construct a compact dictionary from binary data.
--- @param data string Binary data
function CompactDictionary.new(data)
  local self = setmetatable({}, CompactDictionary)
  local offset = 0

  self.key_trie, offset = CompactDictionary._read_trie(data, offset, true)
  self.value_trie, offset = CompactDictionary._read_trie(data, offset, false)

  -- mapping bit vector
  local mbv_size = utils.read_u32(data, offset)
  offset = offset + 4
  local mbv_num_words = bit.rshift(mbv_size + 63, 6) * 2
  local mbv_words = ffi.new("uint32_t[?]", mbv_num_words)
  for i = 0, bit.rshift(mbv_num_words, 1) - 1 do
    mbv_words[i * 2 + 1] = utils.read_u32(data, offset)
    offset = offset + 4
    mbv_words[i * 2] = utils.read_u32(data, offset)
    offset = offset + 4
  end
  self.mapping_bv = BitVector.new(mbv_words, mbv_size)

  -- mapping array
  local mapping_size = utils.read_u32(data, offset)
  offset = offset + 4
  self.mapping = ffi.new("int32_t[?]", mapping_size)
  for i = 0, mapping_size - 1 do
    self.mapping[i] = utils.read_i32(data, offset)
    offset = offset + 4
  end

  if offset ~= #data then
    error("CompactDictionary: unexpected trailing data (offset=" .. offset .. ", size=" .. #data .. ")")
  end

  self.has_mapping = CompactDictionary._create_has_mapping(self.mapping_bv)
  return self
end

function CompactDictionary._read_trie(data, offset, compact_hiragana_flag)
  local edge_size = utils.read_i32(data, offset)
  offset = offset + 4
  local edges = ffi.new("uint16_t[?]", edge_size)
  for i = 0, edge_size - 1 do
    local c
    if compact_hiragana_flag then
      c = hiragana.decode_byte(utils.read_u8(data, offset))
      offset = offset + 1
    else
      c = utils.read_u16(data, offset)
      offset = offset + 2
    end
    edges[i] = c
  end

  local bv_size = utils.read_u32(data, offset)
  offset = offset + 4
  local num_words = bit.rshift(bv_size + 63, 6) * 2
  local bv_words = ffi.new("uint32_t[?]", num_words)
  for i = 0, bit.rshift(num_words, 1) - 1 do
    bv_words[i * 2 + 1] = utils.read_u32(data, offset)
    offset = offset + 4
    bv_words[i * 2] = utils.read_u32(data, offset)
    offset = offset + 4
  end

  local trie = LOUDSTrie.new(BitVector.new(bv_words, bv_size), edges, edge_size)
  return trie, offset
end

function CompactDictionary._create_has_mapping(mapping_bv)
  local num_nodes = mapping_bv:rank(mapping_bv:size() + 1, false)
  local bl = BitList.new(num_nodes)
  local bit_pos = 0
  for node = 1, num_nodes - 1 do
    bl:set(node, mapping_bv:get(bit_pos + 1))
    bit_pos = mapping_bv:next_clear_bit(bit_pos + 1)
  end
  return bl
end

--- Exact search: returns all dictionary values for the given key.
function CompactDictionary:search(key)
  local results = {}
  local key_index = self.key_trie:lookup(key)
  if key_index ~= -1 and self.has_mapping:get(key_index) then
    local vs = self.mapping_bv:select(key_index, false)
    local ve = self.mapping_bv:next_clear_bit(vs + 1)
    local size = ve - vs - 1
    if size > 0 then
      local off = self.mapping_bv:rank(vs, false)
      for i = 0, size - 1 do
        results[#results + 1] = self.value_trie:reverse_lookup(self.mapping[vs - off + i])
      end
    end
  end
  return results
end

--- Predictive search: returns all dictionary values for keys that start with the given prefix.
function CompactDictionary:predictive_search(key)
  local results = {}
  local key_index = self.key_trie:lookup(key)
  if key_index > 1 then
    local nodes = self.key_trie:predictive_search(key_index)
    for _, i in ipairs(nodes) do
      if self.has_mapping:get(i) then
        local vs = self.mapping_bv:select(i, false)
        local ve = self.mapping_bv:next_clear_bit(vs + 1)
        local size = ve - vs - 1
        local off = self.mapping_bv:rank(vs, false)
        for j = 0, size - 1 do
          results[#results + 1] = self.value_trie:reverse_lookup(self.mapping[vs - off + j])
        end
      end
    end
  end
  return results
end

return CompactDictionary
