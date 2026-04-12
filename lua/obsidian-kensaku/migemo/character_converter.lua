local utils = require "obsidian-kensaku.migemo.utils"

local M = {}

-- Half-width → Full-width mapping (by code point)
local han2zen_map = {}
-- Full-width → Half-width mapping (by code point)
local zen2han_map = {}

local function add(h, z)
  local hcp = utils.to_codepoints(h)
  local zcp = utils.to_codepoints(z)
  han2zen_map[hcp[1]] = z
  -- zen2han is keyed by first codepoint of the full-width char
  zen2han_map[zcp[1]] = h
end

-- ASCII half/full pairs
local ascii_pairs = {
  { "!", "\239\188\129" }, -- ！
  { '"', "\226\128\157" }, -- "
  { "#", "\239\188\131" }, -- ＃
  { "$", "\239\188\132" }, -- ＄
  { "%", "\239\188\133" }, -- ％
  { "&", "\239\188\134" }, -- ＆
  { "'", "\226\128\152" }, -- '
  { "(", "\239\188\136" }, -- （
  { ")", "\239\188\137" }, -- ）
  { "*", "\239\188\138" }, -- ＊
  { "+", "\239\188\139" }, -- ＋
  { ",", "\239\188\140" }, -- ，
  { "-", "\239\188\141" }, -- －
  { ".", "\239\188\142" }, -- ．
  { "/", "\239\188\143" }, -- ／
}
for i = 0, 9 do
  ascii_pairs[#ascii_pairs + 1] = { string.char(0x30 + i), utils.utf8_char(0xFF10 + i) }
end
local more_ascii = {
  { ":", "\239\188\154" }, -- ：
  { ";", "\239\188\155" }, -- ；
  { "<", "\239\188\156" }, -- ＜
  { "=", "\239\188\157" }, -- ＝
  { ">", "\239\188\158" }, -- ＞
  { "?", "\239\188\159" }, -- ？
  { "@", "\239\188\160" }, -- ＠
}
for _, p in ipairs(more_ascii) do
  ascii_pairs[#ascii_pairs + 1] = p
end
for i = 0, 25 do
  ascii_pairs[#ascii_pairs + 1] = { string.char(0x41 + i), utils.utf8_char(0xFF21 + i) } -- A-Z
end
local bracket_ascii = {
  { "[", "\239\188\187" }, -- ［
  { "\\", "\239\191\165" }, -- ￥
  { "]", "\239\188\189" }, -- ］
  { "^", "\239\188\190" }, -- ＾
  { "_", "\239\188\191" }, -- ＿
  { "`", "\226\128\152" }, -- '
}
for _, p in ipairs(bracket_ascii) do
  ascii_pairs[#ascii_pairs + 1] = p
end
for i = 0, 25 do
  ascii_pairs[#ascii_pairs + 1] = { string.char(0x61 + i), utils.utf8_char(0xFF41 + i) } -- a-z
end
local final_ascii = {
  { "{", "\239\189\155" }, -- ｛
  { "|", "\239\189\156" }, -- ｜
  { "}", "\239\189\157" }, -- ｝
  { "~", "\239\189\158" }, -- ～
}
for _, p in ipairs(final_ascii) do
  ascii_pairs[#ascii_pairs + 1] = p
end

-- Half-width katakana → Full-width katakana
local kana_pairs = {
  { "\239\189\161", "\227\128\130" }, -- ｡ → 。
  { "\239\189\162", "\227\128\140" }, -- ｢ → 「
  { "\239\189\163", "\227\128\141" }, -- ｣ → 」
  { "\239\189\164", "\227\128\129" }, -- ､ → 、
  { "\239\189\165", "\227\131\187" }, -- ･ → ・
  { "\239\189\166", "\227\131\178" }, -- ｦ → ヲ
  { "\239\189\167", "\227\130\161" }, -- ｧ → ァ
  { "\239\189\168", "\227\130\163" }, -- ｨ → ィ
  { "\239\189\169", "\227\130\165" }, -- ｩ → ゥ
  { "\239\189\170", "\227\130\167" }, -- ｪ → ェ
  { "\239\189\171", "\227\130\169" }, -- ｫ → ォ
  { "\239\189\172", "\227\131\163" }, -- ｬ → ャ
  { "\239\189\173", "\227\131\165" }, -- ｭ → ュ
  { "\239\189\174", "\227\131\167" }, -- ｮ → ョ
  { "\239\189\175", "\227\131\131" }, -- ｯ → ッ
  { "\239\189\176", "\227\131\188" }, -- ｰ → ー
}
-- ｱ(FF71) → ア(30A2), ..., ﾝ(FF9D) → ン(30F3)
for i = 0, 44 do
  kana_pairs[#kana_pairs + 1] = { utils.utf8_char(0xFF71 + i), utils.utf8_char(0x30A2 + i * 2) }
end
-- Corrections for katakana that don't follow the *2 pattern
-- Actually the simple +i*2 doesn't work for all. Let me use the accurate mapping.
-- Reset and do it properly with individual entries.
-- Remove the last 45 entries
for _ = 1, 45 do
  kana_pairs[#kana_pairs] = nil
end
-- Manually map half-width katakana (FF71-FF9D) to full-width
local hw_to_fw_kata = {
  [0xFF71] = 0x30A2, -- ｱ→ア
  [0xFF72] = 0x30A4, -- ｲ→イ
  [0xFF73] = 0x30A6, -- ｳ→ウ
  [0xFF74] = 0x30A8, -- ｴ→エ
  [0xFF75] = 0x30AA, -- ｵ→オ
  [0xFF76] = 0x30AB, -- ｶ→カ
  [0xFF77] = 0x30AD, -- ｷ→キ
  [0xFF78] = 0x30AF, -- ｸ→ク
  [0xFF79] = 0x30B1, -- ｹ→ケ
  [0xFF7A] = 0x30B3, -- ｺ→コ
  [0xFF7B] = 0x30B5, -- ｻ→サ
  [0xFF7C] = 0x30B7, -- ｼ→シ
  [0xFF7D] = 0x30B9, -- ｽ→ス
  [0xFF7E] = 0x30BB, -- ｾ→セ
  [0xFF7F] = 0x30BD, -- ｿ→ソ
  [0xFF80] = 0x30BF, -- ﾀ→タ
  [0xFF81] = 0x30C1, -- ﾁ→チ
  [0xFF82] = 0x30C4, -- ﾂ→ツ
  [0xFF83] = 0x30C6, -- ﾃ→テ
  [0xFF84] = 0x30C8, -- ﾄ→ト
  [0xFF85] = 0x30CA, -- ﾅ→ナ
  [0xFF86] = 0x30CB, -- ﾆ→ニ
  [0xFF87] = 0x30CC, -- ﾇ→ヌ
  [0xFF88] = 0x30CD, -- ﾈ→ネ
  [0xFF89] = 0x30CE, -- ﾉ→ノ
  [0xFF8A] = 0x30CF, -- ﾊ→ハ
  [0xFF8B] = 0x30D2, -- ﾋ→ヒ
  [0xFF8C] = 0x30D5, -- ﾌ→フ
  [0xFF8D] = 0x30D8, -- ﾍ→ヘ
  [0xFF8E] = 0x30DB, -- ﾎ→ホ
  [0xFF8F] = 0x30DE, -- ﾏ→マ
  [0xFF90] = 0x30DF, -- ﾐ→ミ
  [0xFF91] = 0x30E0, -- ﾑ→ム
  [0xFF92] = 0x30E1, -- ﾒ→メ
  [0xFF93] = 0x30E2, -- ﾓ→モ
  [0xFF94] = 0x30E4, -- ﾔ→ヤ
  [0xFF95] = 0x30E6, -- ﾕ→ユ
  [0xFF96] = 0x30E8, -- ﾖ→ヨ
  [0xFF97] = 0x30E9, -- ﾗ→ラ
  [0xFF98] = 0x30EA, -- ﾘ→リ
  [0xFF99] = 0x30EB, -- ﾙ→ル
  [0xFF9A] = 0x30EC, -- ﾚ→レ
  [0xFF9B] = 0x30ED, -- ﾛ→ロ
  [0xFF9C] = 0x30EF, -- ﾜ→ワ
  [0xFF9D] = 0x30F3, -- ﾝ→ン
}
for hw, fw in pairs(hw_to_fw_kata) do
  kana_pairs[#kana_pairs + 1] = { utils.utf8_char(hw), utils.utf8_char(fw) }
end
-- Dakuten/handakuten entries
kana_pairs[#kana_pairs + 1] = { "\239\190\158", "\227\130\155" } -- ﾞ → ゛
kana_pairs[#kana_pairs + 1] = { "\239\190\159", "\227\130\156" } -- ﾟ → ゜

-- Build han2zen map
for _, pair in ipairs(ascii_pairs) do
  add(pair[1], pair[2])
end
for _, pair in ipairs(kana_pairs) do
  add(pair[1], pair[2])
end

-- Additional zen2han entries for dakuten katakana
local dakuten_zen2han = {
  { 0x30F4, "\239\189\179\239\190\158" }, -- ヴ → ｳﾞ
  { 0x30AC, "\239\189\182\239\190\158" }, -- ガ → ｶﾞ
  { 0x30AE, "\239\189\183\239\190\158" }, -- ギ → ｷﾞ
  { 0x30B0, "\239\189\184\239\190\158" }, -- グ → ｸﾞ
  { 0x30B2, "\239\189\185\239\190\158" }, -- ゲ → ｹﾞ
  { 0x30B4, "\239\189\186\239\190\158" }, -- ゴ → ｺﾞ
  { 0x30B6, "\239\189\187\239\190\158" }, -- ザ → ｻﾞ
  { 0x30B8, "\239\189\188\239\190\158" }, -- ジ → ｼﾞ
  { 0x30BA, "\239\189\189\239\190\158" }, -- ズ → ｽﾞ
  { 0x30BC, "\239\189\190\239\190\158" }, -- ゼ → ｾﾞ
  { 0x30BE, "\239\189\191\239\190\158" }, -- ゾ → ｿﾞ
  { 0x30C0, "\239\190\128\239\190\158" }, -- ダ → ﾀﾞ
  { 0x30C2, "\239\190\129\239\190\158" }, -- ヂ → ﾁﾞ
  { 0x30C5, "\239\190\130\239\190\158" }, -- ヅ → ﾂﾞ
  { 0x30C7, "\239\190\131\239\190\158" }, -- デ → ﾃﾞ
  { 0x30C9, "\239\190\132\239\190\158" }, -- ド → ﾄﾞ
  { 0x30D0, "\239\190\138\239\190\158" }, -- バ → ﾊﾞ
  { 0x30D3, "\239\190\139\239\190\158" }, -- ビ → ﾋﾞ
  { 0x30D6, "\239\190\140\239\190\158" }, -- ブ → ﾌﾞ
  { 0x30D9, "\239\190\141\239\190\158" }, -- ベ → ﾍﾞ
  { 0x30DC, "\239\190\142\239\190\158" }, -- ボ → ﾎﾞ
  { 0x30D1, "\239\190\138\239\190\159" }, -- パ → ﾊﾟ
  { 0x30D4, "\239\190\139\239\190\159" }, -- ピ → ﾋﾟ
  { 0x30D7, "\239\190\140\239\190\159" }, -- プ → ﾌﾟ
  { 0x30DA, "\239\190\141\239\190\159" }, -- ペ → ﾍﾟ
  { 0x30DD, "\239\190\142\239\190\159" }, -- ポ → ﾎﾟ
}
for _, entry in ipairs(dakuten_zen2han) do
  zen2han_map[entry[1]] = entry[2]
end

function M.han2zen(source)
  local result = {}
  for cp in utils.utf8_iter(source) do
    local replacement = han2zen_map[cp]
    if replacement then
      result[#result + 1] = replacement
    else
      result[#result + 1] = utils.utf8_char(cp)
    end
  end
  return table.concat(result)
end

function M.zen2han(source)
  local result = {}
  for cp in utils.utf8_iter(source) do
    local replacement = zen2han_map[cp]
    if replacement then
      result[#result + 1] = replacement
    else
      result[#result + 1] = utils.utf8_char(cp)
    end
  end
  return table.concat(result)
end

--- Convert hiragana to katakana. Non-hiragana characters are passed through.
function M.hira2kata(source)
  local result = {}
  for cp in utils.utf8_iter(source) do
    if cp >= 0x3041 and cp <= 0x3096 then
      result[#result + 1] = utils.utf8_char(cp - 0x3041 + 0x30A1)
    else
      result[#result + 1] = utils.utf8_char(cp)
    end
  end
  return table.concat(result)
end

return M
