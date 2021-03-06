#!/usr/bin/env moon
----- mooni -----
-- A basic MoonScript REPL
--
parse = require "moonscript.parse"
compile = require "moonscript.compile"
append = table.insert

-- need to keep track of what globals have been added during the session
oldg = {k,v for k,v in pairs _G}
_G._FOO = true

-- (this will return their names)
newglobs = -> [k for k in pairs _G when not oldg[k]]

chopline = (txt) -> txt\gsub '^[^\n]+\n','', 1
firstline = (txt) -> txt\match '^[^\n]*'

mytostring = tostring

capture = (ok,...) ->
    t = {...}
    t.n = select '#',...
    return ok,t

eval_lua = (lua_code) ->
    chunk,err = loadstring lua_code, 'tmp'
    if err -- Lua compile error is rare!
        print err
        return
    ok,res = capture pcall chunk
    if not ok -- runtime error
        print res[1]
        return
    elseif #res > 0
        -- this allows for overriding basic value printing
        _G._l = res[1] -- save last value calculated
        out = [mytostring res[i] for i = 1,res.n]
        io.write table.concat(out,'\t'),'\n'

old_lua_code = nil

translate = (moon_code) ->
    -- Ugly fiddle #2: we force Moonscript code to regard
    -- any _new_ globals as known globals
    locs = 'local '..table.concat(newglobs!,',')
    moon_code = locs..'\n'..moon_code
    tree, err = parse.string moon_code
    if not tree
        print err
        return
    lua_code, err, pos = compile.tree tree
    if not lua_code
        print compile.format_error err, pos, moon_code
        return
    -- our code is ready
    -- Fiddle #2 requires us to lose the top local declarations we inserted
    lua_code = chopline lua_code
    -- Fiddle #1 Moonscript will of course declare any new variables
    -- as local. This fiddle removes the 'local'
    was_local, rest = lua_code\match '^local (%S+)(.+)'
    if was_local
        if rest\match '\n' then rest = firstline rest
        -- two cases; either a direct local assignmnent or a declaration line
        if rest\match '='
            lua_code = lua_code\gsub '^local%s+', ''
        else
            lua_code = chopline lua_code
    old_lua_code = lua_code
    eval_lua lua_code

opts,i = {},0
nexta = ->
    i += 1
    arg[i]

while true
    a = nexta!
    break if not a
    flag,rest = a\match '^%-(%a)(%S*)'
    if flag == 'l'
        lib = (rest and #rest > 0) and rest or nexta!
        require lib
    elseif flag == 'e'
        translate nexta!
        os.exit 0

ok,dump = pcall require,'moondump'
if ok
    mytostring = dump
    _G.tstring = mytostring

normal, block = '> ','>> '
prompt = normal

get_line = nil    
ok,LN = pcall require, 'linenoise'
if ok
    get_line = ->
        line = LN.linenoise prompt
        if line and line\match '%S'
            LN.addhistory line
        line
else
    get_line = ->
        io.write prompt
        io.read!

print 'MoonScript version 0.2.3'
print 'Note: use backslash or tab to start a block'

while true
    line = get_line!
    if not line then break
    -- a line ending with a tab or a backslash starts a block
    if line\match '[\t\\]$'
        prompt = block
        line = line\gsub '\\$',''
        code = {line}
        line = get_line!
        while #line > 0  -- block ends with empty line
            append code, line
            line = get_line!
        prompt = normal
        code = table.concat code, '\n'
        translate code
    elseif line\match '^%?que'
        print old_lua_code
    else
        translate line
