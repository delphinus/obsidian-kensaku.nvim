local CompactDictionary = require "obsidian-kensaku.migemo.compact_dictionary"
local RomajiProcessor = require "obsidian-kensaku.migemo.romaji_processor"
local TernaryRegexGenerator = require "obsidian-kensaku.migemo.ternary_regex_generator"
local cc = require "obsidian-kensaku.migemo.character_converter"

local M = {}

--- rxop format: {or, beginGroup, endGroup, beginClass, endClass, newline, escape}
M.RXOP_VIM = { "\\|", "\\%(", "\\)", "[", "]", "", "\\.[]*~^$" }
M.RXOP_PCRE = { "|", "(?:", ")", "[", "]", "", "\\.[]{}()*+-?^$|" }
M.VIM_PREFIX = "\\m"

local Migemo = {}
Migemo.__index = Migemo

function Migemo.new()
  local self = setmetatable({}, Migemo)
  self.dict = nil
  self.rxop = nil
  self.processor = RomajiProcessor.build()
  return self
end

function Migemo:set_dict(dict)
  self.dict = dict
end

function Migemo:set_rxop(rxop)
  self.rxop = rxop
end

function Migemo:query_a_word(word)
  local generator = TernaryRegexGenerator.new(self.rxop or M.RXOP_PCRE)
  generator:add(word)

  local lower = word:lower()
  if self.dict then
    for _, w in ipairs(self.dict:predictive_search(lower)) do
      generator:add(w)
    end
  end

  generator:add(cc.han2zen(word))
  generator:add(cc.zen2han(word))

  local result = self.processor:romaji_to_hiragana_predictively(lower)
  for _, suffix in ipairs(result.suffixes) do
    local hira = result.prefix .. suffix
    generator:add(hira)
    if self.dict then
      for _, w in ipairs(self.dict:predictive_search(hira)) do
        generator:add(w)
      end
    end
    local kata = cc.hira2kata(hira)
    generator:add(kata)
    generator:add(cc.zen2han(kata))
  end

  return generator:generate()
end

function Migemo:query(word)
  if word == "" then
    return ""
  end
  local words = Migemo.parse_query(word)
  local parts = {}
  for _, w in ipairs(words) do
    parts[#parts + 1] = self:query_a_word(w)
  end
  return table.concat(parts)
end

--- Split a query string into words (handles camelCase and spaces).
function Migemo.parse_query(query)
  local words = {}
  local i = 1
  while i <= #query do
    local c = query:byte(i)
    if c == 0x20 or c == 0x09 or c == 0x0A or c == 0x0D then
      i = i + 1
    elseif c >= 0x41 and c <= 0x5A then
      local j = i + 1
      while j <= #query and query:byte(j) >= 0x41 and query:byte(j) <= 0x5A do
        j = j + 1
      end
      if j > i + 1 then
        words[#words + 1] = query:sub(i, j - 1)
        i = j
      else
        while j <= #query do
          local cj = query:byte(j)
          if (cj >= 0x41 and cj <= 0x5A) or cj == 0x20 or cj == 0x09 or cj == 0x0A or cj == 0x0D then
            break
          end
          j = j + 1
        end
        words[#words + 1] = query:sub(i, j - 1)
        i = j
      end
    else
      local j = i + 1
      while j <= #query do
        local cj = query:byte(j)
        if (cj >= 0x41 and cj <= 0x5A) or cj == 0x20 or cj == 0x09 or cj == 0x0A or cj == 0x0D then
          break
        end
        j = j + 1
      end
      words[#words + 1] = query:sub(i, j - 1)
      i = j
    end
  end
  return words
end

-- Singleton management

local _instance = nil
local _dict_path = nil

--- Get or create the singleton Migemo instance.
--- @param dict_path string|nil Path to migemo-compact-dict. Uses cached instance if path matches.
--- @return table Migemo instance
function M.get(dict_path)
  if _instance and _dict_path == dict_path then
    return _instance
  end
  local migemo = Migemo.new()
  if dict_path then
    migemo:set_dict(CompactDictionary.load(dict_path))
  end
  _instance = migemo
  _dict_path = dict_path
  return migemo
end

--- Query with a specific rxop.
--- @param dict_path string Path to migemo-compact-dict
--- @param word string Input romaji
--- @param rxop table rxop tuple (e.g. M.RXOP_VIM or M.RXOP_PCRE)
--- @return string regex pattern
function M.query(dict_path, word, rxop)
  local migemo = M.get(dict_path)
  migemo:set_rxop(rxop)
  return migemo:query(word)
end

return M
