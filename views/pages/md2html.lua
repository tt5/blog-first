local lpeg = require("lpeg")

local upper, gsub, format, length =
  string.upper, string.gsub, string.format, string.len
local concat, insert, unpack = table.concat, table.insert, table.unpack
local P, R, S, V, C, Cg, Cb, Cmt, Cc, Ct, B, Cs, any =
  lpeg.P, lpeg.R, lpeg.S, lpeg.V, lpeg.C, lpeg.Cg, lpeg.Cb,
  lpeg.Cmt, lpeg.Cc, lpeg.Ct, lpeg.B, lpeg.Cs, lpeg.P(1)

-----
-----

local util = {}
function util.err(msg, exit_code)
  io.stderr:write("mymarkdown.lua: " .. msg .. "\n")
  os.exit(exit_code or 1)
end
function util.cache(dir, string, transform, suffix)
  local name = util.pathname(dir, "out" .. suffix)
  local file = io.open(name, "r")
    local file = assert(io.open(name, "w"))
    local result = string -- input
--    result0 = result
--    result1 = "no"
    if transform ~= nil then
      result = transform(result)
--      result1 = result
    end
    assert(file:write(result))
    assert(file:close())
--  return name .. "(  " .. result0 .. " <> " .. result1 .. "  )"
  return name
end
function util.table_copy(t)
  local u = { }
  for k, v in pairs(t) do u[k] = v end
  return setmetatable(u, getmetatable(t))
end
function util.walk(t, f)
  local typ = type(t)
  if typ == "string" then
    f(t)
  elseif typ == "table" then
    local i = 1
    local n
    n = t[i]
    while n do
      util.walk(n, f)
      i = i + 1
      n = t[i]
    end
  elseif typ == "function" then
    local ok, val = pcall(t)
    if ok then
      util.walk(val,f)
    end
  else
    f(tostring(t))
  end
end
function util.flatten(ary)
  local new = {}
  for _,v in ipairs(ary) do
    if type(v) == "table" then
      for _,w in ipairs(util.flatten(v)) do
        new[#new + 1] = w
      end
    else
      new[#new + 1] = v
    end
  end
  return new
end
function util.rope_to_string(rope)
  local buffer = {}
  util.walk(rope, function(x) buffer[#buffer + 1] = x end)
  return concat(buffer)
end
function util.rope_last(rope)
  if #rope == 0 then
    return nil
  else
    local l = rope[#rope]
    if type(l) == "table" then
      return util.rope_last(l)
    else
      return l
    end
  end
end
function util.intersperse(ary, x)
  local new = {}
  local l = #ary
  for i,v in ipairs(ary) do
    local n = #new
    new[n + 1] = v
    if i ~= l then
      new[n + 2] = x
    end
  end
  return new
end
function util.map(ary, f)
  local new = {}
  for i,v in ipairs(ary) do
    new[i] = f(v)
  end
  return new
end
function util.pathname(dir, file)
  if #dir == 0 then
    return file
  else
    return dir .. "/" .. file
  end
end

-----
-----

local M = {}
M.writer = {}
function M.writer.new(options)
  local self = {}

  self.suffix = ".html"

  self.space = " "
  self.eof = [[<!-- END -->]]
  self.linebreak = "<br>"

  function self.plain(s) return {"<p>",s, "</p>"} end

  function self.pack(name)
    return [[-> ]] .. name .. [[]]
  end

  function self.interblocksep(s)
    return {""}
  end

  self.string = function(s) return s end

  function self.emphasis(s)
    return {"<em>",s,"</em>"}
  end
  function self.strong(s)
    return {"<strong>",s,"</strong>"}
  end

  function self.code(s)
    return {"\\markdownRendererCodeSpan{",s,"}"}
  end

  codecount = 1
  function self.fencedCode(i, s)
    s = string.gsub(s, '[\r\n%s]*$', '')
    local name = util.cache(options.cacheDir, s, nil, codecount .. ".verbatim")
    codecount = codecount + 1
    return {"\\markdownRendererInputFencedCode{",name,"}{",i,"}"}
  end

  self.active_headings = {}
  function self.heading(s,level)

    local cmd
    level = level
    if level <= 1 then
      cmd = "h1"
    elseif level == 2 then
      cmd = "\\markdownRendererHeadingTwo"
    elseif level == 3 then
      cmd = "\\markdownRendererHeadingThree"
    elseif level == 4 then
      cmd = "\\markdownRendererHeadingFour"
    elseif level == 5 then
      cmd = "\\markdownRendererHeadingFive"
    elseif level >= 6 then
      cmd = "\\markdownRendererHeadingSix"
    else
      cmd = ""
    end
    return {"<", cmd,">",s,"</", cmd, ">"}
  end

  return self
end

-----
-----

local parsers                  = {}
parsers.at                     = P("@")
parsers.hash                   = P("#")
parsers.asterisk               = P("*")
parsers.doubleasterisks        = P("**")
parsers.backtick               = P("`")
parsers.space                  = P(" ")
parsers.tab                    = P("\t")
parsers.newline                = P("\n")
parsers.tightblocksep          = P("\001")

parsers.digit                  = R("09")
parsers.hexdigit               = R("09","af","AF")
parsers.letter                 = R("AZ","az")
parsers.alphanumeric           = R("AZ","az","09")
parsers.keyword                = parsers.letter * parsers.alphanumeric^0
--parsers.citation_chars         = parsers.alphanumeric + S("#$%&-+<>~/_")
parsers.internal_punctuation   = S(":;,.?")

parsers.fourspaces             = P("    ")

parsers.any                    = P(1)
parsers.fail                   = parsers.any - 1

parsers.spacechar              = S("\t ")
parsers.spacing                = S(" \n\r\t")
parsers.nonspacechar           = parsers.any - parsers.spacing
parsers.optionalspace          = parsers.spacechar^0

--parsers.specialchar            = S("*_`&[]<!\\.@-^")
parsers.specialchar            = S("*`")

parsers.normalchar             = parsers.any - (parsers.specialchar + parsers.spacing + parsers.tightblocksep)
parsers.eof                    = -parsers.any
parsers.nonindentspace         = parsers.space^-3 * - parsers.spacechar
parsers.indent                 = parsers.space^-3 * parsers.tab + parsers.fourspaces
/ ""
parsers.linechar               = P(1 - parsers.newline)

parsers.blankline              = parsers.optionalspace * parsers.newline
/ "\n"
parsers.blanklines             = parsers.blankline^0
parsers.skipblanklines         = (parsers.optionalspace * parsers.newline)^0
parsers.indentedline           = parsers.indent
/""
* C(parsers.linechar^1 * parsers.newline^-1)
parsers.optionallyindentedline = parsers.indent^-1
/""
* C(parsers.linechar^1 * parsers.newline^-1)
parsers.sp                     = parsers.spacing^0
parsers.spnl                   = parsers.optionalspace * (parsers.newline * parsers.optionalspace)^-1
parsers.line                   = parsers.linechar^0 * parsers.newline
parsers.nonemptyline           = parsers.line - parsers.blankline

parsers.infostring     = (parsers.linechar - (parsers.backtick
                       + parsers.space^1 * (parsers.newline + parsers.eof)))^0

-- parse many p between starter and ender
parsers.between = function(p, starter, ender)
  local ender2 = B(parsers.nonspacechar) * ender
  return (starter * #parsers.nonspacechar * Ct(p * (p - ender2)^0) * ender2)
end

-- lpeg.Cg(patt [, name]) 	the values produced by patt, optionally tagged with name
parsers.openticks   = Cg(parsers.backtick^1, "ticks")

local function captures_equal_length(s,i,a,b)
  return #a == #b and i
end

parsers.closeticks  = parsers.space^-1
                    * Cmt(C(parsers.backtick^1)
                         * Cb("ticks"), captures_equal_length)

parsers.intickschar = (parsers.any - S(" \n\r`"))
                    + (parsers.newline * -parsers.blankline)
                    + (parsers.space - parsers.closeticks)
                    + (parsers.backtick^1 - parsers.closeticks)

parsers.inticks     = parsers.openticks * parsers.space^-1
                    * C(parsers.intickschar^0) * parsers.closeticks
local function captures_geq_length(s,i,a,b)
  return #a >= #b and i
end

local fenceindent
parsers.fencehead    = function(char)
  return               C(parsers.nonindentspace) / function(s) fenceindent = #s end
                     * Cg(char^3, "fencelength")
                     * parsers.optionalspace * C(parsers.infostring)
                     * parsers.optionalspace * (parsers.newline + parsers.eof)
end

parsers.fencetail    = function(char)
  return               parsers.nonindentspace
                     * Cmt(C(char^3) * Cb("fencelength"), captures_geq_length)
                     * parsers.optionalspace * (parsers.newline + parsers.eof)
                     + parsers.eof
end

parsers.fencedline   = function(char)
  return               C(parsers.line - parsers.fencetail(char))
                     / function(s)
                         i = 1
                         remaining = fenceindent
                         while true do
                           c = s:sub(i, i)
                           if c == " " and remaining > 0 then
                             remaining = remaining - 1
                             i = i + 1
                           elseif c == "\t" and remaining > 3 then
                             remaining = remaining - 4
                             i = i + 1
                           else
                             break
                           end
                         end
                         return s:sub(i)
                       end
end

parsers.BacktickFencedCode
                     = parsers.fencehead(parsers.backtick)
                     * Cs(parsers.fencedline(parsers.backtick)^0)
                     * parsers.fencetail(parsers.backtick)

parsers.HeadingStart = #parsers.hash * C(parsers.hash^-6)
                     * -parsers.hash / length

-----
-----

--parsers.Inline         = V("Inline")
--parsers.Block        = V("Block")

local function strip_atx_end(s)
  return s:gsub("[s]*\n$","")
end

M.reader = {}
function M.reader.new(writer, options)
  local self = {}

--defaultOptions.shiftHeadings = 0
  local d1 = {cacheDir = "./cache", shiftHeadings = 0}
  options = options or {}
  setmetatable(options, { __index = function (_, key) return d1[key] end })

  local larsers    = {}

  local function create_parser(name, grammar)
    return function(str)
      local res = lpeg.match(grammar(), str)
      if res == nil then
        error(format("%s failed on:\n%s", name, str:sub(1,40)))
      else
        return res
      end
    end
  end

  local parse_blocks = create_parser("parse_blocks", function() return larsers.blocks end)

  local parse_blocks_toplevel = create_parser("parse_blocks_toplevel", function() return larsers.blocks_toplevel end)

  local parse_inlines
    = create_parser("parse_inlines",
                    function()
                      return larsers.inlines
                    end)

  larsers.dig = parsers.digit

--  larsers.Str      = (parsers.normalchar * (parsers.normalchar + parsers.at)^0)
--                   / writer.string
  larsers.Str      = parsers.normalchar^1
                   / writer.string

  larsers.UlOrStarLine  = parsers.asterisk^3
                        / writer.string

  larsers.Endline   = parsers.newline * -( -- newline, but not before...
                        parsers.blankline -- paragraph break
                      + parsers.eof       -- end of document
                    ) * parsers.spacechar^0
                    / writer.space

  larsers.Space      = parsers.spacechar^2 * larsers.Endline
  / writer.linebreak
                     + parsers.spacechar^1 * larsers.Endline^-1 * parsers.eof / ""
                     + parsers.spacechar^1 * larsers.Endline^-1
                                           * parsers.optionalspace
                                           / writer.space
                     + larsers.Endline * larsers.Endline^-1 / writer.space

--  larsers.NonbreakingEndline
--                    = parsers.newline * -( -- newline, but not before...
--                        parsers.blankline -- paragraph break
--                      + parsers.tightblocksep  -- nested list
--                      + parsers.eof       -- end of document
--                    ) * parsers.spacechar^0
--                    / writer.nbsp

--  larsers.NonbreakingSpace
--                  = parsers.spacechar^2 * larsers.Endline / writer.linebreak
--                  + parsers.spacechar^1 * larsers.Endline^-1 * parsers.eof / ""
--                  + parsers.spacechar^1 * larsers.Endline^-1
--                                        * parsers.optionalspace
--                                        / writer.nbsp

  larsers.Plain        = parsers.nonindentspace * Ct( V("Inline")^1 )
                       / writer.plain

  larsers.Blank        = parsers.blankline
  / ""

  larsers.Strong = ( parsers.between(V("Inline"), parsers.doubleasterisks,
                                     parsers.doubleasterisks)
                   ) / writer.strong

  larsers.Emph   = ( parsers.between(V("Inline"), parsers.asterisk,
                                     parsers.asterisk)
                   ) / writer.emphasis

  larsers.Code     = parsers.inticks / writer.code

  larsers.FencedCode   = parsers.BacktickFencedCode
                       / function(infostring, code)
                           return writer.fencedCode(infostring, code)
                         end

  larsers.Heading = Cg(parsers.HeadingStart,"level")
                     * parsers.optionalspace
                     * (C(parsers.line) / strip_atx_end / parse_inlines)
                     * Cb("level")
                     / writer.heading

  local syntax =
    { "Blocks",

      Blocks   = larsers.Blank^0 * V("Block")^-1
               * (larsers.Blank^0 * V("Block"))^0
               * larsers.Blank^0 * parsers.eof,

      Block                 = V("Heading") + V("FencedCode") + V("Plain"),
--                            + V("Verbatim")

      Heading               = larsers.Heading,
      FencedCode            = larsers.FencedCode,
      Plain                 = larsers.Plain,

      Inline                = V("Space")
      + V("Strong") + V("Emph") + V("Str")
      + V("Code"),

      Str                   = larsers.Str,
      Strong                = larsers.Strong,
      Emph                  = larsers.Emph,
      Space                 = larsers.Space,
      Code                  = larsers.Code,
    }

  local blocks_toplevel_t = util.table_copy(syntax)
  larsers.blocks_toplevel = Ct(blocks_toplevel_t)

  local inlines_t = util.table_copy(syntax)
  inlines_t[1] = "Inlines"
  inlines_t.Inlines = V("Inline")^0 * (parsers.spacing^0 * parsers.eof / "")
  larsers.inlines = Ct(inlines_t)

  function self.convert(input)
    references = {}
    local opt_string = {}
    local name = util.cache(options.cacheDir, input, function(input)
        return util.rope_to_string(parse_blocks_toplevel(input)) .. writer.eof
      end, ".md" .. writer.suffix)
    return writer.pack(name)
  end

  return self
end

function M.new(options)
  local writer = M.writer.new(options)
  local reader = M.reader.new(writer, options)
  return reader.convert
end

local convert = M.new({})
local input = assert(io.open(arg[1], "r"):read("*a")) -- "*a" returns all the content of md file
print(convert(input .. "\n"))
