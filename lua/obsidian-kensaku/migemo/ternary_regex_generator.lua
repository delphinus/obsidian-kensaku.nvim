local BitList = require "obsidian-kensaku.migemo.bit_list"
local utils = require "obsidian-kensaku.migemo.utils"

local TernaryRegexGenerator = {}
TernaryRegexGenerator.__index = TernaryRegexGenerator

--- @param rxop table {or, begin_group, end_group, begin_class, end_class, newline, escape}
function TernaryRegexGenerator.new(rxop)
  local self = setmetatable({}, TernaryRegexGenerator)
  self.or_op = rxop[1]
  self.begin_group = rxop[2]
  self.end_group = rxop[3]
  self.begin_class = rxop[4]
  self.end_class = rxop[5]
  self.newline = rxop[6]
  self.escape_chars = TernaryRegexGenerator._init_escape(rxop[7])
  self.root = nil
  return self
end

function TernaryRegexGenerator._init_escape(escape)
  local bits = BitList.new(128)
  for i = 1, #escape do
    local c = escape:byte(i)
    if c < 128 then
      bits:set(c, true)
    end
  end
  return bits
end

-- AA-tree operations

local function skew(t)
  if t == nil or t.left == nil then
    return t
  end
  if t.left.level == t.level then
    local l = t.left
    t.left = l.right
    l.right = t
    return l
  end
  return t
end

local function split(t)
  if t == nil or t.right == nil or t.right.right == nil then
    return t
  end
  if t.level == t.right.right.level then
    local r = t.right
    t.right = r.left
    r.left = t
    r.level = r.level + 1
    return r
  end
  return t
end

local function insert_node(x, t)
  if t == nil then
    local r = { value = x, child = nil, left = nil, right = nil, level = 1 }
    return r, r, true
  end
  local r, inserted
  if x < t.value then
    t.left, r, inserted = insert_node(x, t.left)
  elseif x > t.value then
    t.right, r, inserted = insert_node(x, t.right)
  else
    return t, t, false
  end
  t = skew(t)
  t = split(t)
  return t, r, inserted
end

local function add_to_tree(node, codepoints, offset)
  if offset <= #codepoints then
    local new_node, target, inserted = insert_node(codepoints[offset], node)
    if inserted or target.child ~= nil then
      target.child = add_to_tree(target.child, codepoints, offset + 1)
    end
    return new_node
  else
    return nil
  end
end

local function traverse_siblings(node, results)
  if node ~= nil then
    traverse_siblings(node.left, results)
    results[#results + 1] = node
    traverse_siblings(node.right, results)
  end
end

--- Add a word to the generator.
function TernaryRegexGenerator:add(word)
  if #word == 0 then
    return
  end
  local cps = utils.to_codepoints(word)
  self.root = add_to_tree(self.root, cps, 1)
end

function TernaryRegexGenerator:_escape_char(value)
  if value < 128 and self.escape_chars:get(value) then
    return "\\" .. utils.utf8_char(value)
  end
  return utils.utf8_char(value)
end

function TernaryRegexGenerator:generate_stub(node)
  local siblings = {}
  traverse_siblings(node, siblings)
  local brother = #siblings
  local haschild = 0
  for _, n in ipairs(siblings) do
    if n.child ~= nil then
      haschild = haschild + 1
    end
  end
  local nochild = brother - haschild

  local parts = {}

  if brother > 1 and haschild > 0 then
    parts[#parts + 1] = self.begin_group
  end

  if nochild > 0 then
    if nochild > 1 then
      parts[#parts + 1] = self.begin_class
    end
    for _, n in ipairs(siblings) do
      if n.child == nil then
        parts[#parts + 1] = self:_escape_char(n.value)
      end
    end
    if nochild > 1 then
      parts[#parts + 1] = self.end_class
    end
  end

  if haschild > 0 then
    if nochild > 0 then
      parts[#parts + 1] = self.or_op
    end
    local child_parts = {}
    for _, n in ipairs(siblings) do
      if n.child ~= nil then
        local cp = { self:_escape_char(n.value) }
        if self.newline and #self.newline > 0 then
          cp[#cp + 1] = self.newline
        end
        cp[#cp + 1] = self:generate_stub(n.child)
        child_parts[#child_parts + 1] = table.concat(cp)
      end
    end
    parts[#parts + 1] = table.concat(child_parts, self.or_op)
  end

  if brother > 1 and haschild > 0 then
    parts[#parts + 1] = self.end_group
  end

  return table.concat(parts)
end

function TernaryRegexGenerator:generate()
  if self.root == nil then
    return ""
  end
  return self:generate_stub(self.root)
end

return TernaryRegexGenerator
