local bit = require "bit"
local utils = require "obsidian-kensaku.migemo.utils"

local RomajiProcessor = {}
RomajiProcessor.__index = RomajiProcessor

--- @class RomajiPredictiveResult
--- @field prefix string
--- @field suffixes string[]

-- Roman entry: {roman, hiragana, remain, index}
-- index is a 32-bit key computed by packing up to 4 ASCII bytes.

local function calculate_index(roman, start, end_pos)
  local result = 0
  for i = 0, 3 do
    local idx = i + start
    local c = (idx < #roman and idx < end_pos) and roman:byte(idx + 1) or 0
    result = bit.bor(result, c)
    if i < 3 then
      result = bit.lshift(result, 8)
    end
  end
  return result
end

local function make_entry(roman, hira, remain)
  return { roman = roman, hiragana = hira, remain = remain, index = calculate_index(roman, 0, 4) }
end

-- stylua: ignore start
local ROMAN_ENTRIES = {
  make_entry("-", "\227\131\188", 0),     -- ー
  make_entry("~", "\227\128\156", 0),     -- 〜
  make_entry(".", "\227\128\130", 0),     -- 。
  make_entry(",", "\227\128\129", 0),     -- 、
  make_entry("z/", "\227\131\187", 0),    -- ・
  make_entry("z.", "\226\128\166", 0),    -- …
  make_entry("z,", "\226\128\165", 0),    -- ‥
  make_entry("zh", "\226\134\144", 0),    -- ←
  make_entry("zj", "\226\134\147", 0),    -- ↓
  make_entry("zk", "\226\134\145", 0),    -- ↑
  make_entry("zl", "\226\134\146", 0),    -- →
  make_entry("z-", "\227\128\156", 0),    -- 〜
  make_entry("z[", "\227\128\142", 0),    -- 『
  make_entry("z]", "\227\128\143", 0),    -- 』
  make_entry("[", "\227\128\140", 0),     -- 「
  make_entry("]", "\227\128\141", 0),     -- 」
  make_entry("va", "\227\130\148\227\129\129", 0),   -- ゔぁ
  make_entry("vi", "\227\130\148\227\129\131", 0),   -- ゔぃ
  make_entry("vu", "\227\130\148", 0),               -- ゔ
  make_entry("ve", "\227\130\148\227\129\135", 0),   -- ゔぇ
  make_entry("vo", "\227\130\148\227\129\137", 0),   -- ゔぉ
  make_entry("vya", "\227\130\148\227\130\131", 0),  -- ゔゃ
  make_entry("vyi", "\227\130\148\227\129\131", 0),  -- ゔぃ
  make_entry("vyu", "\227\130\148\227\130\133", 0),  -- ゔゅ
  make_entry("vye", "\227\130\148\227\129\135", 0),  -- ゔぇ
  make_entry("vyo", "\227\130\148\227\130\135", 0),  -- ゔょ
  make_entry("qq", "\227\129\163", 1),    -- っ
  make_entry("vv", "\227\129\163", 1),    -- っ
  make_entry("ll", "\227\129\163", 1),    -- っ
  make_entry("xx", "\227\129\163", 1),    -- っ
  make_entry("kk", "\227\129\163", 1),    -- っ
  make_entry("gg", "\227\129\163", 1),    -- っ
  make_entry("ss", "\227\129\163", 1),    -- っ
  make_entry("zz", "\227\129\163", 1),    -- っ
  make_entry("jj", "\227\129\163", 1),    -- っ
  make_entry("tt", "\227\129\163", 1),    -- っ
  make_entry("dd", "\227\129\163", 1),    -- っ
  make_entry("hh", "\227\129\163", 1),    -- っ
  make_entry("ff", "\227\129\163", 1),    -- っ
  make_entry("bb", "\227\129\163", 1),    -- っ
  make_entry("pp", "\227\129\163", 1),    -- っ
  make_entry("mm", "\227\129\163", 1),    -- っ
  make_entry("yy", "\227\129\163", 1),    -- っ
  make_entry("rr", "\227\129\163", 1),    -- っ
  make_entry("ww", "\227\129\163", 1),    -- っ
  make_entry("www", "w", 2),
  make_entry("cc", "\227\129\163", 1),    -- っ
  make_entry("kya", "\227\129\141\227\130\131", 0),  -- きゃ
  make_entry("kyi", "\227\129\141\227\129\131", 0),  -- きぃ
  make_entry("kyu", "\227\129\141\227\130\133", 0),  -- きゅ
  make_entry("kye", "\227\129\141\227\129\135", 0),  -- きぇ
  make_entry("kyo", "\227\129\141\227\130\135", 0),  -- きょ
  make_entry("gya", "\227\129\142\227\130\131", 0),  -- ぎゃ
  make_entry("gyi", "\227\129\142\227\129\131", 0),  -- ぎぃ
  make_entry("gyu", "\227\129\142\227\130\133", 0),  -- ぎゅ
  make_entry("gye", "\227\129\142\227\129\135", 0),  -- ぎぇ
  make_entry("gyo", "\227\129\142\227\130\135", 0),  -- ぎょ
  make_entry("sya", "\227\129\151\227\130\131", 0),  -- しゃ
  make_entry("syi", "\227\129\151\227\129\131", 0),  -- しぃ
  make_entry("syu", "\227\129\151\227\130\133", 0),  -- しゅ
  make_entry("sye", "\227\129\151\227\129\135", 0),  -- しぇ
  make_entry("syo", "\227\129\151\227\130\135", 0),  -- しょ
  make_entry("sha", "\227\129\151\227\130\131", 0),  -- しゃ
  make_entry("shi", "\227\129\151", 0),              -- し
  make_entry("shu", "\227\129\151\227\130\133", 0),  -- しゅ
  make_entry("she", "\227\129\151\227\129\135", 0),  -- しぇ
  make_entry("sho", "\227\129\151\227\130\135", 0),  -- しょ
  make_entry("zya", "\227\129\152\227\130\131", 0),  -- じゃ
  make_entry("zyi", "\227\129\152\227\129\131", 0),  -- じぃ
  make_entry("zyu", "\227\129\152\227\130\133", 0),  -- じゅ
  make_entry("zye", "\227\129\152\227\129\135", 0),  -- じぇ
  make_entry("zyo", "\227\129\152\227\130\135", 0),  -- じょ
  make_entry("tya", "\227\129\161\227\130\131", 0),  -- ちゃ
  make_entry("tyi", "\227\129\161\227\129\131", 0),  -- ちぃ
  make_entry("tyu", "\227\129\161\227\130\133", 0),  -- ちゅ
  make_entry("tye", "\227\129\161\227\129\135", 0),  -- ちぇ
  make_entry("tyo", "\227\129\161\227\130\135", 0),  -- ちょ
  make_entry("cha", "\227\129\161\227\130\131", 0),  -- ちゃ
  make_entry("chi", "\227\129\161", 0),              -- ち
  make_entry("chu", "\227\129\161\227\130\133", 0),  -- ちゅ
  make_entry("che", "\227\129\161\227\129\135", 0),  -- ちぇ
  make_entry("cho", "\227\129\161\227\130\135", 0),  -- ちょ
  make_entry("cya", "\227\129\161\227\130\131", 0),  -- ちゃ
  make_entry("cyi", "\227\129\161\227\129\131", 0),  -- ちぃ
  make_entry("cyu", "\227\129\161\227\130\133", 0),  -- ちゅ
  make_entry("cye", "\227\129\161\227\129\135", 0),  -- ちぇ
  make_entry("cyo", "\227\129\161\227\130\135", 0),  -- ちょ
  make_entry("dya", "\227\129\162\227\130\131", 0),  -- ぢゃ
  make_entry("dyi", "\227\129\162\227\129\131", 0),  -- ぢぃ
  make_entry("dyu", "\227\129\162\227\130\133", 0),  -- ぢゅ
  make_entry("dye", "\227\129\162\227\129\135", 0),  -- ぢぇ
  make_entry("dyo", "\227\129\162\227\130\135", 0),  -- ぢょ
  make_entry("tsa", "\227\129\164\227\129\129", 0),  -- つぁ
  make_entry("tsi", "\227\129\164\227\129\131", 0),  -- つぃ
  make_entry("tse", "\227\129\164\227\129\135", 0),  -- つぇ
  make_entry("tso", "\227\129\164\227\129\137", 0),  -- つぉ
  make_entry("tha", "\227\129\166\227\130\131", 0),  -- てゃ
  make_entry("thi", "\227\129\166\227\129\131", 0),  -- てぃ
  make_entry("t'i", "\227\129\166\227\129\131", 0),  -- てぃ
  make_entry("thu", "\227\129\166\227\130\133", 0),  -- てゅ
  make_entry("the", "\227\129\166\227\129\135", 0),  -- てぇ
  make_entry("tho", "\227\129\166\227\130\135", 0),  -- てょ
  make_entry("t'yu", "\227\129\166\227\130\133", 0), -- てゅ
  make_entry("dha", "\227\129\167\227\130\131", 0),  -- でゃ
  make_entry("dhi", "\227\129\167\227\129\131", 0),  -- でぃ
  make_entry("d'i", "\227\129\167\227\129\131", 0),  -- でぃ
  make_entry("dhu", "\227\129\167\227\130\133", 0),  -- でゅ
  make_entry("dhe", "\227\129\167\227\129\135", 0),  -- でぇ
  make_entry("dho", "\227\129\167\227\130\135", 0),  -- でょ
  make_entry("d'yu", "\227\129\167\227\130\133", 0), -- でゅ
  make_entry("twa", "\227\129\168\227\129\129", 0),  -- とぁ
  make_entry("twi", "\227\129\168\227\129\131", 0),  -- とぃ
  make_entry("twu", "\227\129\168\227\129\133", 0),  -- とぅ
  make_entry("twe", "\227\129\168\227\129\135", 0),  -- とぇ
  make_entry("two", "\227\129\168\227\129\137", 0),  -- とぉ
  make_entry("t'u", "\227\129\168\227\129\133", 0),  -- とぅ
  make_entry("dwa", "\227\129\169\227\129\129", 0),  -- どぁ
  make_entry("dwi", "\227\129\169\227\129\131", 0),  -- どぃ
  make_entry("dwu", "\227\129\169\227\129\133", 0),  -- どぅ
  make_entry("dwe", "\227\129\169\227\129\135", 0),  -- どぇ
  make_entry("dwo", "\227\129\169\227\129\137", 0),  -- どぉ
  make_entry("d'u", "\227\129\169\227\129\133", 0),  -- どぅ
  make_entry("nya", "\227\129\171\227\130\131", 0),  -- にゃ
  make_entry("nyi", "\227\129\171\227\129\131", 0),  -- にぃ
  make_entry("nyu", "\227\129\171\227\130\133", 0),  -- にゅ
  make_entry("nye", "\227\129\171\227\129\135", 0),  -- にぇ
  make_entry("nyo", "\227\129\171\227\130\135", 0),  -- にょ
  make_entry("hya", "\227\129\178\227\130\131", 0),  -- ひゃ
  make_entry("hyi", "\227\129\178\227\129\131", 0),  -- ひぃ
  make_entry("hyu", "\227\129\178\227\130\133", 0),  -- ひゅ
  make_entry("hye", "\227\129\178\227\129\135", 0),  -- ひぇ
  make_entry("hyo", "\227\129\178\227\130\135", 0),  -- ひょ
  make_entry("bya", "\227\129\179\227\130\131", 0),  -- びゃ
  make_entry("byi", "\227\129\179\227\129\131", 0),  -- びぃ
  make_entry("byu", "\227\129\179\227\130\133", 0),  -- びゅ
  make_entry("bye", "\227\129\179\227\129\135", 0),  -- びぇ
  make_entry("byo", "\227\129\179\227\130\135", 0),  -- びょ
  make_entry("pya", "\227\129\180\227\130\131", 0),  -- ぴゃ
  make_entry("pyi", "\227\129\180\227\129\131", 0),  -- ぴぃ
  make_entry("pyu", "\227\129\180\227\130\133", 0),  -- ぴゅ
  make_entry("pye", "\227\129\180\227\129\135", 0),  -- ぴぇ
  make_entry("pyo", "\227\129\180\227\130\135", 0),  -- ぴょ
  make_entry("fa", "\227\129\181\227\129\129", 0),   -- ふぁ
  make_entry("fi", "\227\129\181\227\129\131", 0),   -- ふぃ
  make_entry("fu", "\227\129\181", 0),               -- ふ
  make_entry("fe", "\227\129\181\227\129\135", 0),   -- ふぇ
  make_entry("fo", "\227\129\181\227\129\137", 0),   -- ふぉ
  make_entry("fya", "\227\129\181\227\130\131", 0),  -- ふゃ
  make_entry("fyu", "\227\129\181\227\130\133", 0),  -- ふゅ
  make_entry("fyo", "\227\129\181\227\130\135", 0),  -- ふょ
  make_entry("hwa", "\227\129\181\227\129\129", 0),  -- ふぁ
  make_entry("hwi", "\227\129\181\227\129\131", 0),  -- ふぃ
  make_entry("hwe", "\227\129\181\227\129\135", 0),  -- ふぇ
  make_entry("hwo", "\227\129\181\227\129\137", 0),  -- ふぉ
  make_entry("hwyu", "\227\129\181\227\130\133", 0), -- ふゅ
  make_entry("mya", "\227\129\191\227\130\131", 0),  -- みゃ
  make_entry("myi", "\227\129\191\227\129\131", 0),  -- みぃ
  make_entry("myu", "\227\129\191\227\130\133", 0),  -- みゅ
  make_entry("mye", "\227\129\191\227\129\135", 0),  -- みぇ
  make_entry("myo", "\227\129\191\227\130\135", 0),  -- みょ
  make_entry("rya", "\227\130\138\227\130\131", 0),  -- りゃ
  make_entry("ryi", "\227\130\138\227\129\131", 0),  -- りぃ
  make_entry("ryu", "\227\130\138\227\130\133", 0),  -- りゅ
  make_entry("rye", "\227\130\138\227\129\135", 0),  -- りぇ
  make_entry("ryo", "\227\130\138\227\130\135", 0),  -- りょ
  make_entry("n'", "\227\130\147", 0),               -- ん
  make_entry("nn", "\227\130\147", 0),               -- ん
  make_entry("n", "\227\130\147", 0),                -- ん
  make_entry("xn", "\227\130\147", 0),               -- ん
  make_entry("a", "\227\129\130", 0),  -- あ
  make_entry("i", "\227\129\132", 0),  -- い
  make_entry("u", "\227\129\134", 0),  -- う
  make_entry("wu", "\227\129\134", 0), -- う
  make_entry("e", "\227\129\136", 0),  -- え
  make_entry("o", "\227\129\138", 0),  -- お
  make_entry("xa", "\227\129\129", 0), -- ぁ
  make_entry("xi", "\227\129\131", 0), -- ぃ
  make_entry("xu", "\227\129\133", 0), -- ぅ
  make_entry("xe", "\227\129\135", 0), -- ぇ
  make_entry("xo", "\227\129\137", 0), -- ぉ
  make_entry("la", "\227\129\129", 0), -- ぁ
  make_entry("li", "\227\129\131", 0), -- ぃ
  make_entry("lu", "\227\129\133", 0), -- ぅ
  make_entry("le", "\227\129\135", 0), -- ぇ
  make_entry("lo", "\227\129\137", 0), -- ぉ
  make_entry("lyi", "\227\129\131", 0), -- ぃ
  make_entry("xyi", "\227\129\131", 0), -- ぃ
  make_entry("lye", "\227\129\135", 0), -- ぇ
  make_entry("xye", "\227\129\135", 0), -- ぇ
  make_entry("ye", "\227\129\132\227\129\135", 0), -- いぇ
  make_entry("ka", "\227\129\139", 0), -- か
  make_entry("ki", "\227\129\141", 0), -- き
  make_entry("ku", "\227\129\143", 0), -- く
  make_entry("ke", "\227\129\145", 0), -- け
  make_entry("ko", "\227\129\147", 0), -- こ
  make_entry("xka", "\227\131\181", 0), -- ヵ
  make_entry("xke", "\227\131\182", 0), -- ヶ
  make_entry("lka", "\227\131\181", 0), -- ヵ
  make_entry("lke", "\227\131\182", 0), -- ヶ
  make_entry("ga", "\227\129\140", 0), -- が
  make_entry("gi", "\227\129\142", 0), -- ぎ
  make_entry("gu", "\227\129\144", 0), -- ぐ
  make_entry("ge", "\227\129\146", 0), -- げ
  make_entry("go", "\227\129\148", 0), -- ご
  make_entry("sa", "\227\129\149", 0), -- さ
  make_entry("si", "\227\129\151", 0), -- し
  make_entry("su", "\227\129\153", 0), -- す
  make_entry("se", "\227\129\155", 0), -- せ
  make_entry("so", "\227\129\157", 0), -- そ
  make_entry("ca", "\227\129\139", 0), -- か
  make_entry("ci", "\227\129\151", 0), -- し
  make_entry("cu", "\227\129\143", 0), -- く
  make_entry("ce", "\227\129\155", 0), -- せ
  make_entry("co", "\227\129\147", 0), -- こ
  make_entry("qa", "\227\129\143\227\129\129", 0), -- くぁ
  make_entry("qi", "\227\129\143\227\129\131", 0), -- くぃ
  make_entry("qu", "\227\129\143", 0),             -- く
  make_entry("qe", "\227\129\143\227\129\135", 0), -- くぇ
  make_entry("qo", "\227\129\143\227\129\137", 0), -- くぉ
  make_entry("kwa", "\227\129\143\227\129\129", 0), -- くぁ
  make_entry("kwi", "\227\129\143\227\129\131", 0), -- くぃ
  make_entry("kwu", "\227\129\143\227\129\133", 0), -- くぅ
  make_entry("kwe", "\227\129\143\227\129\135", 0), -- くぇ
  make_entry("kwo", "\227\129\143\227\129\137", 0), -- くぉ
  make_entry("gwa", "\227\129\144\227\129\129", 0), -- ぐぁ
  make_entry("gwi", "\227\129\144\227\129\131", 0), -- ぐぃ
  make_entry("gwu", "\227\129\144\227\129\133", 0), -- ぐぅ
  make_entry("gwe", "\227\129\144\227\129\135", 0), -- ぐぇ
  make_entry("gwo", "\227\129\144\227\129\137", 0), -- ぐぉ
  make_entry("za", "\227\129\150", 0), -- ざ
  make_entry("zi", "\227\129\152", 0), -- じ
  make_entry("zu", "\227\129\154", 0), -- ず
  make_entry("ze", "\227\129\156", 0), -- ぜ
  make_entry("zo", "\227\129\158", 0), -- ぞ
  make_entry("ja", "\227\129\152\227\130\131", 0), -- じゃ
  make_entry("ji", "\227\129\152", 0),             -- じ
  make_entry("ju", "\227\129\152\227\130\133", 0), -- じゅ
  make_entry("je", "\227\129\152\227\129\135", 0), -- じぇ
  make_entry("jo", "\227\129\152\227\130\135", 0), -- じょ
  make_entry("jya", "\227\129\152\227\130\131", 0), -- じゃ
  make_entry("jyi", "\227\129\152\227\129\131", 0), -- じぃ
  make_entry("jyu", "\227\129\152\227\130\133", 0), -- じゅ
  make_entry("jye", "\227\129\152\227\129\135", 0), -- じぇ
  make_entry("jyo", "\227\129\152\227\130\135", 0), -- じょ
  make_entry("ta", "\227\129\159", 0), -- た
  make_entry("ti", "\227\129\161", 0), -- ち
  make_entry("tu", "\227\129\164", 0), -- つ
  make_entry("tsu", "\227\129\164", 0), -- つ
  make_entry("te", "\227\129\166", 0), -- て
  make_entry("to", "\227\129\168", 0), -- と
  make_entry("da", "\227\129\160", 0), -- だ
  make_entry("di", "\227\129\162", 0), -- ぢ
  make_entry("du", "\227\129\165", 0), -- づ
  make_entry("de", "\227\129\167", 0), -- で
  make_entry("do", "\227\129\169", 0), -- ど
  make_entry("xtu", "\227\129\163", 0), -- っ
  make_entry("xtsu", "\227\129\163", 0), -- っ
  make_entry("ltu", "\227\129\163", 0), -- っ
  make_entry("ltsu", "\227\129\163", 0), -- っ
  make_entry("na", "\227\129\170", 0), -- な
  make_entry("ni", "\227\129\171", 0), -- に
  make_entry("nu", "\227\129\172", 0), -- ぬ
  make_entry("ne", "\227\129\173", 0), -- ね
  make_entry("no", "\227\129\174", 0), -- の
  make_entry("ha", "\227\129\175", 0), -- は
  make_entry("hi", "\227\129\178", 0), -- ひ
  make_entry("hu", "\227\129\181", 0), -- ふ
  make_entry("he", "\227\129\184", 0), -- へ
  make_entry("ho", "\227\129\187", 0), -- ほ
  make_entry("ba", "\227\129\176", 0), -- ば
  make_entry("bi", "\227\129\179", 0), -- び
  make_entry("bu", "\227\129\182", 0), -- ぶ
  make_entry("be", "\227\129\185", 0), -- べ
  make_entry("bo", "\227\129\188", 0), -- ぼ
  make_entry("pa", "\227\129\177", 0), -- ぱ
  make_entry("pi", "\227\129\180", 0), -- ぴ
  make_entry("pu", "\227\129\183", 0), -- ぷ
  make_entry("pe", "\227\129\186", 0), -- ぺ
  make_entry("po", "\227\129\189", 0), -- ぽ
  make_entry("ma", "\227\129\190", 0), -- ま
  make_entry("mi", "\227\129\191", 0), -- み
  make_entry("mu", "\227\130\128", 0), -- む
  make_entry("me", "\227\130\129", 0), -- め
  make_entry("mo", "\227\130\130", 0), -- も
  make_entry("xya", "\227\130\131", 0), -- ゃ
  make_entry("lya", "\227\130\131", 0), -- ゃ
  make_entry("ya", "\227\130\132", 0), -- や
  make_entry("wyi", "\227\130\144", 0), -- ゐ
  make_entry("xyu", "\227\130\133", 0), -- ゅ
  make_entry("lyu", "\227\130\133", 0), -- ゅ
  make_entry("yu", "\227\130\134", 0), -- ゆ
  make_entry("wye", "\227\130\145", 0), -- ゑ
  make_entry("xyo", "\227\130\135", 0), -- ょ
  make_entry("lyo", "\227\130\135", 0), -- ょ
  make_entry("yo", "\227\130\136", 0), -- よ
  make_entry("ra", "\227\130\137", 0), -- ら
  make_entry("ri", "\227\130\138", 0), -- り
  make_entry("ru", "\227\130\139", 0), -- る
  make_entry("re", "\227\130\140", 0), -- れ
  make_entry("ro", "\227\130\141", 0), -- ろ
  make_entry("xwa", "\227\130\142", 0), -- ゎ
  make_entry("lwa", "\227\130\142", 0), -- ゎ
  make_entry("wa", "\227\130\143", 0), -- わ
  make_entry("wi", "\227\129\134\227\129\131", 0), -- うぃ
  make_entry("we", "\227\129\134\227\129\135", 0), -- うぇ
  make_entry("wo", "\227\130\146", 0), -- を
  make_entry("wha", "\227\129\134\227\129\129", 0), -- うぁ
  make_entry("whi", "\227\129\134\227\129\131", 0), -- うぃ
  make_entry("whu", "\227\129\134", 0),             -- う
  make_entry("whe", "\227\129\134\227\129\135", 0), -- うぇ
  make_entry("who", "\227\129\134\227\129\137", 0), -- うぉ
}
-- stylua: ignore end

-- Sort entries by index
table.sort(ROMAN_ENTRIES, function(a, b)
  return a.index < b.index
end)

function RomajiProcessor.new(entries)
  local self = setmetatable({}, RomajiProcessor)
  table.sort(entries, function(a, b)
    return a.index < b.index
  end)
  self.entries = entries
  self.indexes = {}
  for i, e in ipairs(entries) do
    self.indexes[i] = e.index
  end
  return self
end

function RomajiProcessor.build()
  local entries = {}
  for _, e in ipairs(ROMAN_ENTRIES) do
    entries[#entries + 1] = { roman = e.roman, hiragana = e.hiragana, remain = e.remain, index = e.index }
  end
  return RomajiProcessor.new(entries)
end

function RomajiProcessor:find_predictively(roman, offset)
  local last_found = -1
  local start_idx = 1
  local end_idx = #self.indexes + 1
  for i = 0, 3 do
    if #roman <= offset + i then
      break
    end
    local start_key = calculate_index(roman, offset, offset + i + 1)
    start_idx = utils.binary_search(self.indexes, start_idx, end_idx, start_key)
    if start_idx >= 0 then
      last_found = start_idx
    else
      start_idx = -start_idx - 1
    end
    local end_key = start_key + bit.lshift(1, 24 - 8 * i)
    end_idx = utils.binary_search(self.indexes, start_idx, end_idx, end_key)
    if end_idx < 0 then
      end_idx = -end_idx - 1
    end
    if end_idx - start_idx == 1 then
      return { self.entries[start_idx] }
    end
  end
  local result = {}
  for i = start_idx, end_idx - 1 do
    result[#result + 1] = self.entries[i]
  end
  return result
end

function RomajiProcessor:romaji_to_hiragana(romaji)
  if #romaji == 0 then
    return ""
  end
  local hiragana = {}
  local start = 0
  local end_pos = 1
  while start < #romaji do
    local last_found = -1
    local lower = 1
    local upper = #self.indexes + 1
    while upper - lower > 1 and end_pos <= #romaji do
      local lower_key = calculate_index(romaji, start, end_pos)
      lower = utils.binary_search(self.indexes, lower, upper, lower_key)
      if lower >= 0 then
        last_found = lower
      else
        lower = -lower - 1
      end
      local upper_key = lower_key + bit.lshift(1, 32 - 8 * (end_pos - start))
      upper = utils.binary_search(self.indexes, lower, upper, upper_key)
      if upper < 0 then
        upper = -upper - 1
      end
      end_pos = end_pos + 1
    end
    if last_found >= 0 then
      local entry = self.entries[last_found]
      hiragana[#hiragana + 1] = entry.hiragana
      start = start + #entry.roman - entry.remain
      end_pos = start + 1
    else
      hiragana[#hiragana + 1] = romaji:sub(start + 1, start + 1)
      start = start + 1
      end_pos = start + 1
    end
  end
  return table.concat(hiragana)
end

--- @return RomajiPredictiveResult
function RomajiProcessor:romaji_to_hiragana_predictively(romaji)
  if #romaji == 0 then
    return { prefix = "", suffixes = { "" } }
  end
  local hiragana = {}
  local start = 0
  local end_pos = 1
  while start < #romaji do
    local last_found = -1
    local lower = 1
    local upper = #self.indexes + 1
    while upper - lower > 1 and end_pos <= #romaji do
      local lower_key = calculate_index(romaji, start, end_pos)
      lower = utils.binary_search(self.indexes, lower, upper, lower_key)
      if lower >= 0 then
        last_found = lower
      else
        lower = -lower - 1
      end
      local upper_key = lower_key + bit.lshift(1, 32 - 8 * (end_pos - start))
      upper = utils.binary_search(self.indexes, lower, upper, upper_key)
      if upper < 0 then
        upper = -upper - 1
      end
      end_pos = end_pos + 1
    end
    if end_pos > #romaji and upper - lower > 1 then
      local set = {}
      for i = lower, upper - 1 do
        local re = self.entries[i]
        if re.remain > 0 then
          local set2 = self:find_predictively(romaji, end_pos - 1 - re.remain)
          for _, re2 in ipairs(set2) do
            if re2.remain == 0 then
              set[re.hiragana .. re2.hiragana] = true
            end
          end
        else
          set[re.hiragana] = true
        end
      end
      local list = {}
      for k in pairs(set) do
        list[#list + 1] = k
      end
      local prefix = table.concat(hiragana)
      if #list == 1 then
        return { prefix = prefix .. list[1], suffixes = { "" } }
      else
        return { prefix = prefix, suffixes = list }
      end
    end
    if last_found >= 0 then
      local entry = self.entries[last_found]
      hiragana[#hiragana + 1] = entry.hiragana
      start = start + #entry.roman - entry.remain
      end_pos = start + 1
    else
      hiragana[#hiragana + 1] = romaji:sub(start + 1, start + 1)
      start = start + 1
      end_pos = start + 1
    end
  end
  return { prefix = table.concat(hiragana), suffixes = { "" } }
end

return RomajiProcessor
