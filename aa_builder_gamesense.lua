_G.SCRIPT_NAME = "G$Z0LINA";


-- gazolina fixed by 2k00 , enjoy

local origrequire = require
local compiler = loadstring or load

local modules = {
    ["neverlose/clipboard"] = function(require)
        local char_array = ffi.typeof 'char[?]'

        local native_GetClipboardTextCount = utils.get_vfunc('vgui2.dll', 'VGUI_System010', 7, 'int(__thiscall*)(void*)')
        local native_SetClipboardText = utils.get_vfunc('vgui2.dll', 'VGUI_System010', 9, 'void(__thiscall*)(void*, const char*, int)')
        local native_GetClipboardText = utils.get_vfunc('vgui2.dll', 'VGUI_System010', 11, 'int(__thiscall*)(void*, int, const char*, int)')

        local function get()
            local len = native_GetClipboardTextCount()
            if len > 0 then
                local char_arr = char_array(len)
                native_GetClipboardText(0, char_arr, len)
                return ffi.string(char_arr, len - 1)
            end
        end

        local function set(...)
            local text = tostring(table.concat({ ... }))
            native_SetClipboardText(text, string.len(text))
        end

        return {
            set = set,
            get = get
        }
    end,

    ["neverlose/base64"] = function(require)
        local shl, shr, band = bit.lshift, bit.rshift, bit.band
        local char, byte, gsub, sub, format, concat, tostring, error, pairs = string.char, string.byte, string.gsub, string.sub, string.format, table.concat, tostring, error, pairs

        local extract = function(v, from, width)
            return band(shr(v, from), shl(1, width) - 1)
        end

        local function makeencoder(alphabet)
            local encoder, decoder = {}, {}
            for i=1, 65 do
                local chr = byte(sub(alphabet, i, i)) or 32
                if decoder[chr] ~= nil then
                    error('invalid alphabet: duplicate character ' .. tostring(chr), 3)
                end
                encoder[i-1] = chr
                decoder[chr] = i-1
            end
            return encoder, decoder
        end

        local encoders, decoders = {}, {}

        encoders['base64'], decoders['base64'] = makeencoder('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=')
        encoders['base64url'], decoders['base64url'] = makeencoder('ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_')

        local alphabet_mt = {
            __index = function(tbl, key)
                if type(key) == 'string' and (key:len() == 64 or key:len() == 65) then
                    encoders[key], decoders[key] = makeencoder(key)
                    return tbl[key]
                end
            end
        }

        setmetatable(encoders, alphabet_mt)
        setmetatable(decoders, alphabet_mt)

        local function encode(str, encoder)
            encoder = encoders[encoder or 'base64'] or error('invalid alphabet specified', 2)
            str = tostring(str)
            local t, k, n = {}, 1, #str
            local lastn = n % 3
            local cache = {}

            for i = 1, n-lastn, 3 do
                local a, b, c = byte(str, i, i+2)
                local v = a*0x10000 + b*0x100 + c
                local s = cache[v]
                if not s then
                    s = char(encoder[extract(v,18,6)], encoder[extract(v,12,6)], encoder[extract(v,6,6)], encoder[extract(v,0,6)])
                    cache[v] = s
                end
                t[k] = s
                k = k + 1
            end

            if lastn == 2 then
                local a, b = byte(str, n-1, n)
                local v = a*0x10000 + b*0x100
                t[k] = char(encoder[extract(v,18,6)], encoder[extract(v,12,6)], encoder[extract(v,6,6)], encoder[64])
            elseif lastn == 1 then
                local v = byte(str, n)*0x10000
                t[k] = char(encoder[extract(v,18,6)], encoder[extract(v,12,6)], encoder[64], encoder[64])
            end
            return concat(t)
        end

        local function decode(b64, decoder)
            decoder = decoders[decoder or 'base64'] or error('invalid alphabet specified', 2)
            local pattern = '[^%w%+%/%=]'
            b64 = gsub(tostring(b64), pattern, '')

            local cache = {}
            local t, k = {}, 1
            local n = #b64
            local padding = sub(b64, -2) == '==' and 2 or sub(b64, -1) == '=' and 1 or 0

            for i = 1, padding > 0 and n-4 or n, 4 do
                local a, b, c, d = byte(b64, i, i+3)
                local v0 = a*0x1000000 + b*0x10000 + c*0x100 + d
                local s = cache[v0]
                if not s then
                    local v = decoder[a]*0x40000 + decoder[b]*0x1000 + decoder[c]*0x40 + decoder[d]
                    s = char(extract(v,16,8), extract(v,8,8), extract(v,0,8))
                    cache[v0] = s
                end
                t[k] = s
                k = k + 1
            end

            if padding == 1 then
                local a, b, c = byte(b64, n-3, n-1)
                local v = decoder[a]*0x40000 + decoder[b]*0x1000 + decoder[c]*0x40
                t[k] = char(extract(v,16,8), extract(v,8,8))
            elseif padding == 2 then
                local a, b = byte(b64, n-3, n-2)
                local v = decoder[a]*0x40000 + decoder[b]*0x1000
                t[k] = char(extract(v,16,8))
            end
            return concat(t)
        end

        return {
            encode = encode,
            decode = decode
        }
    end,
    ["neverlose/pui"] = function(require)
        -- perfect user interface
        ----- neverlose

        --------------------------------------------------------------------------------
        -- #region :: Header

        --
        -- #region : Definitions

        local _PUIVERSION = 1

        --#region: localization

        local print, require, print_raw, print_error, color, next, vector, type, pairs, ipairs, getmetatable, setmetatable, assert, rawget, rawset, rawequal, rawlen, unpack, select, tonumber, tostring, error, pcall, xpcall, print_dev =
              print, require, print_raw, print_error, color, next, vector, type, pairs, ipairs, getmetatable, setmetatable, assert, rawget, rawset, rawequal, rawlen, unpack, select, tonumber, tostring, error, pcall, xpcall, print_dev

        local C = function (t) local c = {} for k, v in next, t do c[k] = v end return c end

        local table, math, string, ui = C(table), C(math), C(string), C(ui)

        --#endregion

        --#region: global table

        table.find = function (t, j)  for k, v in next, t do if v == j then return k end end return false  end
        table.ifind = function (t, j)  for i = 1, table.maxn(t) do if t[i] == j then return i end end  end
        table.ihas = function (t, ...) local arg = {...} for i = 1, table.maxn(t) do for j = 1, #arg do if t[i] == arg[j] then return true end end end return false end

        table.filter = function (t)  local res = {} for i = 1, table.maxn(t) do if t[i] ~= nil then res[#res+1] = t[i] end end return res  end
        table.append = function (t, ...)  for i, v in ipairs{...} do table.insert(t, v) end  end
        table.appendf = function (t, ...)  local arg = {...} for i = 1, table.maxn(arg) do local v = arg[i] if v ~= nil then t[#t+1] = v end end  end
        table.range = function (t, i, j)  local r = {} for l = i or 0, j or #t do r[#r+1] = t[l] end return r  end
        table.copy = function (o) if type(o) ~= "table" then return o end local r = {} for k, v in next, o do r[table.copy(k)] = table.copy(v) end return r end

        math.round = function (value)  return math.floor (value + 0.5)  end
        math.lerp = function (a, b, w)  return a + (b - a) * w  end

        local ternary = function (c, a, b)  if c then return a else return b end  end
        local aserror = function (a, msg, level) if not a then error(msg, level and level + 1 or 4) end end
        local contend = function (func, callback, ...)
            local t = { pcall(func, ...) }
            if not t[1] then if type(callback) == "function" then return callback(t[2]) else error(t[2], callback or 2) end end
            return unpack(t, 2)
        end

        local debug = setmetatable({
            warning = function (...)
                print_raw("[\ae09334ffpui", "] ", ...)
            end,
            error = function (...)
                print_raw("[\aef6060ffpui", "] ", ...)
                cvar.play:call("ui/menu_invalid.wav")
                error()
            end
        }, {
            __call = function (self, ...)
                if _IS_MARKET then return end
                print_raw("\a74a6a9ffpui - ", ...)
                print_dev(...)
            end
        })

        --#endregion

        --#region: directory tools

        local dirs = {
            execute = function (t, path, func)
                local p, k for _, s in ipairs(path) do
                    k, p, t = s, t, t[s]
                    if t == nil then return end
                end
                if p[k] ~= nil then func(p[k], p) end
            end,
            replace = function (t, path, value)
                local p, k for _, s in ipairs(path) do
                    k, p, t = s, t, t[s]
                    if t == nil then return end
                end
                p[k] = value
            end,
            find = function (t, path)
                local p, k
                for _, s in ipairs(path) do
                    k, p, t = s, t, t[s]
                    if type(t) ~= "table" then break end
                end
                return p[k]
            end,
        }

        dirs.pave = function (t, place, path)
            local p = t for i, v in ipairs(path) do
                if type(p[v]) == "table" then p = p[v]
                else p[v] = (i < #path) and {} or place  p = p[v]  end
            end return t
        end

        dirs.extract = function (t, path)
            if not path or #path == 0 then return t end
            local j = dirs.find(t, path)
            return dirs.pave({}, j, path)
        end

        --#endregion

        local pui, pui_mt, methods_mt = {}, {}, { element = {}, group = {} }
        local tools, elemence = {}, {}
        local config, is_setup = {}, false

        local stringlist

        --
        local dpi = render.get_scale(1)

        -- #endregion
        --

        --
        -- #region : Elements

        --#region: definitions

        local elements = {
            switch					= { type = "boolean",	arg = 2 },
            slider					= { type = "number",	arg = 6 },
            combo					= { type = "string",	arg = 2, variable = true },
            language				= { type = "string",	arg = 2, variable = true },
            selectable				= { type = "table",		arg = 2, variable = true },
            button					= { type = "function",	arg = 3, unsavable = true },
            list					= { type = "number",	arg = 2, variable = true },
            listable				= { type = "table",		arg = 2, variable = true },
            label					= { type = "string",	arg = 1, unsavable = true },
            texture					= { type = "userdata",	arg = 5, unsavable = true },
            image					= { type = "userdata",	arg = 5, unsavable = true },
            hotkey					= { type = "number",	arg = 2 },
            input					= { type = "string",	arg = 2 },
            textbox					= { type = "string",	arg = 2 },
            color_picker			= { type = "userdata",	arg = 2 },
            value					= { type = "any",		arg = 2 },
            ["sol.lua::LuaVarClr"]	= { type = "userdata",	arg = 2 },
            [""]					= { type = "any",		arg = 2 },
        }

        --#endregion

        --#region: methods parsing

        local __mt = {
            group = {}, wrp_group = {},
            element = {}, wrp_element = {},
            events = {}
        } do
            local element = ui.find("Miscellaneous", "Main", "Movement", "Air Duck")
            local group = element:parent()

            local element_keys, group_keys = { "__eq", "__index", "__name", "__type", "color_picker", "create", "disabled", "export", "get", "get_override", "id", "import", "key", "list", "name", "new", "override", "parent", "reset", "set", "set_callback", "tooltip", "type", "unset_callback", "update", "visibility",
            }, { "__eq", "__index", "__name", "__type", "button", "color_picker", "combo", "create", "disabled", "export", "hotkey", "import", "input", "label", "list", "listable", "name", "parent", "selectable", "slider", "switch", "texture", "value", "visibility", }

            for i = 1, #element_keys do
                local k = element_keys[i]
                local v = element[k]
                __mt.element[k], __mt.wrp_element[k] = v, function (self, ...) return v(self.ref, ...) end
            end

            for i = 1, #group_keys do
                local k = group_keys[i]
                local v = group[k]
                __mt.group[k], __mt.wrp_group[k] = v, function (self, ...) return v(self.ref, ...) end
            end
        end

        --#endregion

        --#region: weak tables

        local icons = setmetatable({}, {
            __mode = "k",
            __index = function (self, name)
                local icon = ui.get_icon(name)
                if #icon == 0 then
                    debug.warning(icon, ("<%s> icon not found"):format(name))
                    return "[?]"
                end
                self[name] = icon
                return self[name]
            end
        })

        local groups = setmetatable({}, {
            __mode = "k",
            __index = function (self, raw)
                local key, group
                local kind = type(raw)

                if kind == "table" then
                    if raw.__name == "pui::group" then return raw.ref end
                    for i = 1, #raw do  raw[i] = tools.format(raw[i])  end

                    key, group = raw[1] .."-".. (raw[2] or ""), ui.create(unpack(raw))
                elseif kind == "userdata" and raw.__name == "sol.lua::LuaGroup" then
                    key, group = tostring(raw), raw
                else
                    raw = tools.format(raw)
                    key, group = tostring(raw), ui.create(raw)
                end

                self[key] = group

                return self[key]
            end
        })

        --#endregion

        -- #endregion
        --

        --
        -- #region : Utils

        --#region: tools

        do
            local fmethods = {
                gradients = function (col, text)
                    local colors = {}; for w in string.gmatch(col, "\b%x+") do
                        colors[#colors+1] = color(string.sub(w, 2))
                    end
                    if #colors > 0 then return tools.gradient(text, colors) end
                end,
                colors = function (col)
                    return pui.colors[col] and ("\a".. pui.colors[col]:to_hex()) or "\aDEFAULT"
                end,
                macros = setmetatable({}, {
                    __newindex = function (self, key, value)
                        local kv = type(value)

                        if kv == "string" then
                        elseif kv == "userdata" and value.__name == "sol.ImColor" then
                            value = "\a" .. value:to_hex()
                        else
                            value = tostring(value)
                        end

                        rawset(self, tostring(key), value)
                    end,
                    __index = function (self, key) return rawget(self, key) end
                })
            }

            pui.macros = fmethods.macros

            tools.format = function (s)
                if type(s) == "string" then
                    if stringlist then stringlist[s] = true end
                    s = string.gsub(s, "\b<(.-)>", fmethods.macros)
                    s = string.gsub(s, "[\v\r]", { ["\v"] = "\a{Link Active}", ["\r"] = "\aDEFAULT" })
                    s = string.gsub(s, "([\b%x]-)%[(.-)%]", fmethods.gradients)
                    s = string.gsub(s, "\a%[(.-)%]", fmethods.colors)
                    s = string.gsub(s, "\f<(.-)>", icons)
                end

                return s
            end

            tools.gradient = function (text, colors)
                local symbols, length = {}, #(text:gsub(".[\128-\191]*", "a"))
                local s = 1 / (#colors - 1)

                local i = 0
                for letter in string.gmatch(text, ".[\128-\191]*") do
                    i = i + 1

                    local weight = i / length
                    local cw = weight / s
                    local j = math.ceil(cw)
                    local w = (cw / j)
                    local L, R = colors[j], colors[j+1]

                    local r = L.r + (R.r - L.r) * w
                    local g = L.g + (R.g - L.g) * w
                    local b = L.b + (R.b - L.b) * w
                    local a = L.a + (R.a - L.a) * w

                    symbols[#symbols+1] = ("\a%02x%02x%02x%02x%s"):format(r, g, b, a, letter)
                end

                symbols[#symbols+1] = "\aDEFAULT"

                return table.concat(symbols)
            end
        end

        --#endregion

        --#region: elemence

        do
            elemence.new = function (ref)
                local this = { ref = ref }
                --

                this.__depend = { {}, {} }
                this[0], this[1] = {
                    type = __mt.element.type(this.ref),
                    events = {}, callbacks = {},
                }, {}

                this[0].savable = not elements[this[0].type].unsavable == true
                --

                if this[0].type ~= "button" then
                    local v1, v2 = __mt.element.get(this.ref)
                    if v2 ~= nil then
                        this.value = { v1, v2 }
                        __mt.element.set_callback(this.ref, function (self)
                            this.value = { __mt.element.get(self) }
                        end)
                    else
                        this.value = v1
                        __mt.element.set_callback(this.ref, function (self)
                            this.value = __mt.element.get(self)
                        end)
                    end
                end

                return setmetatable(this, methods_mt.element)
            end

            elemence.group = function (ref)
                return setmetatable({
                    ref = ref, par = ref:parent(),
                    __depend = { {}, {} }
                }, methods_mt.group)
            end

            elemence.dispense = function (key, ...)
                local args, ctx = {...}, elements[key]

                args.n = table.maxn(args)

                local variable, counter = (ctx and ctx.variable) and type(args[2]) == "string", 1
                args.req, args.misc = (ctx and not variable) and ctx.arg or args.n, {}

                for i = 1, args.n do
                    local v = args[i]
                    local kind = type(v)

                    if i == 2 and ctx.variable and not variable then
                        for j = 1, #v do
                            v[j] = tools.format(v[j])
                        end
                    else
                        args[i] = tools.format(v)
                    end

                    if kind == "userdata" and v.__name == "sol.Vector" then  args[i] = v * dpi  end

                    if i > args.req then
                        args.misc[counter], counter = v, counter + 1
                    end
                end

                return args
            end

            elemence.memorize = function (self, path, location)
                if type(self) ~= "table" or self.__name ~= "pui::element" or self[0].skipsave then return end

                location = location or config
                local main = false
                if self[0].savable then
                    dirs.pave(location, self.ref, path)
                    main = true
                end

                if rawget(self, "color") then
                    local pathc = table.copy(path)
                    pathc[#pathc] = (main and "*" or "") .. path[#path]
                    dirs.pave(location, self.color.ref, pathc)
                elseif next(self[1]) then
                    local pathc, gear = table.copy(path), {}
                    pathc[#pathc] = (main and "~" or "") .. path[#path]
                    for k, v in next, self[1] do
                        if v[0].savable and not v[0].skipsave then
                            gear[k] = v.ref
                            if rawget(v, "color") then gear["*"..k] = v.color.ref end
                        end
                    end
                    dirs.pave(location, gear, pathc)
                end
            end

            elemence.features = function (self, args)
                if self[0].type == "image" or self[0].type == "value" then return end

                local had_child, had_tooltip = false, false

                for i = 1, table.maxn(args) do
                    local v = args[i]
                    local t = type(v)

                    if not had_child and t == "function" then
                        local c
                        methods_mt.element.create(self)
                        self[1], c = v(self[0].gear, self)
                        if c ~= nil then self[0].gear:depend{self, c} end
                        had_child = true

                    elseif not had_child and (t == "userdata" and v.__name == "sol.ImColor") or (t == "table" and (v[1] and v[1].__name == "sol.ImColor" or v[next(v)] and v[next(v)][1].__name == "sol.ImColor")) then
                        local im = t == "table"
                        local g = im and v[1] or v
                        local d = v[2]

                        methods_mt.element.color_picker(self, g)
                        if d ~= nil then self.color:depend{self, d} end
                        had_child = true

                    elseif not had_tooltip and t == "string" or (t == "table" and type(v[1]) == "string") then
                        __mt.element.tooltip(self.ref, tools.format(v))
                        had_tooltip = true
                    elseif i == 2 and v == false then
                        self[0].skipsave = true
                    end
                end
            end

            --#region: .depend

            local cases = {
                combo = function (v)
                    if v[3] == true then
                        return v[1].value ~= v[2]
                    else
                        for i = 2, #v do
                            if v[1].value == v[i] then return true end
                        end
                    end
                    return false
                end,
                list = function (v)
                    if v[3] == true then
                        return v[1].value ~= v[2]
                    else
                        for i = 2, #v do
                            if v[1].value == v[i] then return true end
                        end
                    end
                    return false
                end,
                selectable = function (v)
                    if v[2] == true then
                        return #v[1].value > 0
                    elseif v[3] == true then
                        return not table.ihas(v[1].value, unpack(v, 2))
                    else
                        return table.ihas(v[1].value, unpack(v, 2))
                    end
                end,
                listable = function (v)
                    if v[2] == true then
                        return #v[1].value > 0
                    elseif v[3] == true then
                        return not table.ihas(v[1].value, unpack(v, 2))
                    else
                        return table.ihas(v[1].value, unpack(v, 2))
                    end
                end,
                slider = function (v)
                    return v[2] <= v[1].value and v[1].value <= (v[3] or v[2])
                end,
            }

            local depend = function (v)
                local condition = false

                if type(v[2]) == "function" then
                    condition = v[2]( v[1] )
                else
                    local f = cases[v[1][0].type]
                    if f then condition = f(v)
                    else condition = v[1].value == v[2] end
                end

                return condition and true or false
            end

            elemence.dependant = function (__depend, dependant, disabler)
                local count = 0

                for i = 1, #__depend do
                    count = count + ( depend(__depend[i]) and 1 or 0 )
                end

                local eligible = count >= #__depend
                local kind = dependant.__name == "sol.lua::LuaGroup" and "group" or "element"
                __mt[kind][disabler and "disabled" or "visibility"](dependant, ternary(disabler, not eligible, eligible))
            end

            --#endregion
        end

        --#endregion

        -- #endregion
        --


        -- #endregion ------------------------------------------------------------------
        --



        --------------------------------------------------------------------------------
        -- #region :: PUI


        --
        -- #region : pui

        --#region: variables

        pui.version = _PUIVERSION

        pui.colors = {}
        pui.accent, pui.alpha = ui.get_style("Link Active"), ui.get_alpha()
        pui.menu_position, pui.menu_size = ui.get_position(), ui.get_size()

        events.render:set(function ()
            pui.accent, pui.alpha = ui.get_style("Link Active"), ui.get_alpha()
            pui.menu_position, pui.menu_size = ui.get_position(), ui.get_size()
        end)

        --#endregion

        --#region: features

        pui.string = tools.format

        pui.create = function (tab, name, align)
            if type(name) == "table" then
                local collection = {}
                for k, v in ipairs(name) do
                    collection[ v[1] or k ] = elemence.group( groups[{tab, v[2], v[3]}] )
                end
                return collection
            else
                return elemence.group( groups[name and {tab, name, align} or tab] )
            end
        end

        pui.find = function (...)
            local arg = {...}
            local children for i, v in ipairs(arg) do
                if type(v) == "table" then
                    children, arg[i] = v, nil
                break end
            end

            local found = { ui.find( unpack(arg) ) }

            for i, v in ipairs(found) do
                found[i] = elemence[v.__name == "sol.lua::LuaGroup" and "group" or "new"](v)
            end

            if found[2] and found[2].ref.__name == "sol.lua::LuaVar" then
                found[1].color, found[2] = found[2], nil
            elseif children and found[1] then
                for k, v in next, children do
                    local path = {...}
                    path[#path] = v
                    found[1][1][k] = pui.find( unpack(path) )
                end
            end

            return found[1]
        end

        pui.sidebar = function (name, icon)
            name, icon = tools.format(name), icon and tools.format(icon) or nil

            ui.sidebar(name, icon)
        end

        pui.get_icon = function (name)
            return icons[name]
        end

        pui.traverse = function (t, f, p)
            p = p or {}

            if type(t) == "table" and (t.__name ~= "pui::element" and t.__name ~= "pui::group") and t[#t] ~= "~" then
                for k, v in next, t do
                    local np = table.copy(p); np[#np+1] = k
                    pui.traverse(v, f, np)
                end
            else
                f(t, p)
            end
        end

        pui.translate = function (original, translations)
            original = tools.format(original)
            for k, v in next, translations or {} do
                ui.localize(k, original, tools.format(v))
            end
            return original
        end

        do -- categories
            local mt = {
                create = function (self, name, align)
                    return elemence.group(__mt.group.create(self[1], tools.format(name), align))
                end
            }	mt.__index = mt

            local sidebar = ui.find("Aimbot", "Anti Aim"):parent():parent()
            local cats = {}

            pui.category = function (name, tab)
                name, tab = tostring(tools.format(name)), tostring(tools.format(tab))
                local ref = contend(ui.find, function () end, name, tab)

                if not cats[name] then
                    cats[name] = {}
                    if not ref then cats[name][0] = sidebar:create(name) end
                end
                if not cats[name][tab] then
                    if ref then cats[name][tab] = ref
                    else cats[name][tab] = cats[name][0]:create(tab) end
                end

                return setmetatable({cats[name][tab]}, mt)
            end
        end

        pui.string_recorder = {
            open = function () stringlist = {} end,
            close = function ()
                if stringlist then
                    local list, count = {}, 0
                    for k, v in next, stringlist do
                        count = count + 1
                        list[count] = k
                    end
                    stringlist = nil
                    return list
                end
            end
        }

        --#endregion

        --#region: config system

        do
            pui.is_loading_config, pui.is_saving_config = false, false

            local function traverse_b (t, f, p)
                p = p or {}

                if type(t) == "table" and t._S == nil then
                    for k, v in next, t do
                        local np = table.copy(p); np[#np+1] = k
                        traverse_b(v, f, np)
                    end
                else
                    f(t, p)
                end
            end

            local convert = function (t)
                local new = {}
                traverse_b(t, function (v, p)
                    if type(v) == "table" and v._S ~= nil then
                        if v._C then
                            local col = table.copy(p)
                            col[#col] = "*" .. col[#col]
                            dirs.pave(new, v._C, col)
                            dirs.pave(new, v._S, p)
                        else
                            local gear = table.copy(v)
                            gear._S = nil
                            for gk, gv in next, gear do
                                if type(gv) == "table" and gv._C then
                                    gear["*"..gk], gear[gk] = gv._C, gv._S
                                end
                            end

                            local gearpath = table.copy(p)
                            gearpath[#gearpath] = "~" .. gearpath[#gearpath]
                            dirs.pave(new, gear, gearpath)
                            dirs.pave(new, v._S, p)
                        end
                    else
                        dirs.pave(new, v, p)
                    end
                end)
                return new
            end

            local locate = function (init, arg)
                if type(arg[1]) == "table" then
                    local r = {}
                    for i, v in ipairs(arg) do
                        local d = dirs.find(init, v)
                        dirs.pave(r, d, v)
                    end

                    return r
                else
                    return dirs.extract(init, arg)
                end
            end

            local save = function (location, ...)
                pui.is_saving_config = true

                local arg, packed = {...}, {}

                pui.traverse(locate(location, arg), function (ref, path)
                    local etype = __mt.element.type(ref)
                    local value, value2 = __mt.element[etype == "hotkey" and "key" or "get"](ref)
                    local vtype, v2type = type(value), type(value2)

                    if etype == "color_picker" then
                        if vtype == "table" then
                            value2, v2type = value, vtype
                            value, vtype = __mt.element.list(ref)[1], "string"
                        end

                        if value2 then
                            value = { value }
                            if v2type == "table" then
                                for i = 1, #value2 do
                                    value[#value+1] = "#".. value2[i]:to_hex()
                                end
                            else
                                value[2] = "#".. value2:to_hex()
                            end
                            value[#value+1] = "~"
                        else
                            value = "#".. value:to_hex()
                        end
                    elseif vtype == "table" then
                        value[#value+1] = "~"
                    end

                    dirs.pave(packed, value, path)
                end)

                pui.is_saving_config = false
                return packed
            end
            local load = function (location, data, ...)
                if not data then return end

                local arg, reset = {...}, true
                if arg[1] == false then table.remove(arg, 1); reset = false end

                pui.is_loading_config = true

                local packed = convert(locate(data, arg))
                pui.traverse(locate(location, arg), function (ref, path)
                    local value = dirs.find(packed, path)

                    local multicolor
                    local vtype, etype = type(value), __mt.element.type(ref)
                    local object = elements[etype] or elements[ref.__name]

                    if etype == "color_picker" then
                        if vtype == "string" and value:sub(1, 1) == "#" then
                            value = color(value)
                            vtype = "userdata"
                        elseif vtype == "table" then
                            value[#value] = nil
                            for i = 2, #value do value[i] = color(value[i]) end
                            multicolor = true
                            vtype = "userdata"
                        end
                    elseif vtype == "table" and value[#value] == "~" then
                        value[#value] = nil
                    end

                    if not object or (object.type ~= "any" and object.type ~= vtype) then
                        return reset and __mt.element.reset(ref) or nil
                    end

                    pcall(function ()
                        if etype == "hotkey" then
                            __mt.element.key(ref, value)
                        elseif etype == "color_picker" and multicolor then
                            __mt.element.set(ref, value[1])
                            __mt.element.set(ref, value[1], table.range(value, 2))
                        else
                            __mt.element.set(ref, value)
                        end
                    end)
                end)

                pui.is_loading_config = false
            end

            local package_mt = {
                __type = "pui::package", __metatable = false,
                __call = function (self, raw, ...)
                    return (type(raw) == "table" and load or save)(self[0], raw, ...)
                end,
                save = function (self, ...) return save(self[0], ...) end,
                load = function (self, ...) load(self[0], ...) end,
            }	package_mt.__index = package_mt

            pui.setup = function (t, isolate)
                if isolate == true then
                    local package = { [0] = {} }
                    pui.traverse(t, function (r, p) elemence.memorize(r, p, package[0]) end)
                    return setmetatable(package, package_mt)
                else
                    if is_setup then return debug.warning("config is already setup by this or another script") end
                    pui.traverse(t, elemence.memorize)
                    is_setup = true
                    return t
                end
            end

            pui.save = function (...) return save(config, ...) end
            pui.load = function (...) load(config, ...) end
        end

        --#endregion

        -- #endregion
        --

        --
        -- #region : methods

        methods_mt.element = {
            __metatable = false,
            __type = "pui::element", __name = "pui::element",
            __tostring = function (self) return string.format("pui::element.%s \"%s\"", self[0].type, self.ref:name()) end,
            __eq = function (a, b) return __mt.element.__eq(a.ref, b.ref) end,
            __index = function (self, key)
                return rawget(methods_mt.element, key) or rawget(__mt.wrp_element, key) or rawget(self[1], key)
            end,
            __call = function (self, ...)
                return (#{...} == 0 and __mt.element.get or __mt.element.set)(self.ref, ...)
            end,

            --

            create = function (self)
                self[0].gear = self[0].gear or elemence.group(__mt.element.create(self.ref))
                return self[0].gear
            end,

            depend = function (self, ...)
                local arg = {...}
                local disabler = arg[1] == true

                local __depend = self.__depend[disabler and 2 or 1]
                for i = disabler and 2 or 1, table.maxn(arg) do
                    local v = arg[i]
                    if v then
                        if v.__name == "pui::element" then v = {v, true} end

                        v[0] = false
                        __depend[#__depend+1] = v

                        local check = function () elemence.dependant(__depend, self.ref, disabler) end
                        check()

                        __mt.element.set_callback(v[1].ref, check)
                    end
                end

                return self
            end,

            --

            name = function (self, s)
                if s then	__mt.element.name(self.ref, tools.format(s))
                else		return __mt.element.name(self.ref) end
            end,
            set_name = function (self, s)
                __mt.element.name(self.ref, tools.format(s))
            end,
            get_name = function (self)
                return __mt.element.name(self.ref)
            end,

            type = function (self) return self[0].type end,
            get_type = function (self) return self[0].type end,

            list = function (self)
                return __mt.element.list(self.ref)
            end,
            get_list = function (self)
                return __mt.element.list(self.ref)
            end,
            update = function (self, ...)
                __mt.element.update(self.ref, ...)

                if self[0].type == "list" or self[0].type == "listable" then
                    local value, list = __mt.element.get(self.ref), __mt.element.list(self.ref)
                    if not list then return end
                    local max = #list

                    if type(value) == "number" then
                        if value > max then
                            __mt.element.set(self.ref, max)
                            self.value = max
                        end
                    else
                        local id = table.ifind(list, value)

                        if id == nil or id > max then
                            __mt.element.set(self.ref, list[max])
                            self.value = list[max]
                        end
                    end
                end
            end,

            tooltip = function (self, t)
                if t then	__mt.element.tooltip(self.ref, tools.format(t))
                else		return __mt.element.tooltip(self.ref) end
            end,
            set_tooltip = function (self, t)
                __mt.element.tooltip(self.ref, tools.format(t))
            end,
            get_tooltip = function (self)
                return __mt.element.tooltip(self.ref)
            end,

            set_visible = function (self, v)
                __mt.element.visibility(self.ref, v)
            end,
            get_visible = function (self)
                __mt.element.visibility(self.ref)
            end,

            set_disabled = function (self, v)
                __mt.element.disabled(self.ref, v)
            end,
            get_disabled = function (self)
                __mt.element.disabled(self.ref)
            end,

            get_color = function (self)
                return rawget(self, "color") and self.color.value
            end,
            color_picker = function (self, default)
                self.color = elemence.new(__mt.element.color_picker(self.ref, default))

                return self.color
            end,

            set_event = function (self, event, fn, condition)
                if condition == nil then condition = true end
                local fncond, latest = type(condition) == "function", fn

                self[0].events[fn] = function ()
                    local permission

                    if fncond then permission = condition(self) and true or false
                    else permission = self.value == condition end

                    if latest ~= permission then
                        events[event](fn, permission)
                        latest = permission
                    end
                end
                self[0].events[fn]()
                __mt.element.set_callback(self.ref, self[0].events[fn])
            end,
            unset_event = function (self, event, fn)
                events[event].unset(events[event], fn)
                __mt.element.unset_callback(self.ref, self[0].events[fn])
                self[0].events[fn] = nil
            end,

            set_callback = function (self, fn, once)
                self[0].callbacks[fn] = function () fn(self) end
                __mt.element.set_callback(self.ref, self[0].callbacks[fn], once)
            end,
            unset_callback = function (self, fn)
                if self[0].callbacks[fn] then
                    __mt.element.unset_callback(self.ref, self[0].callbacks[fn])
                    self[0].callbacks[fn] = nil
                end
            end,

            override = function (self, ...)
                __mt.element.override(self.ref, ...)
            end,
            get_override = function (self)
                return __mt.element.get_override(self.ref)
            end,
        }

        methods_mt.group = {
            __name = "pui::group", __metatable = false,
            __index = function (self, key)
                return methods_mt.group[key] or (elements[key] and pui_mt.__index(self, key) or __mt.wrp_group[key])
            end,

            name = function (self, s, t)
                local ref = t == true and self.par or self.ref
                if s then	__mt.group.name(ref, tools.format(s))
                else		return __mt.group.name(ref) end
            end,
            set_name = function (self, s, t)
                __mt.group.name(t == true and self.par or self.ref, tools.format(s))
            end,
            get_name = function (self, t)
                return __mt.group.name(t == true and self.par or self.ref)
            end,

            disabled = function (self, b, t)
                local ref = t == true and self.par or self.ref
                if b ~= nil then   __mt.group.disabled(ref, b)
                else		return __mt.group.disabled(ref) end
            end,
            set_disabled = function (self, b, t)
                __mt.group.disabled(t == true and self.par or self.ref, b and true or false)
            end,
            get_disabled = function (self, t)
                return __mt.group.disabled(t == true and self.par or self.ref)
            end,

            set_visible = function (self, b)
                __mt.group.visibility(self.ref, b and true or false)
            end,
            get_visible = function (self)
                return __mt.group.visibility(self.ref)
            end,

            depend = methods_mt.element.depend
        }

        -- #endregion
        --

        --
        -- #region : pui_mt

        do
            local cached = {} for key in next, elements do
                cached[key] = function (origin, ...)
                    local is_child = origin.__name == "pui::group"
                    local group = is_child and origin.ref or groups[origin]

                    local args = elemence.dispense(key, ...)
                    local this = elemence.new( __mt.group[key]( group, unpack(args, 1, args.n < args.req and args.n or args.req) ) )

                    elemence.features(this, args.misc)

                    return this
                end
            end

            pui_mt.__metatable = false
            pui_mt.__name = "pui::basement"
            pui_mt.__index = function (self, key)
                if not elements[key] then return ui[key] end
                return cached[key]
            end
        end

        -- #endregion
        --


        -- #endregion ------------------------------------------------------------------
        --




        return setmetatable(pui, pui_mt) ---------------------------<  enQ • 1927  >----
    end,

["neverlose/smoothy"] = function(require)
        local native_GetTimescale = utils.get_vfunc('engine.dll', 'VEngineClient014', 91, 'float(__thiscall*)(void*)')

        local to_pairs = {
            vector = { 'x', 'y', 'z' },
            imcolor =  { 'r', 'g', 'b', 'a' }
        }

        local function get_type(value)
            local val_type = type(value)

            if val_type == 'userdata' and value.__type then
                return string.lower(value.__type.name)
            end

            if val_type == 'boolean' then
                value = value and 1 or 0
            end

            return val_type
        end

        local function copy_tables(destination, keysTable, valuesTable)
            valuesTable = valuesTable or keysTable
            local mt = getmetatable(keysTable)

            if mt and getmetatable(destination) == nil then
                setmetatable(destination, mt)
            end

            for k,v in pairs(keysTable) do
                if type(v) == 'table' then
                    destination[k] = copy_tables({}, v, valuesTable[k])
                else
                    local value = valuesTable[k]

                    if type(value) == 'boolean' then
                        value = value and 1 or 0
                    end

                    destination[k] = value
                end
            end

            return destination
        end

        local function resolve(easing_fn, previous, new, clock, duration)
            if type(new) == 'boolean' then new = new and 1 or 0 end
            if type(previous) == 'boolean' then previous = previous and 1 or 0 end

            local previous = easing_fn(clock, previous, new - previous, duration)

            if type(new) == 'number' then
                if math.abs(new-previous) <= .001 then
                    previous = new
                end

                if previous % 1 < .0001 then
                    previous = math.floor(previous)
                elseif previous % 1 > .9999 then
                    previous = math.ceil(previous)
                end
            end

            return previous
        end

        local function perform_easing(ntype, easing_fn, previous, new, clock, duration)
            if to_pairs[ntype] then
                for _, key in ipairs(to_pairs[ntype]) do
                    previous[key] = perform_easing(
                        type(v), easing_fn,
                        previous[key], new[key],
                        clock, duration
                    )
                end

                return previous
            end

            if ntype == 'table' then
                for k, v in pairs(new) do
                    previous[k] = previous[k] or v
                    previous[k] = perform_easing(
                        type(v), easing_fn,
                        previous[k], v,
                        clock, duration
                    )
                end

                return previous
            end

            return resolve(easing_fn, previous, new, clock, duration)
        end

        local adjusted_speed

        local new = function(default, easing_fn)
            if type(default) == 'boolean' then
                default = default and 1 or 0
            end

            local mt = { }
            local mt_data = {
                value = default or 0,
                easing = easing_fn or function(t, b, c, d)
                    return c * t / d + b
                end
            }

            function mt.update(self, duration, value, easing, ignore_adj_speed)
                if type(value) == 'boolean' then
                    value = value and 1 or 0
                end

                local clock = globals.frametime / native_GetTimescale()
                local duration = duration or .15
                local value_type = get_type(value)
                local target_type = get_type(self.value)

                assert(value_type == target_type, string.format('type mismatch. expected %s (received %s)', target_type, value_type))

                if self.value == value then
                    return value
                end

                if adjusted_speed and ignore_adj_speed ~= true then
                    duration = duration * adjusted_speed
                end

                if clock <= 0 or clock >= duration then
                    if target_type == 'imcolor' or target_type == 'vector' then
                        self.value = value:clone()
                    elseif target_type == 'table' then
                        copy_tables(self.value, value)
                    else
                        self.value = value
                    end
                else
                    local easing = easing or self.easing

                    self.value = perform_easing(
                        target_type, easing,
                        self.value, value,
                        clock, duration
                    )
                end

                return self.value
            end

            return setmetatable(mt, {
                __metatable = false,
                __call = mt.update,
                __index = mt_data
            })
        end

        local new_interp = function(initial_value)
            return setmetatable({
                previous = initial_value or 0
            }, {
                __call = function(self, new_value, mul)
                    local mul = mul or 1
                    local tickinterval = globals.tickinterval * mul
                    local difference = math.abs(new_value - self.previous)

                    if difference > 0 then
                        local clock = globals.frametime / native_GetTimescale()
                        local time = math.min(tickinterval, clock) / tickinterval

                        self.previous = self.previous + time * (new_value - self.previous)
                    else
                        self.previous = new_value
                    end

                    self.previous = (self.previous % 1 < .0001) and 0 or self.previous

                    return self.previous
                end
            })
        end

        local set_speed = function(new_speed)
            if new_speed == true then return adjusted_speed or 1 end
            if new_speed == nil then adjusted_speed = nil end

            if type(new_speed) == 'number' and new_speed >= 0 then
                adjusted_speed = new_speed
            end

            return adjusted_speed
        end

        return {
            new = new,
            new_interp = new_interp,
            set_speed = set_speed
        }
    end,

    ["ffi"] = function()
        return ffi
    end,

["neverlose/inspect"] = function(require)
local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local math = _tl_compat and _tl_compat.math or math; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; local type = type
local inspect = { Options = {} }

















inspect._VERSION = 'inspect.lua 3.1.0'
inspect._URL = 'http://github.com/kikito/inspect.lua'
inspect._DESCRIPTION = 'human-readable representations of tables'
inspect._LICENSE = [[
  MIT LICENSE

  Copyright (c) 2022 Enrique García Cota

  Permission is hereby granted, free of charge, to any person obtaining a
  copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to
  the following conditions:

  The above copyright notice and this permission notice shall be included
  in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]
inspect.KEY = setmetatable({}, { __tostring = function() return 'inspect.KEY' end })
inspect.METATABLE = setmetatable({}, { __tostring = function() return 'inspect.METATABLE' end })

local tostring = tostring
local rep = string.rep
local match = string.match
local char = string.char
local gsub = string.gsub
local fmt = string.format


local sbavailable, stringbuffer = pcall(require, "string.buffer")
local buffnew
local puts
local render

if sbavailable then
   buffnew = stringbuffer.new
   puts = function(buf, str)
      buf:put(str)
   end
   render = function(buf)
      return buf:get()
   end
else
   buffnew = function()
      return { n = 0 }
   end
   puts = function(buf, str)
      buf.n = buf.n + 1
      buf[buf.n] = str
   end
   render = function(buf)
      return table.concat(buf)
   end
end

local _rawget
if rawget then
   _rawget = rawget
else
   _rawget = function(t, k) return t[k] end
end

local function rawpairs(t)
   return next, t, nil
end



local function smartQuote(str)
   if match(str, '"') and not match(str, "'") then
      return "'" .. str .. "'"
   end
   return '"' .. gsub(str, '"', '\\"') .. '"'
end


local shortControlCharEscapes = {
   ["\a"] = "\\a", ["\b"] = "\\b", ["\f"] = "\\f", ["\n"] = "\\n",
   ["\r"] = "\\r", ["\t"] = "\\t", ["\v"] = "\\v", ["\127"] = "\\127",
}
local longControlCharEscapes = { ["\127"] = "\127" }
for i = 0, 31 do
   local ch = char(i)
   if not shortControlCharEscapes[ch] then
      shortControlCharEscapes[ch] = "\\" .. i
      longControlCharEscapes[ch] = fmt("\\%03d", i)
   end
end

local function escape(str)
   return (gsub(gsub(gsub(str, "\\", "\\\\"),
   "(%c)%f[0-9]", longControlCharEscapes),
   "%c", shortControlCharEscapes))
end

local luaKeywords = {}
for k in ([[ and break do else elseif end false for function goto if
             in local nil not or repeat return then true until while
]]):gmatch('%w+') do
   luaKeywords[k] = true
end

local function isIdentifier(str)
   return type(str) == "string" and
   not not str:match("^[_%a][_%a%d]*$") and
   not luaKeywords[str]
end

local flr = math.floor
local function isSequenceKey(k, sequenceLength)
   return type(k) == "number" and
   flr(k) == k and
   1 <= (k) and
   k <= sequenceLength
end

local defaultTypeOrders = {
   ['number'] = 1, ['boolean'] = 2, ['string'] = 3, ['table'] = 4,
   ['function'] = 5, ['userdata'] = 6, ['thread'] = 7,
}

local function sortKeys(a, b)
   local ta, tb = type(a), type(b)


   if ta == tb and (ta == 'string' or ta == 'number') then
      return (a) < (b)
   end

   local dta = defaultTypeOrders[ta] or 100
   local dtb = defaultTypeOrders[tb] or 100


   return dta == dtb and ta < tb or dta < dtb
end

local function getKeys(t)

   local seqLen = 1
   while _rawget(t, seqLen) ~= nil do
      seqLen = seqLen + 1
   end
   seqLen = seqLen - 1

   local keys, keysLen = {}, 0
   for k in rawpairs(t) do
      if not isSequenceKey(k, seqLen) then
         keysLen = keysLen + 1
         keys[keysLen] = k
      end
   end
   table.sort(keys, sortKeys)
   return keys, keysLen, seqLen
end

local function countCycles(x, cycles, depth)
   if type(x) == "table" then
      if cycles[x] then
         cycles[x] = cycles[x] + 1
      else
         cycles[x] = 1
         if depth > 0 then
            for k, v in rawpairs(x) do
               countCycles(k, cycles, depth - 1)
               countCycles(v, cycles, depth - 1)
            end
            countCycles(getmetatable(x), cycles, depth - 1)
         end
      end
   end
end

local function makePath(path, a, b)
   local newPath = {}
   local len = #path
   for i = 1, len do newPath[i] = path[i] end

   newPath[len + 1] = a
   newPath[len + 2] = b

   return newPath
end


local function processRecursive(process,
   item,
   path,
   visited)
   if item == nil then return nil end
   if visited[item] then return visited[item] end

   local processed = process(item, path)
   if type(processed) == "table" then
      local processedCopy = {}
      visited[item] = processedCopy
      local processedKey

      for k, v in rawpairs(processed) do
         processedKey = processRecursive(process, k, makePath(path, k, inspect.KEY), visited)
         if processedKey ~= nil then
            processedCopy[processedKey] = processRecursive(process, v, makePath(path, processedKey), visited)
         end
      end

      local mt = processRecursive(process, getmetatable(processed), makePath(path, inspect.METATABLE), visited)
      if type(mt) ~= 'table' then mt = nil end
      setmetatable(processedCopy, mt)
      processed = processedCopy
   end
   return processed
end



local Inspector = {}










local Inspector_mt = { __index = Inspector }

local function tabify(inspector)
   puts(inspector.buf, inspector.newline .. rep(inspector.indent, inspector.level))
end

function Inspector:getId(v)
   local id = self.ids[v]
   local ids = self.ids
   if not id then
      local tv = type(v)
      id = (ids[tv] or 0) + 1
      ids[v], ids[tv] = id, id
   end
   return tostring(id)
end

function Inspector:putValue(v)
   local buf = self.buf
   local tv = type(v)
   if tv == 'string' then
      puts(buf, smartQuote(escape(v)))
   elseif tv == 'number' or tv == 'boolean' or tv == 'nil' or
      tv == 'cdata' or tv == 'ctype' then
      puts(buf, tostring(v))
   elseif tv == 'table' and not self.ids[v] then
      local t = v

      if t == inspect.KEY or t == inspect.METATABLE then
         puts(buf, tostring(t))
      elseif self.level >= self.depth then
         puts(buf, '{...}')
      else
         if self.cycles[t] > 1 then puts(buf, fmt('<%d>', self:getId(t))) end

         local keys, keysLen, seqLen = getKeys(t)

         puts(buf, '{')
         self.level = self.level + 1

         for i = 1, seqLen + keysLen do
            if i > 1 then puts(buf, ',') end
            if i <= seqLen then
               puts(buf, ' ')
               self:putValue(t[i])
            else
               local k = keys[i - seqLen]
               tabify(self)
               if isIdentifier(k) then
                  puts(buf, k)
               else
                  puts(buf, "[")
                  self:putValue(k)
                  puts(buf, "]")
               end
               puts(buf, ' = ')
               self:putValue(t[k])
            end
         end

         local mt = getmetatable(t)
         if type(mt) == 'table' then
            if seqLen + keysLen > 0 then puts(buf, ',') end
            tabify(self)
            puts(buf, '<metatable> = ')
            self:putValue(mt)
         end

         self.level = self.level - 1

         if keysLen > 0 or type(mt) == 'table' then
            tabify(self)
         elseif seqLen > 0 then
            puts(buf, ' ')
         end

         puts(buf, '}')
      end

   else
      puts(buf, fmt('<%s %d>', tv, self:getId(v)))
   end
end




function inspect.inspect(root, options)
   options = options or {}

   local depth = options.depth or (math.huge)
   local newline = options.newline or '\n'
   local indent = options.indent or '  '
   local process = options.process

   if process then
      root = processRecursive(process, root, {}, {})
   end

   local cycles = {}
   countCycles(root, cycles, depth)

   local inspector = setmetatable({
      buf = buffnew(),
      ids = {},
      cycles = cycles,
      depth = depth,
      level = 0,
      newline = newline,
      indent = indent,
   }, Inspector_mt)

   inspector:putValue(root)

   return render(inspector.buf)
end

setmetatable(inspect, {
   __call = function(_, root, options)
      return inspect.inspect(root, options)
   end,
})

return inspect
end,
    ["neverlose/easing"] = function(require)
        local tween = {
  _VERSION     = 'tween 2.1.1',
  _DESCRIPTION = 'tweening for lua',
  _URL         = 'https://github.com/kikito/tween.lua',
  _LICENSE     = [[
    MIT LICENSE

    Copyright (c) 2014 Enrique García Cota, Yuichi Tateno, Emmanuel Oga

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
}

-- easing

-- Adapted from https://github.com/EmmanuelOga/easing. See LICENSE.txt for credits.
-- For all easing functions:
-- t = time == how much time has to pass for the tweening to complete
-- b = begin == starting property value
-- c = change == ending - beginning
-- d = duration == running time. How much time has passed *right now*

local pow, sin, cos, pi, sqrt, abs, asin = math.pow, math.sin, math.cos, math.pi, math.sqrt, math.abs, math.asin

-- linear
local function linear(t, b, c, d) return c * t / d + b end

-- quad
local function inQuad(t, b, c, d) return c * pow(t / d, 2) + b end
local function outQuad(t, b, c, d)
  t = t / d
  return -c * t * (t - 2) + b
end
local function inOutQuad(t, b, c, d)
  t = t / d * 2
  if t < 1 then return c / 2 * pow(t, 2) + b end
  return -c / 2 * ((t - 1) * (t - 3) - 1) + b
end
local function outInQuad(t, b, c, d)
  if t < d / 2 then return outQuad(t * 2, b, c / 2, d) end
  return inQuad((t * 2) - d, b + c / 2, c / 2, d)
end

-- cubic
local function inCubic (t, b, c, d) return c * pow(t / d, 3) + b end
local function outCubic(t, b, c, d) return c * (pow(t / d - 1, 3) + 1) + b end
local function inOutCubic(t, b, c, d)
  t = t / d * 2
  if t < 1 then return c / 2 * t * t * t + b end
  t = t - 2
  return c / 2 * (t * t * t + 2) + b
end
local function outInCubic(t, b, c, d)
  if t < d / 2 then return outCubic(t * 2, b, c / 2, d) end
  return inCubic((t * 2) - d, b + c / 2, c / 2, d)
end

-- quart
local function inQuart(t, b, c, d) return c * pow(t / d, 4) + b end
local function outQuart(t, b, c, d) return -c * (pow(t / d - 1, 4) - 1) + b end
local function inOutQuart(t, b, c, d)
  t = t / d * 2
  if t < 1 then return c / 2 * pow(t, 4) + b end
  return -c / 2 * (pow(t - 2, 4) - 2) + b
end
local function outInQuart(t, b, c, d)
  if t < d / 2 then return outQuart(t * 2, b, c / 2, d) end
  return inQuart((t * 2) - d, b + c / 2, c / 2, d)
end

-- quint
local function inQuint(t, b, c, d) return c * pow(t / d, 5) + b end
local function outQuint(t, b, c, d) return c * (pow(t / d - 1, 5) + 1) + b end
local function inOutQuint(t, b, c, d)
  t = t / d * 2
  if t < 1 then return c / 2 * pow(t, 5) + b end
  return c / 2 * (pow(t - 2, 5) + 2) + b
end
local function outInQuint(t, b, c, d)
  if t < d / 2 then return outQuint(t * 2, b, c / 2, d) end
  return inQuint((t * 2) - d, b + c / 2, c / 2, d)
end

-- sine
local function inSine(t, b, c, d) return -c * cos(t / d * (pi / 2)) + c + b end
local function outSine(t, b, c, d) return c * sin(t / d * (pi / 2)) + b end
local function inOutSine(t, b, c, d) return -c / 2 * (cos(pi * t / d) - 1) + b end
local function outInSine(t, b, c, d)
  if t < d / 2 then return outSine(t * 2, b, c / 2, d) end
  return inSine((t * 2) -d, b + c / 2, c / 2, d)
end

-- expo
local function inExpo(t, b, c, d)
  if t == 0 then return b end
  return c * pow(2, 10 * (t / d - 1)) + b - c * 0.001
end
local function outExpo(t, b, c, d)
  if t == d then return b + c end
  return c * 1.001 * (-pow(2, -10 * t / d) + 1) + b
end
local function inOutExpo(t, b, c, d)
  if t == 0 then return b end
  if t == d then return b + c end
  t = t / d * 2
  if t < 1 then return c / 2 * pow(2, 10 * (t - 1)) + b - c * 0.0005 end
  return c / 2 * 1.0005 * (-pow(2, -10 * (t - 1)) + 2) + b
end
local function outInExpo(t, b, c, d)
  if t < d / 2 then return outExpo(t * 2, b, c / 2, d) end
  return inExpo((t * 2) - d, b + c / 2, c / 2, d)
end

-- circ
local function inCirc(t, b, c, d) return(-c * (sqrt(1 - pow(t / d, 2)) - 1) + b) end
local function outCirc(t, b, c, d)  return(c * sqrt(1 - pow(t / d - 1, 2)) + b) end
local function inOutCirc(t, b, c, d)
  t = t / d * 2
  if t < 1 then return -c / 2 * (sqrt(1 - t * t) - 1) + b end
  t = t - 2
  return c / 2 * (sqrt(1 - t * t) + 1) + b
end
local function outInCirc(t, b, c, d)
  if t < d / 2 then return outCirc(t * 2, b, c / 2, d) end
  return inCirc((t * 2) - d, b + c / 2, c / 2, d)
end

-- elastic
local function calculatePAS(p,a,c,d)
  p, a = p or d * 0.3, a or 0
  if a < abs(c) then return p, c, p / 4 end -- p, a, s
  return p, a, p / (2 * pi) * asin(c/a) -- p,a,s
end
local function inElastic(t, b, c, d, a, p)
  local s
  if t == 0 then return b end
  t = t / d
  if t == 1  then return b + c end
  p,a,s = calculatePAS(p,a,c,d)
  t = t - 1
  return -(a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b
end
local function outElastic(t, b, c, d, a, p)
  local s
  if t == 0 then return b end
  t = t / d
  if t == 1 then return b + c end
  p,a,s = calculatePAS(p,a,c,d)
  return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p) + c + b
end
local function inOutElastic(t, b, c, d, a, p)
  local s
  if t == 0 then return b end
  t = t / d * 2
  if t == 2 then return b + c end
  p,a,s = calculatePAS(p,a,c,d)
  t = t - 1
  if t < 0 then return -0.5 * (a * pow(2, 10 * t) * sin((t * d - s) * (2 * pi) / p)) + b end
  return a * pow(2, -10 * t) * sin((t * d - s) * (2 * pi) / p ) * 0.5 + c + b
end
local function outInElastic(t, b, c, d, a, p)
  if t < d / 2 then return outElastic(t * 2, b, c / 2, d, a, p) end
  return inElastic((t * 2) - d, b + c / 2, c / 2, d, a, p)
end

-- back
local function inBack(t, b, c, d, s)
  s = s or 1.70158
  t = t / d
  return c * t * t * ((s + 1) * t - s) + b
end
local function outBack(t, b, c, d, s)
  s = s or 1.70158
  t = t / d - 1
  return c * (t * t * ((s + 1) * t + s) + 1) + b
end
local function inOutBack(t, b, c, d, s)
  s = (s or 1.70158) * 1.525
  t = t / d * 2
  if t < 1 then return c / 2 * (t * t * ((s + 1) * t - s)) + b end
  t = t - 2
  return c / 2 * (t * t * ((s + 1) * t + s) + 2) + b
end
local function outInBack(t, b, c, d, s)
  if t < d / 2 then return outBack(t * 2, b, c / 2, d, s) end
  return inBack((t * 2) - d, b + c / 2, c / 2, d, s)
end

-- bounce
local function outBounce(t, b, c, d)
  t = t / d
  if t < 1 / 2.75 then return c * (7.5625 * t * t) + b end
  if t < 2 / 2.75 then
    t = t - (1.5 / 2.75)
    return c * (7.5625 * t * t + 0.75) + b
  elseif t < 2.5 / 2.75 then
    t = t - (2.25 / 2.75)
    return c * (7.5625 * t * t + 0.9375) + b
  end
  t = t - (2.625 / 2.75)
  return c * (7.5625 * t * t + 0.984375) + b
end
local function inBounce(t, b, c, d) return c - outBounce(d - t, 0, c, d) + b end
local function inOutBounce(t, b, c, d)
  if t < d / 2 then return inBounce(t * 2, 0, c, d) * 0.5 + b end
  return outBounce(t * 2 - d, 0, c, d) * 0.5 + c * .5 + b
end
local function outInBounce(t, b, c, d)
  if t < d / 2 then return outBounce(t * 2, b, c / 2, d) end
  return inBounce((t * 2) - d, b + c / 2, c / 2, d)
end

tween.easing = {
  linear    = linear,
  inQuad    = inQuad,    outQuad    = outQuad,    inOutQuad    = inOutQuad,    outInQuad    = outInQuad,
  inCubic   = inCubic,   outCubic   = outCubic,   inOutCubic   = inOutCubic,   outInCubic   = outInCubic,
  inQuart   = inQuart,   outQuart   = outQuart,   inOutQuart   = inOutQuart,   outInQuart   = outInQuart,
  inQuint   = inQuint,   outQuint   = outQuint,   inOutQuint   = inOutQuint,   outInQuint   = outInQuint,
  inSine    = inSine,    outSine    = outSine,    inOutSine    = inOutSine,    outInSine    = outInSine,
  inExpo    = inExpo,    outExpo    = outExpo,    inOutExpo    = inOutExpo,    outInExpo    = outInExpo,
  inCirc    = inCirc,    outCirc    = outCirc,    inOutCirc    = inOutCirc,    outInCirc    = outInCirc,
  inElastic = inElastic, outElastic = outElastic, inOutElastic = inOutElastic, outInElastic = outInElastic,
  inBack    = inBack,    outBack    = outBack,    inOutBack    = inOutBack,    outInBack    = outInBack,
  inBounce  = inBounce,  outBounce  = outBounce,  inOutBounce  = inOutBounce,  outInBounce  = outInBounce
}



-- private stuff

local function copyTables(destination, keysTable, valuesTable)
  valuesTable = valuesTable or keysTable
  local mt = getmetatable(keysTable)
  if mt and getmetatable(destination) == nil then
    setmetatable(destination, mt)
  end
  for k,v in pairs(keysTable) do
    if type(v) == 'table' then
      destination[k] = copyTables({}, v, valuesTable[k])
    else
      destination[k] = valuesTable[k]
    end
  end
  return destination
end

local function checkSubjectAndTargetRecursively(subject, target, path)
  path = path or {}
  local targetType, newPath
  for k,targetValue in pairs(target) do
    targetType, newPath = type(targetValue), copyTables({}, path)
    table.insert(newPath, tostring(k))
    if targetType == 'number' then
      assert(type(subject[k]) == 'number', "Parameter '" .. table.concat(newPath,'/') .. "' is missing from subject or isn't a number")
    elseif targetType == 'table' then
      checkSubjectAndTargetRecursively(subject[k], targetValue, newPath)
    else
      assert(targetType == 'number', "Parameter '" .. table.concat(newPath,'/') .. "' must be a number or table of numbers")
    end
  end
end

local function checkNewParams(duration, subject, target, easing)
  assert(type(duration) == 'number' and duration > 0, "duration must be a positive number. Was " .. tostring(duration))
  local tsubject = type(subject)
  assert(tsubject == 'table' or tsubject == 'userdata', "subject must be a table or userdata. Was " .. tostring(subject))
  assert(type(target)== 'table', "target must be a table. Was " .. tostring(target))
  assert(type(easing)=='function', "easing must be a function. Was " .. tostring(easing))
  checkSubjectAndTargetRecursively(subject, target)
end

local function getEasingFunction(easing)
  easing = easing or "linear"
  if type(easing) == 'string' then
    local name = easing
    easing = tween.easing[name]
    if type(easing) ~= 'function' then
      error("The easing function name '" .. name .. "' is invalid")
    end
  end
  return easing
end

local function performEasingOnSubject(subject, target, initial, clock, duration, easing)
  local t,b,c,d
  for k,v in pairs(target) do
    if type(v) == 'table' then
      performEasingOnSubject(subject[k], v, initial[k], clock, duration, easing)
    else
      t,b,c,d = clock, initial[k], v - initial[k], duration
      subject[k] = easing(t,b,c,d)
    end
  end
end

-- Tween methods

local Tween = {}
local Tween_mt = {__index = Tween}

function Tween:set(clock)
  assert(type(clock) == 'number', "clock must be a positive number or 0")

  self.initial = self.initial or copyTables({}, self.target, self.subject)
  self.clock = clock

  if self.clock <= 0 then

    self.clock = 0
    copyTables(self.subject, self.initial)

  elseif self.clock >= self.duration then -- the tween has expired

    self.clock = self.duration
    copyTables(self.subject, self.target)

  else

    performEasingOnSubject(self.subject, self.target, self.initial, self.clock, self.duration, self.easing)

  end

  return self.clock >= self.duration
end

function Tween:reset()
  return self:set(0)
end

function Tween:update(dt)
  assert(type(dt) == 'number', "dt must be a number")
  return self:set(self.clock + dt)
end


-- Public interface

function tween.new(duration, subject, target, easing)
  easing = getEasingFunction(easing)
  checkNewParams(duration, subject, target, easing)
  return setmetatable({
    duration  = duration,
    subject   = subject,
    target    = target,
    easing    = easing,
    clock     = 0
  }, Tween_mt)
end

return tween
end;
}

local loaded = {}
local loading = {}
local custom_require

local function make_env(modname)
    return setmetatable({ require = custom_require, _MODULE = modname }, { __index = _G })
end

local function load_embedded_module(lib, def)
    if loaded[lib] ~= nil then return loaded[lib] end
    if loading[lib] then error("circular require detected for module: " .. lib, 2) end
    loading[lib] = true

    local ret
    local t = type(def)
    if t == "function" then
        local ok, result = pcall(def, custom_require, lib)
        loading[lib] = nil
        if not ok then error(("failed to load module '%s': %s"):format(lib, tostring(result)), 2) end
        ret = result
    elseif t == "table" then
        loading[lib] = nil
        ret = def
    elseif t == "string" then
        if not compiler then
            loading[lib] = nil
            error(("module '%s' is stored as source string, but load/loadstring is unavailable"):format(lib), 2)
        end
        local chunk, err = compiler(def, "@" .. lib)
        if not chunk then
            loading[lib] = nil
            error(("failed to compile module '%s': %s"):format(lib, tostring(err)), 2)
        end
        if setfenv then setfenv(chunk, make_env(lib)) end
        local ok, result = pcall(chunk, lib)
        loading[lib] = nil
        if not ok then error(("failed to load module '%s': %s"):format(lib, tostring(result)), 2) end
        ret = result
    else
        loading[lib] = nil
        error(("unsupported embedded module type for '%s': %s"):format(lib, t), 2)
    end
    if ret == nil then ret = true end
    loaded[lib] = ret
    return ret
end

custom_require = function(lib)
    if lib == "ffi" then
        return ffi
    end
    local def = modules[lib]
    if def ~= nil then
        return load_embedded_module(lib, def)
    end
    return error("require: " .. lib)
end

require = custom_require

--original code below

local pui = require("neverlose/pui");
local base64 = require("neverlose/base64");
local clipboard = require("neverlose/clipboard");
local inspect = require("neverlose/inspect");
local smoothy = require("neverlose/smoothy");
local easing = require("neverlose/easing")

local last_update = 1747063995;
--print(common.get_unixtime())
local reference do
    reference = { }

    reference.rage = {
        main = {
            dormant_aimbot = ui.find("Aimbot", "Ragebot", "Main", "Enabled", "Dormant Aimbot"),

            hide_shots = ui.find("Aimbot", "Ragebot", "Main", "Hide Shots"),
            hide_shots_options = ui.find("Aimbot", "Ragebot", "Main", "Hide Shots", "Options"),

            double_tap = ui.find("Aimbot", "Ragebot", "Main", "Double Tap"),
            double_tap_lag_options = ui.find("Aimbot", "Ragebot", "Main", "Double Tap", "Lag Options"),

            peek_assist = {
                ui.find("Aimbot", "Ragebot", "Main", "Peek Assist"),
                ui.find("Aimbot", "Ragebot", "Main", "Peek Assist", "Style"),
                ui.find("Aimbot", "Ragebot", "Main", "Peek Assist", "Auto Stop"),
                ui.find("Aimbot", "Ragebot", "Main", "Peek Assist", "Retreat Mode")
            }
        },

        selection = {
            hit_chance = ui.find("Aimbot", "Ragebot", "Selection", "Hit Chance"),
            minimum_damage = ui.find("Aimbot", "Ragebot", "Selection", "Min. Damage"),
            safe_points = ui.find("Aimbot", "Ragebot", "Safety", "Safe Points"),
            body_aim = ui.find("Aimbot", "Ragebot", "Safety", "Body Aim")
        }
    }

    reference.antiaim = {
        angles = {
            enabled = ui.find("Aimbot", "Anti Aim", "Angles", "Enabled"),
            pitch = ui.find("Aimbot", "Anti Aim", "Angles", "Pitch"),

            yaw = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw"),
            yaw_base = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Base"),
            yaw_add = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Offset"),
            avoid_backstab = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Avoid Backstab"),
            hidden = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw", "Hidden"),

            yaw_modifier = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier"),
            modifier_offset = ui.find("Aimbot", "Anti Aim", "Angles", "Yaw Modifier", "Offset"),

            body_yaw = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw"),
            inverter = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Inverter"),
            left_limit = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Left Limit"),
            right_limit = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Right Limit"),
            options = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Options"),
            freestanding_body_yaw = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Freestanding"),

            freestanding = ui.find("Aimbot", "Anti Aim", "Angles", "Freestanding"),
            freestand_peek = ui.find("Aimbot", "Anti Aim", "Angles", "Body Yaw", "Freestanding"),
            disable_yaw_modifiers = ui.find("Aimbot", "Anti Aim", "Angles", "Freestanding", "Disable Yaw Modifiers"),
            body_freestanding = ui.find("Aimbot", "Anti Aim", "Angles", "Freestanding", "Body Freestanding"),

            extended_angles = ui.find("Aimbot", "Anti Aim", "Angles", "Extended Angles"),
            extended_pitch = ui.find("Aimbot", "Anti Aim", "Angles", "Extended Angles", "Extended Pitch"),
            extended_roll = ui.find("Aimbot", "Anti Aim", "Angles", "Extended Angles", "Extended Roll")
        },

        fake_lag = {
            enabled = ui.find("Aimbot", "Anti Aim", "Fake Lag", "Enabled"),
            limit = ui.find("Aimbot", "Anti Aim", "Fake Lag", "Limit")
        },

        misc = {
            fake_duck = ui.find("Aimbot", "Anti Aim", "Misc", "Fake Duck"),
            slow_walk = ui.find("Aimbot", "Anti Aim", "Misc", "Slow Walk"),
            leg_movement = ui.find("Aimbot", "Anti Aim", "Misc", "Leg Movement")
        }
    }

    reference.ping_spike = ui.find("Miscellaneous", "Main", "Other", "Fake Latency")
end

local e_num = {
    states = {
        "Standing", "Running", "Slowing", "Crouching", "Sneaking", "Air", "Air Crouching", "Legit AA", "Freestanding"
    },

    teams = {
        "T", "CT"
    }
}

local log = {}; do
    function log:message(msg)
        print_raw(
            string.format('[\a%sgazolina\aDEFAULT] %s', ui.get_style()["Link Active"]:to_hex(), msg)
        )

    end

    function log:error(msg)
        print_raw(
            string.format('[\a%sgazolina\aDEFAULT] \aFF3E3EFF%s', ui.get_style()["Link Active"]:to_hex(), msg)
        )
    end

end

local screen = render.screen_size();

local windows = {}; do
    function windows:new(name, initial_pos)
        local initial_pos = initial_pos or vector();
        local group = ui.create("DRAGGING$$$)$)$)$");
        local mt = {};
        local mt_data = {
            dragging = false,
            mouse_pos = vector(0, 0),
            mouse_pos_diff = vector(0, 0),
            intersected = nil,

            size = vector(0, 0),
            position = vector(0, 0),

            reference = (function()
                local dragging_vector = {
                    group:slider(('%s:dragging_x'):format(name), -16384, 16384, initial_pos.x),
                    group:slider(('%s:dragging_y'):format(name), -16384, 16384, initial_pos.y)
                }

                dragging_vector[1]:visibility(false)
                dragging_vector[2]:visibility(false)

                return dragging_vector
            end)()
        }

        function mt.intersects(self, mouse, pos, size)
            return
                mouse.x >= pos.x and mouse.x <= pos.x+size.x and
                mouse.y >= pos.y and mouse.y <= pos.y+size.y
        end

        function mt.set_position(self, vec)
            self.reference[1]:set(vec.x);
            self.reference[2]:set(vec.y);
        end

        function mt.is_dragging(self)
            return self.dragging
        end

        function mt.update(self, size)
            local new_mouse_pos = ui.get_mouse_position()
            local menu_pos = ui.get_position()
            local menu_size = ui.get_size()

            local holding_key, intersection_check =
                ui.get_alpha() > 0 and common.is_button_down(1),
                self:intersects(new_mouse_pos, self.position, size) and not
                self:intersects(new_mouse_pos, menu_pos, menu_size)

            self.mouse_pos_diff = -(self.mouse_pos-new_mouse_pos)

            if holding_key and self.intersected == nil then
                self.intersected = intersection_check
            end

            if holding_key and self.intersected then
                self.dragging = true
            elseif not holding_key then
                self.dragging = false
                self.intersected = nil
            end

            if self.dragging then
                local limit, new_pos = size * .5, vector(
                    self.reference[1]:get() + self.mouse_pos_diff.x,
                    self.reference[2]:get() + self.mouse_pos_diff.y
                )

                self.reference[1]:set(math.max(-limit.x, math.min(screen.x-limit.x, new_pos.x)))
                self.reference[2]:set(math.max(-limit.y, math.min(screen.y-limit.y, new_pos.y)))
            end

            local pos = vector(
                self.reference[1]:get(),
                self.reference[2]:get()
            )

            self.mouse_pos = new_mouse_pos
            self.size = size;
            self.position = pos;
        end

        return setmetatable(mt, { __index = mt_data })
    end
end

local cvars = {}; do
    function cvars:get_original(convar)
        return tonumber(convar:string())
    end
end

local text_effects = {}; do
    function text_effects:animate(speed, from, to, text)
        if not text or text:gsub(" ", "") == "" then 
            return text
        end
    
        local output = ""
        local time = globals.realtime * speed
        local i = 1
        local len = #text
    
        while i <= len do
            local byte1 = text:byte(i)
            local is_cyrillic = (byte1 == 0xD0 or byte1 == 0xD1) and text:byte(i + 1)
    
            if is_cyrillic then
                local char = text:sub(i, i + 1)
                local index = (math.sin(time + i / 3) + 1) / 2
                local accent = from:lerp(to, math.clamp(index, 0, 1)):to_hex()
                output = output .. "\a" .. accent .. char -- фикс русских символов братик
                i = i + 2
            else
                local index = (math.sin(time + i / 3) + 1) / 2
                local accent = from:lerp(to, math.clamp(index, 0, 1)):to_hex()
                output = output .. "\a" .. accent .. text:sub(i, i)
                i = i + 1
            end
        end
    
        return output
    end

    function text_effects:format(icon, text, pre_spaces, post_spaces, post_post_spaces, icon_color)
        pre_spaces = pre_spaces or 0
        post_spaces = post_spaces or 0 
        post_post_spaces = post_post_spaces or 0
        text = text or "ERROR"

        local space = "\xE2\x80\x8A"

        local get = ui.get_icon(icon);
        local clean = string.gsub(get, " ", "")

        if clean == "" then
            get = icon;
        end

        if icon_color then
            get = "\a" .. icon_color .. get .. "\r"
        else
            get = "\v" .. get .. "\r"
        end

        return string.rep(space, pre_spaces)  .. get .. string.rep(space, post_spaces) .. text .. string.rep(space, post_post_spaces)
    end

    function text_effects:colored(...)
        local output = "";
        
        for key, value in pairs({...}) do
            local accent = value[2];
            local text = value[1];

            output = output .. "\a" .. accent:to_hex() .. text;
        end

        return output;
    end
end

local keybinds = {}; do
    function keybinds:get_state(name)
        local value, active = 0, false
        local binds = ui.get_binds()
        
        for i = 1, #binds do
            local bind = binds[i]
            if bind.name == name then
                value = bind.value
                active = bind.active
                break
            end
        end

        return {value, active}
    end
end

local menu = {}; do
    local interpoint = "•";

    local info = {}; do
        
        local groups = {
            pui.create(text_effects:format("house", "", 0, 0, 0), " ", 1),
            pui.create(text_effects:format("house", "", 0, 0, 0), "", 1),
            pui.create(text_effects:format("house", "", 0, 0, 0), "  ", 1)
        }

        groups[1]:list("", {text_effects:format("user", "About", 1, 8)})
        groups[2]:label(text_effects:format("triangle-exclamation", "This script was fixed by 2k00 and adapted to neverlose free crack , your welcome dx17 ;)", 1, 3, 0, "aeae61ff"))
        groups[2]:label(text_effects:format("bug", "Report Bugs", 1, 3, 0, "DEFAULT"))
        groups[2]:button(text_effects:format("discord", "Discord Server", 1, 2), function() panorama.SteamOverlayAPI.OpenExternalBrowserURL("https://discord.gg/QwJx52dPSe") end, true)
        groups[2]:button(text_effects:format("", "🦫 Sata Config", 0, 2), function() panorama.SteamOverlayAPI.OpenExternalBrowserURL("https://ru.neverlose.cc/market/item?id=ojYbuQ") end, true)
        groups[2]:button(text_effects:format("youtube", "Sata's YouTube", 0, 2), function() panorama.SteamOverlayAPI.OpenExternalBrowserURL("https://www.youtube.com/channel/UCN5jetnEx5fkG7Cdr0iYh4g") end, true)

        groups[3]:label(text_effects:format("user", "Welcome back, \v" .. common.get_username(), 0, 8));
        groups[3]:label(text_effects:format("code-branch", "Last update: " .. "\v" .. common.get_date("%m/%d %H:%M", last_update) ..  "\r", 0, 8));


        local group = pui.create(text_effects:format("house", "", 0, 0, 0), "Settings", 1)

        local sidebar = {}; do
            sidebar.label = group:label(text_effects:format(interpoint, "Sidebar", 2, 2, 2))
            local gear = sidebar.label:create();

            sidebar.text = gear:input("Text", _G.SCRIPT_NAME)
            sidebar.color = gear:color_picker(text_effects:format(interpoint, "Color", 5, 5, 5), {
                ["Inner"] = { color(175, 255, 55, 255) },
                ["Outter"] = { color(35, 128, 255, 255) }
            })
            sidebar.speed = gear:slider(text_effects:format(interpoint, "Speed", 5, 5, 5), 1, 32, 4)
            info.sidebar = sidebar;
        end

        local watermark = {}; do
            watermark.label = group:label(text_effects:format(interpoint, "Watermark", 2, 2, 2))
            local gear = watermark.label:create();

            watermark.mode = gear:listable("Options", {
                "Customizable Text",
                "Customizable Color",
                "Customizable Font"
            })

            watermark.text = gear:input("Text", _G.SCRIPT_NAME):depend({watermark.mode, 1})
            watermark.gradient = gear:switch(text_effects:format(interpoint, "Gradient", 2, 2, 2)):depend({watermark.mode, 2})
            watermark.color = gear:color_picker(text_effects:format(interpoint, "Color", 5, 5, 5), {
                ["Inner"] = { color(175, 255, 55, 255) },
                ["Outter"] = { color(35, 128, 255, 255) }
            }):depend({watermark.mode, 2}, {watermark.gradient, true})
            watermark.speed = gear:slider(text_effects:format(interpoint, "Speed", 5, 5, 5), 1, 32, 4):depend({watermark.mode, 2}, {watermark.gradient, true})
            watermark.non_gradient = gear:color_picker(text_effects:format(interpoint, "Color", 2, 2, 2)):depend({watermark.mode, 2}, {watermark.gradient, false})
            watermark.font = gear:combo(text_effects:format(interpoint, "Font", 2, 2, 2), {"Default", "Small", "Console", "Bold"}):depend({watermark.mode, 3})

            info.watermark = watermark;
        end
        
        local notify = {}; do
            notify.label = group:label(text_effects:format(interpoint, "Notifications", 2, 2, 2))
            local gear = notify.label:create();

            notify.style = gear:combo(text_effects:format(interpoint, "Mode", 15, 2, 2), {"Cat"})

            notify.text_color = gear:color_picker(text_effects:format(interpoint, "Text Color", 15, 2, 2), color())
            notify.border_color = gear:color_picker(text_effects:format(interpoint, "Border Color", 15, 2, 2), color())

            notify.spam = gear:switch(text_effects:format(" ", "Test Notification", 25, 15, 35))

            info.notify = notify;
        end

        local presets = {}; do
            local delete_state = {
                false, false
            }
            
            local group = pui.create(text_effects:format("house", "", 0, 0, 0), "Presets", 2);

            presets.list = group:list(text_effects:format("list", "List of available configs", 1, 2, 1), {});
            
            presets.name = group:input(text_effects:format("pen", "Name", 1, 2, 1), "")
            presets.create = group:button(text_effects:format("paste", "", 0, 0, 0, "00BCD4ff"), nil, true);
            presets.create:tooltip("Create preset.")

            presets.load = group:button(text_effects:format("upload", "", 0, 0, 0, "3F51B5ff"), nil, true);
            presets.load:tooltip("Load selected preset.")

            presets.save = group:button(text_effects:format("floppy-disk", "", 0, 0, 0, "388E3Cff"), nil, true);
            presets.save:tooltip("Save selected preset.")

            presets.import = group:button(text_effects:format("file-import", "", 0, 0, 0, "4CAF50ff"), nil, true);
            presets.import:tooltip("Import new preset.")

            presets.export = group:button(text_effects:format("file-export", "", 0, 0, 0, "2196F3ff"), nil, true);
            presets.export:tooltip("Export selected preset.")
            
            local hidden_switch = group:switch(" ", false)
            hidden_switch:visibility(false);


            presets.delete = group:button(text_effects:format("trash", "", 0, 0, 0, "ff0000ff"), function() 
                hidden_switch:set(true);
            end):depend({hidden_switch, false})

            presets.delete_confirm = group:button(text_effects:format("trash-check", "", 0, 0, 0, "45ec4aff"), function()
                hidden_switch:set(false)
            end):depend({hidden_switch, true})

            presets.delete_cancel = group:button(text_effects:format("trash-xmark", "", 0, 0, 0, "ff0000ff"), function() 
                hidden_switch:set(false)
            end):depend({hidden_switch, true})
            
            local information = {}; do
                local group = pui.create(text_effects:format("house", "", 0, 0, 0), "Presets", 2);
                
                information.creator = group:label("Author: \v...")
                presets.information = information
            end
            
            info.presets = presets;
        end

        menu.info = info
    end

    local antiaim = {}; do

        local main = {}; do

            local configure = {}; do
                local group = pui.create(text_effects:format("list-tree", "", 0, 0, 0), "Selection", 1);

                configure.team = group:list(text_effects:format("", "", 0, 0, 0), {
                    "\aFF0000FF" .. interpoint .. "\r  T", "\a8698fdff" .. interpoint .. "\r  CT"
                });

                


                configure.state = group:list(text_effects:format("users", "Select the state you want to change.", 2, 2, 2), e_num.states)

                main.configure = configure
            end

            local additional = {}; do
                local group = pui.create(text_effects:format("list-tree", "", 0, 0, 0), "Tweaks", 1);

                local legit_aa = {}; do
                    legit_aa.enabled = group:switch(text_effects:format("face-zany", "Legit AA", 2, 2, 2));

                    local gear = legit_aa.enabled:create();
                    legit_aa.mode = gear:combo(text_effects:format(interpoint, "Yaw Base", 2, 2, 2), {"Local View", "At Target"}):depend({legit_aa.enabled, true});
                
                    additional.legit_aa = legit_aa;
                end

                local manual_yaw = {}; do
                    manual_yaw.select = group:combo(text_effects:format("rotate", "Manual Yaw", 2, 2, 2), {"Disabled", "Left", "Right", "Forward"});

                    local gear = manual_yaw.select:create();
                    manual_yaw.static = gear:switch(text_effects:format(interpoint, "Static", 2, 2, 2));
                    manual_yaw.inverter = gear:switch(text_effects:format(interpoint, "Inverter", 2, 2, 2)):depend({manual_yaw.static, true})
                
                    additional.manual_yaw = manual_yaw;
                end

                local backstab = {}; do
                    backstab.switch = group:switch(text_effects:format("sword", "Avoid Backstab", 2, 2, 2));

                    additional.backstab = backstab
                end

                local warmup_aa = {}; do
                    warmup_aa.select = group:combo(text_effects:format("gear", "State", 2, 2, 2), {"Disabled", "Warmup", "No Enemies", "Force"});
                    local gear = warmup_aa.select:create();

                    warmup_aa.pitch = gear:combo(text_effects:format(interpoint, "Pitch", 2, 2, 2), "Disabled", "Down"):depend({warmup_aa.select, "Disabled", true})
                    warmup_aa.yaw = gear:combo(text_effects:format(interpoint, "Yaw", 2, 2, 2), "Spin", "Distortion", "L&R"):depend({warmup_aa.select, "Disabled", true})

                    warmup_aa.range = gear:slider(text_effects:format("arrows-left-right", "Range", 2, 2, 2), 1, 360, 360):depend({warmup_aa.yaw, "L&R", true}, {warmup_aa.select, "Disabled", true})
                    warmup_aa.speed = gear:slider(text_effects:format("gauge", "Speed", 2, 2, 2), 1, 128, 32, 1, "t"):depend({warmup_aa.yaw, "L&R", true}, {warmup_aa.select, "Disabled", true})

                    warmup_aa.left_yaw = gear:slider(text_effects:format("arrow-left", "Left Offset", 2, 2, 2), -180, 180, 0):depend({warmup_aa.yaw, "L&R"}, {warmup_aa.select, "Disabled", true})
                    warmup_aa.right_yaw = gear:slider(text_effects:format("arrow-right", "Right Offset", 2, 2, 2), -180, 180, 0):depend({warmup_aa.yaw, "L&R"}, {warmup_aa.select, "Disabled", true})
                    
                    additional.warmup_aa = warmup_aa;
                end

                local safe_head = {}; do
                    safe_head.switch = group:switch(text_effects:format("head-side", "Safe Head", 2, 2, 2));

                    local gear = safe_head.switch:create();
                    safe_head.states = gear:selectable(text_effects:format("list-check", "Conditions", 2, 2, 2), {
                        "Air Crouch",
                        "Zeus",
                        "Knife",
                        "Height Advantage"
                    }):depend({safe_head.switch, true});
                    safe_head.height = gear:slider(text_effects:format("ruler-vertical", "Height", 2, 2, 2), 0, 200, 25, 1, "u."):depend({safe_head.switch, true}, {safe_head.states, "Height Advantage"});
                    safe_head.height:tooltip(text_effects:format("info-circle", "If value equals zero then safe head works only on the same height as your enemy.", 1, 2, 1))

                    additional.safe_head = safe_head;
                end
            
                main.additional = additional
            end

            antiaim.main = main;
        end

        local angles = {}; do
            
            local group = pui.create(text_effects:format("list-tree", "", 0, 0, 0), "Builder", 2);

            local break_lc = {}; do
                break_lc.group = pui.create(text_effects:format("list-tree", "", 0, 0, 0), "Snap builder"); 
                break_lc.select = break_lc.group:selectable(text_effects:format(interpoint, "Break LC", 2, 5, 2, "9ca7e1ff"), e_num.states);

                local gear = break_lc.select:create();
                break_lc.disable_on_grenade = gear:switch(text_effects:format("", "Disable on Grenade", 0, 0, 0));
                break_lc.hide_shots = gear:combo(text_effects:format("", "Hide Shots", 0, 0, 0), {"Favor Fire Rate", "Favor Fake Lag", "Break LC"})
                
                angles.break_lc = break_lc;
            end

            local ctx = {}; do
                for idx, state in pairs(e_num.states) do
                    ctx[state] = {};

                    for team, i in pairs(e_num.teams) do
                        ctx[state][i] = {};

                        local b = ctx[state][i];
                        local m_team = main.configure.team;
                        local m_state = main.configure.state;


                        b.allow_state = group:switch(text_effects:format("shield-check", ("Allow \v%s\r state"):format(state), 2, 2, 2), true):depend({m_team, team}, {m_state, idx})
                        b.yaw = group:combo(text_effects:format(interpoint, "Yaw", 2, 2, 2), {"Disabled", "Backward"}, "Backward"):depend({m_team, team}, {m_state, idx}) do
                            local gear = b.yaw:create();

                            b.yaw_mode = gear:combo(text_effects:format("", "Mode", 0, 0, 0), {"Solo", "L/R"}):depend({b.yaw, "Backward"});
                            b.offset = gear:slider(text_effects:format("turn-down-right", "Offset", 10, 2, 2), -180, 180, 0):depend({b.yaw, "Backward"}, {b.yaw_mode, "Solo"});

                            b.yaw_left = gear:slider(text_effects:format("turn-down-right", "Left", 10, 2, 2), -180, 180, 0):depend({b.yaw, "Backward"}, {b.yaw_mode, "L/R"});
                            b.yaw_right = gear:slider(text_effects:format("turn-down-right", "Right", 10, 2, 2), -180, 180, 0):depend({b.yaw, "Backward"}, {b.yaw_mode, "L/R"});

                            b.delay = gear:switch(text_effects:format(interpoint, "Delay", 2, 2, 2, "FFA500FF")):depend({b.yaw, "Backward"}, {b.yaw_mode, "L/R"});
                            b.delay_method = gear:combo(text_effects:format("", "Method", 10, 2, 2), {"Default", "Random", "Custom"}):depend({b.yaw, "Backward"}, {b.yaw_mode, "L/R"}, {b.delay, true});

                            b.delay_default = gear:slider(text_effects:format("turn-down-right", "\aFFA500FFTiming\r", 15, 2, 2), 2, 22, 0):depend({b.yaw, "Backward"}, {b.yaw_mode, "L/R"}, {b.delay_method, "Default"}, {b.delay, true});

                            b.delay_random_min = gear:slider(text_effects:format("turn-down-right", "\aFFA500FFMin. Timing\r", 18, 2, 2), 2, 22, 0):depend({b.yaw, "Backward"}, {b.yaw_mode, "L/R"}, {b.delay_method, "Random"}, {b.delay, true});
                            b.delay_random_max = gear:slider(text_effects:format("turn-down-right", "\aFFA500FFMax. Timing\r", 18, 2, 2), 2, 22, 0):depend({b.yaw, "Backward"}, {b.yaw_mode, "L/R"}, {b.delay_method, "Random"}, {b.delay, true});

                            b.delay_custom_sliders = gear:slider(text_effects:format(interpoint, "Sliders", 17, 2, 2), 2, 6, 2):depend({b.yaw, "Backward"}, {b.yaw_mode, "L/R"}, {b.delay_method, "Custom"}, {b.delay, true});

                            for i = 1, 6 do
                                b["delay_" .. i] = gear:slider(text_effects:format("turn-down-right", ("%s"):format(i), 14 + 5 * i, 2, 2), 2, 22, 0):depend({b.yaw, "Backward"}, {b.yaw_mode, "L/R"}, {b.delay_method, "Custom"}, {b.delay, true}, {b.delay_custom_sliders, function()
                                    if i <= 2 then
                                        return true;
                                    end

                                    return b.delay_custom_sliders.value >= i
                                end});
                            end
                        end;

                        b.modifier = group:combo(text_effects:format("turn-down-right", "Modifier", 10, 2, 2), {"Disabled", "Center", "Offset", "Random", "Spin", "3-Way", "Bobro", "5-Way"}):depend({m_team, team}, {m_state, idx}, {b.yaw, "Backward"}) do
                            local gear = b.modifier:create();

                            b.randomize = gear:switch(text_effects:format("", "Randomize", 0, 0, 0)):depend({m_team, team}, {m_state, idx}, {b.yaw, "Backward"}, {b.modifier, "Disabled", true});
                            
                            b.modifier_mode = gear:combo(text_effects:format("", "Mode", 0, 0, 0), "Default", "Custom"):depend({m_team, team}, {m_state, idx}, {b.yaw, "Backward"}, {b.modifier, "Disabled", true}, {b.randomize, true});
                            
                            
                            b.min = gear:slider(text_effects:format("turn-down-right", "Minimum", 10, 2, 2), -180, 180, 0):depend({m_team, team}, {m_state, idx}, {b.yaw, "Backward"}, {b.modifier, "Disabled", true}, {b.randomize, true}, {b.modifier_mode, "Default"})
                            b.max = gear:slider(text_effects:format("turn-down-right", "Maximum", 10, 2, 2), -180, 180, 0):depend({m_team, team}, {m_state, idx}, {b.yaw, "Backward"}, {b.modifier, "Disabled", true}, {b.randomize, true}, {b.modifier_mode, "Default"})

                            b.modifier_custom_sliders = gear:slider(text_effects:format(interpoint, "Sliders", 7, 5, 2), 2, 6, 2):depend({m_team, team}, {m_state, idx}, {b.yaw, "Backward"}, {b.modifier, "Disabled", true}, {b.randomize, true}, {b.modifier_mode, "Custom"});

                            for i = 1, 6 do
                                b["modifier_sliders_" .. i] = gear:slider(text_effects:format("turn-down-right", ("%s"):format(i), 10 + 5 * i, 2, 2), -180, 180, 0):depend({m_team, team}, {m_state, idx}, {b.yaw, "Backward"}, {b.modifier, "Disabled", true}, {b.randomize, true}, {b.modifier_mode, "Custom"}, {b.modifier_custom_sliders, function()
                                    if i <= 2 then
                                        return true;
                                    end

                                    return b.modifier_custom_sliders.value >= i
                                end});
                            end

                            b.modifier_offset = gear:slider(text_effects:format(interpoint, "Offset", 2, 2, 2), -180, 180, 0):depend({m_team, team}, {m_state, idx}, {b.yaw, "Backward"}, {b.modifier, "Disabled", true}, {b.randomize, false})
                        end

                        b.body_yaw = group:switch(text_effects:format(interpoint, "Body Yaw", 2, 2, 2)):depend({m_team, team}, {m_state, idx}) do
                            local gear = b.body_yaw:create();

                            b.body_freestanding = gear:combo("Freestanding", {"Off", "Peek Fake", "Peek Real"}):depend({m_team, team}, {m_state, idx}, {b.body_yaw, true});

                            b.mode = gear:combo(text_effects:format("", "Mode", 0, 0, 0), {"Static", "Ticks", "Random"}):depend({m_team, team}, {m_state, idx}, {b.body_yaw, true});
                            b.mode_ticks = gear:slider(text_effects:format("turn-down-right", "Ticks", 10, 2, 2), 4, 16, 4, 1, "t"):depend({m_team, team}, {m_state, idx}, {b.body_yaw, true}, {b.mode, "Ticks"});
                            b.mode_random = gear:slider(text_effects:format("turn-down-right", "Random Ticks", 10, 2, 2), 4, 16, 4, 1, "x"):depend({m_team, team}, {m_state, idx}, {b.body_yaw, true}, {b.mode, "Random"});
                        
                        
                            b.limit_mode = gear:combo(text_effects:format("", "Limit Mode", 0, 0, 0), {"Static", "Random", "From/To", "Speed-based Switch"}):depend({m_team, team}, {m_state, idx}, {b.body_yaw, true});

                            b.left_limit = gear:slider(text_effects:format("turn-down-right", "Left Limit", 10, 2, 2), 0, 60, 60):depend({m_team, team}, {m_state, idx}, {b.body_yaw, true}, {b.limit_mode, "Static"});
                            b.right_limit = gear:slider(text_effects:format("turn-down-right", "Right Limit", 10, 2, 2), 0, 60, 60):depend({m_team, team}, {m_state, idx}, {b.body_yaw, true}, {b.limit_mode, "Static"});

                            b.minimum_limit = gear:slider(text_effects:format("turn-down-right", "Minimum", 10, 2, 2), 0, 60, 60):depend({m_team, team}, {m_state, idx}, {b.body_yaw, true}, {b.limit_mode, "Random"});
                            b.maximum_limit = gear:slider(text_effects:format("turn-down-right", "Maximum", 10, 2, 2), 0, 60, 60):depend({m_team, team}, {m_state, idx}, {b.body_yaw, true}, {b.limit_mode, "Random"});

                            b.from_limit = gear:slider(text_effects:format("turn-down-right", "From", 10, 2, 2), 0, 60, 60):depend({m_team, team}, {m_state, idx}, {b.body_yaw, true}, {b.limit_mode, function()
                                return b.limit_mode:get() == "From/To" or b.limit_mode:get() == "Speed-based Switch"
                            end});

                            b.to_limit = gear:slider(text_effects:format("turn-down-right", "To", 10, 2, 2), 0, 60, 60):depend({m_team, team}, {m_state, idx}, {b.body_yaw, true}, {b.limit_mode, function()
                                return b.limit_mode:get() == "From/To" or b.limit_mode:get() == "Speed-based Switch"
                            end});

                            b.sb_speed = gear:slider(text_effects:format("turn-down-right", "\aFFA500FFTiming\r", 15, 2, 2), 1, 22, 0):depend({m_team, team}, {m_state, idx}, {b.body_yaw, true}, {b.limit_mode, "Speed-based Switch"});

                        end
                        b.body_yaw_options = group:selectable(text_effects:format("turn-down-right", "Options", 10, 2, 2), {"Avoid Overlap", "Jitter", "Randomize Jitter", "Anti Bruteforce"}):depend({m_team, team}, {m_state, idx}, {b.body_yaw, true})

                        b.send_to_opposite = group:button(text_effects:format("share-from-square", "Send to the opposite side", 17, 2, 20), function ()
                            local opposite_team = m_team:get() == "T" and "CT" or "T";
                            local current_state = m_state:list()[m_state:get()];

                            local original = ctx[current_state][m_team:get()]
                            local opposite = ctx[current_state][opposite_team]
                            for key, value in pairs(original) do

                                for k, v in pairs(opposite) do

                                    if k == key then
                                        v:set(value:get())
                                    end
                                end
                            end

                            cvar.playvol:call("ui/beepclear.wav", 1.0)
                        end, true):depend({m_team, team}, {m_state, idx})

                        b.choke = break_lc.group:combo(text_effects:format(interpoint, "Tickbase", 2, 5, 2, "ff0000ff"), {"Default", "Custom"}):depend({m_team, team}, {m_state, idx}, {break_lc.select, function()
                            return break_lc.select:get(idx)
                        end}); do
                            local gear = b.choke:create();

                            b.random_choke = gear:switch(text_effects:format("", "Random Choke", 0, 0, 0)):depend({m_team, team}, {m_state, idx}, {b.choke, "Custom"})
                            b.choke_slider = gear:slider(text_effects:format("turn-down-right", "Choke", 10, 2, 2), 2, 22, 16, 1, "t"):depend({m_team, team}, {m_state, idx}, {b.choke, "Custom"}, {b.random_choke, false})

                            b.choke_method = gear:combo(text_effects:format(interpoint, "Method", 2, 2, 2), {"Default", "Custom"}):depend({m_team, team}, {m_state, idx}, {b.choke, "Custom"}, {b.random_choke, true})
                            b.choke_from = gear:slider(text_effects:format("turn-down-right", "Choke from", 10, 2, 2), 1, 22, 16):depend({m_team, team}, {m_state, idx}, {b.choke, "Custom"}, {b.random_choke, true}, {b.choke_method, "Default"})
                            b.choke_to = gear:slider(text_effects:format("turn-down-right", "Choke to", 10, 2, 2), 1, 22, 16):depend({m_team, team}, {m_state, idx}, {b.choke, "Custom"}, {b.random_choke, true}, {b.choke_method, "Default"})


                            b.choke_sliders = gear:slider(text_effects:format("", "Sliders", 15, 0, 0), 2, 6, 2):depend({m_team, team}, {m_state, idx}, {b.choke, "Custom"}, {b.random_choke, true}, {b.choke_method, "Custom"})
                            for i = 1, 6 do
                                b["choke1_" .. i] = gear:slider(text_effects:format("turn-down-right", ("%s"):format(i), 14 + 5 * i, 2, 2), 2, 22, 0, 1, "t"):depend({m_team, team}, {m_state, idx}, {b.choke, "Custom"}, {b.random_choke, true}, {b.choke_method, "Custom"}, {b.choke_sliders, function()
                                    if i <= 2 then
                                        return true;
                                    end

                                    return b.choke_sliders.value >= i
                                end});
                            end
                        end

                        ctx[state][i] = b;
                        angles.builder = ctx;
                    end
                end
            end


            local freestanding = {}; do
                freestanding.switch = group:switch(text_effects:format("arrows-rotate", "Freestanding", 2, 2, 2));

                local gear = freestanding.switch:create();
                freestanding.prefer_manual = gear:switch(text_effects:format(interpoint, "Prefer Manual", 2, 2, 2));

                local dsbl_tbl = e_num.states;
                table.remove(dsbl_tbl, 9)

                freestanding.disablers = gear:selectable(text_effects:format(interpoint, "Disablers", 2, 2, 2), dsbl_tbl);
                freestanding.body_fs = gear:switch(text_effects:format(interpoint, "Body Freestanding", 2, 2, 2))
                freestanding.yaw_mod = gear:switch(text_effects:format(interpoint, "Disable Yaw Modifiers", 2, 2, 2))

                angles.freestanding = freestanding;
            end

            local anti_bruteforce = {}; do
                anti_bruteforce.switch = group:switch(text_effects:format("reply-clock", "Anti-Bruteforce", 2, 2, 2));

                local gear =  anti_bruteforce.switch:create();
                anti_bruteforce.states = gear:selectable(text_effects:format(interpoint, "States", 2, 2, 2), e_num.states):depend({anti_bruteforce.switch, true})
                anti_bruteforce.mode = gear:combo(text_effects:format(interpoint, "Mode", 2, 2, 2), {"Increasing", "Decreasing", "Meta"}):depend({anti_bruteforce.switch, true}, {anti_bruteforce.states, true})
                anti_bruteforce.switch:tooltip(text_effects:format("info-circle", "Anti-bruteforce with automatic preset to avoid hs ^_^.", 1, 2, 1))
                
                angles.anti_bruteforce = anti_bruteforce;
            end

            antiaim.angles = angles;
        end


        menu.antiaim = antiaim;
    end

    local misc = {}; do

        local player_animations = {}; do
            local group = pui.create(text_effects:format("bottle-droplet", "", 0, 0, 0), "Animations", 1);

            local jitter_legs = {}; do
                jitter_legs.switch = group:switch(text_effects:format("user-ninja", "Jitter Legs", 2, 2, 2));

                local gear = jitter_legs.switch:create();
                jitter_legs.from = gear:slider(text_effects:format("", "Start", 2, 2, 2), 0, 100, 0, 0.01, "x"):depend({jitter_legs.switch, true});
                jitter_legs.to = gear:slider(text_effects:format("", "End", 2, 2, 2), 0, 100, 0, 0.01, "x"):depend({jitter_legs.switch, true});
                
                player_animations.jitter_legs = jitter_legs;
            end

            local leaning = {}; do
                leaning.value = group:slider(text_effects:format("lines-leaning", "Leaning", 2, 3, 2), 0, 100, 50, 1, "%");

                player_animations.leaning = leaning;
            end

            local falling = {}; do
                falling.value = group:slider(text_effects:format("person-falling", "Falling", 2, 2, 2), 0, 100, 50, 1, "%");

                player_animations.falling = falling;
            end

            misc.player_animations = player_animations;
        end

        local aimbot = {}; do
            local group = pui.create(text_effects:format("bottle-droplet", "", 0, 0, 0), "Aimbot", 1);

            local latency = {}; do
                latency.switch = group:switch(text_effects:format("wifi", "Unlock Fake Latency", 2, 2, 2), false);
                latency.switch:set_callback(function(e)local value = e:get();cvar.sv_maxunlag:float(value and 2 or 0.1)end)
                latency.switch:tooltip(text_effects:format("info-circle", "Allows you to use maximum Fake Latency (200-300)", 1, 2, 1))

                aimbot.latency = latency;
            end

            local fakeduck = {}; do
                fakeduck.unlock = group:switch(text_effects:format("rabbit-running", "Unlock FD Speed", 2, 2, 2));
                fakeduck.unlock:tooltip(text_effects:format("info-circle", "Allows you to move a bit faster on Fake duck", 1, 2, 1))

                fakeduck.freeze_period = group:switch(text_effects:format("duck", "Fakeduck on Freezetime", 2, 4, 2));
                fakeduck.freeze_period:tooltip(text_effects:format("info-circle", "Allows you to Fake duck on freezetime period.\n\n Helps on de_bank a lot.", 1, 2, 1))

                aimbot.fakeduck = fakeduck;
            end
            
            local logging = {}; do
                logging.switch = group:switch(text_effects:format("timeline-arrow", "Log Events", 2, 2, 2));

                local gear = logging.switch:create();

                local mode = {}; do
                    mode.select = gear:selectable(text_effects:format(interpoint, "Events", 2, 2, 2), {"Aimbot", "Connection problems", "Low FPS"}):depend({logging.switch, true});
                    
                    mode.is_notification = gear:switch(text_effects:format("", "Notification", 10, 2, 2)):depend({logging.switch, true}, {mode.select, "Aimbot"});

                    logging.mode = mode;
                end

                local colors = {}; do
                
                    colors.prefix = gear:color_picker(text_effects:format("", "Prefix Color", 10, 2, 2)):depend({logging.switch, true}, {mode.select, "Aimbot"});
                    colors.main = gear:color_picker(text_effects:format("", "Main Color", 10, 2, 2)):depend({logging.switch, true}, {mode.select, "Aimbot"});

                    logging.colors = colors
                end

                aimbot.logging = logging;
            end

            misc.aimbot = aimbot;
        end
        
        local movement = {}; do
            local group = pui.create(text_effects:format("bottle-droplet", "", 0, 0, 0), "Movement", 1);

            movement.fall_damage = group:switch(text_effects:format("person-falling", "Avoid Fall Damage", 2, 4, 2));
            movement.fall_damage:tooltip("Attempts to perform a jumpbug\nwhen possible.\n\nThis is a 1:1 replica from \a7a9809ffgamesense\r")

            movement.fast_ladder = group:switch(text_effects:format("water-ladder", "Fast Ladder", 2, 2, 2));
            movement.fast_ladder:tooltip("- Abuses the ladder movement\nmechanic and makes you move a\nlittle faster")

            movement.air_duck_collision = group:switch(text_effects:format("person-walking-dashed-line-arrow-right", "Collision Air Duck", 2, 1, 2));
            movement.air_duck_collision:tooltip("Automatically ducks if there's a possibility of avoiding collision by making the player fully-ducked. \n\nDoesn't work on ground.")

            movement.edge_quick_stop = group:switch(text_effects:format("person-circle-exclamation", "Edge Quick Stop", 2, 2, 2));
            movement.edge_quick_stop:tooltip("Prevents you from walking or jumping off edges, similar to the Minecraft sneaking mechanic. \n\nWorks best with Peek Assist.")

            misc.movement = movement
        end

        menu.misc = misc;
    end

    local visuals = {}; do
        local group = pui.create(text_effects:format("bottle-droplet", "", 0, 0, 0), "Visuals", 2);

        local scope_overlay = {}; do
            scope_overlay.switch = group:switch(text_effects:format("crosshairs", "Better Scope Overlay", 2, 2, 2));

            local gear = scope_overlay.switch:create();
            scope_overlay.options = gear:selectable(text_effects:format(interpoint, "Options", 2, 2, 2), {"Rotation", "Inverted"}):depend({scope_overlay.switch, true})
            scope_overlay.animation = gear:switch("Animate"):depend({scope_overlay.switch, true}):depend({scope_overlay.options, "Rotation"});


            scope_overlay.length = gear:slider("Length", 10, 300, 185):depend({scope_overlay.switch, true})
            scope_overlay.gap = gear:slider("Gap", 1, 300, 5):depend({scope_overlay.switch, true})

            local colors = {}; do
                colors.main = gear:color_picker("Main Accent", color(255)):depend({scope_overlay.switch, true})
                colors.edge = gear:color_picker("Edge Accent", color(0)):depend({scope_overlay.switch, true})

                scope_overlay.colors = colors;
            end

            visuals.scope_overlay = scope_overlay
        end


        local manual_arrows = {}; do
            manual_arrows.switch = group:switch(text_effects:format("arrows-turn-to-dots", "Manual Arrows", 2, 2, 2));
            
            local gear = manual_arrows.switch:create();
            manual_arrows.font = gear:combo(text_effects:format(interpoint, "Font", 2, 2, 2), {"Default", "Small", "Console", "Bold"}):depend({manual_arrows.switch, true});
            manual_arrows.color = gear:color_picker(text_effects:format(interpoint, "Color", 2, 2, 2), color()):depend({manual_arrows.switch, true});
            manual_arrows.offset = gear:slider(text_effects:format(interpoint, "Offset", 2, 2, 2), 0, 200, 35):depend({manual_arrows.switch, true});

            local symbols = {}; do
                symbols.left = gear:input("Left Symbol", "力量"):depend({manual_arrows.switch, true})
                symbols.right = gear:input("Right Symbol", "力量"):depend({manual_arrows.switch, true})
                symbols.forward = gear:input("Forward Symbol", "力量"):depend({manual_arrows.switch, true})

                manual_arrows.symbols = symbols;
            end
            visuals.manual_arrows = manual_arrows;
        end

        local aspect_ratio = {}; do
            aspect_ratio.switch = group:switch(text_effects:format("glasses", "Aspect Ratio", 2, 2, 2));

            local gear = aspect_ratio.switch:create();
            aspect_ratio.value = gear:slider(text_effects:format(interpoint, "Value", 2, 2, 2), 1, 200, 133, 0.01):depend({aspect_ratio.switch, true});

            local r_aspectratio = cvar.r_aspectratio;

            local function shutdown()
                r_aspectratio:float(cvars:get_original(r_aspectratio))
            end

            local function on_change()
                if not aspect_ratio.switch:get() then
                    shutdown()
                    return;
                end

                local value = aspect_ratio.value:get() * .01

                r_aspectratio:float(value, true);
            end

            aspect_ratio.switch:set_callback(on_change, true);
            aspect_ratio.value:set_callback(on_change);
            events.shutdown(shutdown)

            visuals.aspect_ratio = aspect_ratio;
        end

        local viewmodel_changer = {}; do
            viewmodel_changer.switch = group:switch(text_effects:format("hand", "Viewmodel Changer", 2, 3, 2));
            
            local gear = viewmodel_changer.switch:create();

            viewmodel_changer.fov = gear:slider(text_effects:format(interpoint, "Field of View", 2, 2, 2), 0, 1000, 680, 0.1):depend({viewmodel_changer.switch, true});
            viewmodel_changer.x = gear:slider(text_effects:format(interpoint, "Offset X", 2, 2, 2), -100, 100, 0, 0.1):depend({viewmodel_changer.switch, true});
            viewmodel_changer.y = gear:slider(text_effects:format(interpoint, "Offset Y", 2, 2, 2), -100, 100, 0, 0.1):depend({viewmodel_changer.switch, true});
            viewmodel_changer.z = gear:slider(text_effects:format(interpoint, "Offset Z", 2, 2, 2), -100, 100, 0, 0.1):depend({viewmodel_changer.switch, true});

            local viewmodel_fov = cvar.viewmodel_fov;

            local viewmodel_offset_x = cvar.viewmodel_offset_x;
            local viewmodel_offset_y = cvar.viewmodel_offset_y;
            local viewmodel_offset_z = cvar.viewmodel_offset_z;

            local function shutdown()
                viewmodel_fov:float(cvars:get_original(viewmodel_fov), false)

                viewmodel_offset_x:float(cvars:get_original(viewmodel_offset_x), false)
                viewmodel_offset_y:float(cvars:get_original(viewmodel_offset_y), false)
                viewmodel_offset_z:float(cvars:get_original(viewmodel_offset_z), false)
            end

            local function on_change()
                local x, y, z, fov = viewmodel_changer.x:get(), viewmodel_changer.y:get(), viewmodel_changer.z:get(), viewmodel_changer.fov:get()

                if viewmodel_changer.switch:get() then
                    viewmodel_fov:float(fov * 0.1, true)
                    viewmodel_offset_x:float(x * 0.1, true)
                    viewmodel_offset_y:float(y * 0.1, true)
                    viewmodel_offset_z:float(z * 0.1, true)
                else
                    shutdown()
                end
            end

            events.shutdown(shutdown)
            viewmodel_changer.switch:set_callback(on_change, true)
            viewmodel_changer.x:set_callback(on_change)
            viewmodel_changer.y:set_callback(on_change)
            viewmodel_changer.z:set_callback(on_change)
            viewmodel_changer.fov:set_callback(on_change)

            
            visuals.viewmodel_changer = viewmodel_changer;
        end

        local skeet_indicators = {}; do
            skeet_indicators.switch = group:switch(text_effects:format("paintbrush", "Game\a95b806ffSense\r Indicators", 2, 2, 2));

            local gear = skeet_indicators.switch:create();
            skeet_indicators.bomb = gear:switch("Bomb"):depend({skeet_indicators.switch, true})
            skeet_indicators.features = gear:selectable(text_effects:format(interpoint, "Feature ind.", 2, 2, 2), {
                "Force safe point",
                "Force body aim",
                "Ping spike",
                "Double tap",
                "Duck peek assist",
                "Freestanding",
                "On shot anti-aim",
                "Minimum damage override"
            }):depend({skeet_indicators.switch, true})

            skeet_indicators.additional = gear:selectable(text_effects:format(interpoint, "Additional ind.", 2, 2, 2), {
                "Hitchance override",
                "Dormant aimbot"
            }):depend({skeet_indicators.switch, true})

            visuals.skeet_indicators = skeet_indicators;
        end


        local velocity_warning = {}; do
            velocity_warning.switch = group:switch(text_effects:format("rabbit-running", "Velocity Warning", 2, 2, 2));

            local gear = velocity_warning.switch:create();
            velocity_warning.color = gear:color_picker(text_effects:format(interpoint, "Color", 2, 2, 2)):depend({velocity_warning.switch, true})
            
            visuals.velocity_warning = velocity_warning;
        end
            
        local hitmarker = {}; do
            hitmarker.select = group:selectable(text_effects:format("bullseye-arrow", "Hit Marker", 2, 4, 2), {"2D", "3D"});

            local gear = hitmarker.select:create();
            hitmarker.color = gear:color_picker(text_effects:format(interpoint, "Color", 2, 2, 2), {
                ["2D"] = { color(175, 255, 55, 255) },
                ["3D"] = { color(35, 128, 255, 255) }
            }):depend({hitmarker.select, true});
            hitmarker.time = gear:slider(text_effects:format(interpoint, "Duration", 2, 2, 2), 0, 100, 1, 0.1, "s"):depend({hitmarker.select, true});

            visuals.hitmarker = hitmarker;
        end

        local player_transparency = {}; do
            player_transparency.switch = group:switch(text_effects:format("face-dotted", "Keep Model Transparency", 2, 4, 2));
            player_transparency.switch:tooltip("- Keeps the local player model transparent after shooting with bolt-action sniper rifles and adds extra fade-in/out animation \n\n- This is a 1:1 replica from \a95b806ffgamesense")
            
            visuals.player_transparency = player_transparency;
        end

        local damage_indicator = {}; do
            damage_indicator.switch = group:switch(text_effects:format("claw-marks", "Damage Indicator", 2, 3, 2));

            visuals.damage_indicator = damage_indicator;
        end

        local legacy_desync = {}; do
            legacy_desync.switch = group:switch(text_effects:format("calendar-range", "Legacy Desync", 2, 5, 2));
            legacy_desync.switch:tooltip("Brings back old desync like back then in 2020. Pre-riptide animations")

            visuals.legacy_desync = legacy_desync;
        end

        local remove_sleeves = {}; do
            remove_sleeves.switch = group:switch(text_effects:format("shirt-long-sleeve", "Remove Sleeves", 2, 2.5, 2));

            visuals.remove_sleeves = remove_sleeves;
        end

        local increased_fl = {}; do
            local ref = ui.find("Aimbot", "Anti Aim", "Fake Lag", "Limit");
            
            increased_fl.switch = group:switch(text_effects:format("lock", "Clock Correction", 2, 5, 2));
            increased_fl.ticks = increased_fl.switch:create():slider("Client-issued ticks", 1, 22, 15, 1, function(e)
                if e == 15 then return "NL" end
                if e == 16 then return "GS" end
                if e == 17 then return "Default" end
                return e;
            end):depend(increased_fl.switch)

            local sv_maxusrcmdprocessticks = cvar.sv_maxusrcmdprocessticks;
            local function shutdown()
                sv_maxusrcmdprocessticks:int(cvars:get_original(sv_maxusrcmdprocessticks), false);
                ref:set(cvars:get_original(sv_maxusrcmdprocessticks) - 2)
            end

            local function on_change()
                local ticks = increased_fl.ticks:get()
                local list = {
                    ["nopoint"] = true,
                    ["ramzan777888"] = true
                }

                if list[common.get_username()] then
                    increased_fl.switch:disabled(false)
                    increased_fl.ticks:disabled(false)
                    if increased_fl.switch:get() then
                        sv_maxusrcmdprocessticks:int(ticks, true)
                        ref:set(ticks - 2);
                    else
                        shutdown()
                    end
                else
                    increased_fl.switch:disabled(true)
                    increased_fl.ticks:disabled(true)
                    shutdown()
                end
            end

            events.shutdown(shutdown)
            events.render(on_change)

            visuals.increased_fl = increased_fl;
        end

        menu.visuals = visuals;
    end
end

local notify = {}; do
    local data = {}

    function notify.new(text, color, icon)
        local style = menu.info.notify.style:get()
        local time = 3
        
        table.insert(data, {
            text = text,

            duration = globals.realtime + 3,
            alpha = smoothy.new(0),
            color = color or ui.get_style()["Link Active"],
            icon = icon or "bolt"
        })
    end

    local function outline_container(icon, text, pos, clr, alpha, add_y)
        clr = clr or color(255);

        local text_size = render.measure_text(1, "d", text) + vector(33, 10)

        pos = pos - vector(text_size.x/2, 0);
        

        render.rect_outline(pos, pos + text_size, color(0):alpha_modulate(alpha * 255), 1, 5);
        render.rect(pos + vector(1, 1), pos - vector(1, 1) + text_size, color(0, 0, 0, 120 * alpha), 5);

        render.rect(pos + vector(25, 4), pos + vector(25, text_size.y - 4), color(160, 160, 160, 255 * alpha), 0);

        render.text(1, pos + vector(10, 4), clr:alpha_modulate(255 * alpha), "d", ui.get_icon(icon))
        render.text(1, pos + vector(30, 4), color():alpha_modulate(255 * alpha), "d", text)
    end

    local function cat_container(ctx, center, add_y)
        local text = ctx.text;

        local accent = ctx.color or color(255);
        ctx.alpha(.1, globals.realtime < ctx.duration);
        local alpha_value = ctx.alpha.value;

        outline_container(ctx.icon, text_effects:colored(
            (function()
                local parts = {}
                for i, txt in pairs(text) do
                    table.insert(parts, {
                        txt,
                        (i % 2 == 0 and accent or color(255)):alpha_modulate(255 * alpha_value)
                    })
                end
                return unpack(parts)
            end)()  
        ), center + vector(0, add_y), accent, alpha_value, add_y)


        add_y = add_y * alpha_value;

        return alpha_value < 0.01 and (ctx.duration + 3 < globals.realtime) or #data > 6, alpha_value;
    end

    local function on_paint()
        local center = screen / vector(2, 1.4)
        local add_y = 0

        for i = #data, 1, -1 do
            local ctx = data[i]
            local style = menu.info.notify.style:get()
            
            if style == "Cat" then
                local should_clear, alpha = cat_container(ctx, center, add_y);

                if should_clear then
                    table.remove(data, i)
                end

                add_y = add_y + 27 * alpha
            end
        end
    end

    local function test_notify()
        if not menu.info.notify.spam:get() then
            return
        end
        notify.new({
            "Hello",
            " world! ",
            "boys and ",
            "ladies","","","","",""
        }, color(255, 0, 0, 255))

        notify.new({
            "Hello",
            " world! ",
            "boys and ",
            "ladies","","","","",""
        }, color(255, 255, 255, 255))

        utils.execute_after(5, test_notify)
    end 

    menu.info.notify.spam:set_callback(test_notify)
    test_notify();
    events.render(on_paint)
end

local presets = {}; do
    local _NAME = "mo4ablyadskaya";
    local database = db[_NAME] or {};
    local xor_key = "3e b1 59 f2 8d 04 c7 aa 6f d0 23 9c 45 e8";

    local sep = "♡⋆⋆························⋆⋆♡";
    
    local pinned = {"\a{Link Active}•   Brandon", "\a{Link Active}•   mapsat ♡", "\a{Link Active}•   MetaHOI", sep}


    if not database[pinned[1]] then
        database[pinned[1]] = "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"
    end
    
    if not database[pinned[2]] then
        database[pinned[2]] = "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"
    end

    if not database[pinned[3]] then
        database[pinned[3]] = "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"
    end


    local function save_database()
        db[_NAME] = database;
    end 

    local function xorstr(str)
        local key = xor_key
        local strlen, keylen = #str, #key

        local strbuf = ffi.new('char[?]', strlen+1)
        local keybuf = ffi.new('char[?]', keylen+1)

        ffi.copy(strbuf, str)
        ffi.copy(keybuf, key)

        for i=0, strlen-1 do
            strbuf[i] = bit.bxor(strbuf[i], keybuf[i % keylen])
        end

        return ffi.string(strbuf, strlen)
    end

    local function encrypt_preset(str)
        return base64.encode(
            xorstr(json.stringify(str))
        )
    end

    local function normalize_blob(str)
        if type(str) ~= "string" then
            return
        end

        str = str:gsub("%s+", "")

        if str == "" then
            return
        end

        return str
    end

    local function decrypt_preset(str, silent)
        str = normalize_blob(str)

        if str == nil then
            if not silent then
                log:error("Unable to decrypt preset")
            end

            return
        end

        local success, preset = pcall(function()
            return json.parse(xorstr(base64.decode(str)))
        end)

        if success == false then
            if not silent then
                log:error("Unable to decrypt preset")
            end

            return
        end

        return preset;
    end

    local function get_selected_name()
        local list = menu.info.presets.list
        local items = list:list()
        local index = list:get()
        local name = items ~= nil and index ~= nil and items[index] or nil

        if name ~= nil and name ~= sep then
            return name
        end

        local fallback_name = menu.info.presets.name:get()

        if fallback_name == nil or fallback_name == sep or database[fallback_name] == nil then
            return
        end

        return fallback_name
    end

    local function is_pinned_name(name)
        for i = 1, #pinned do
            if pinned[i] == name then
                return true
            end
        end

        return false
    end

    local function parse_preset_blob(str)
        str = normalize_blob(str)

        if str == nil then
            return
        end

        local preset = decrypt_preset(str, true)

        if type(preset) == "table" and type(preset.config) == "string" and type(preset.author) == "string" then
            local config = decrypt_preset(preset.config, true)

            if type(config) == "table" then
                if type(preset.time) ~= "number" then
                    preset.time = common.get_unixtime()
                end

                return str, preset, config
            end
        end

        if type(msgpack) ~= "table" then
            return
        end

        local legacy_success, legacy_preset = pcall(function()
            return msgpack.unpack(base64.decode(str))
        end)

        if not legacy_success or type(legacy_preset) ~= "table" or type(legacy_preset.config) ~= "string" then
            return
        end

        local legacy_config_success, legacy_config = pcall(function()
            return msgpack.unpack(base64.decode(normalize_blob(legacy_preset.config) or ""))
        end)

        if not legacy_config_success or type(legacy_config) ~= "table" then
            return
        end

        local upgraded_preset = {
            author = type(legacy_preset.author) == "string" and legacy_preset.author or "Unknown",
            time = common.get_unixtime(),
            config = encrypt_preset(legacy_config)
        }

        return encrypt_preset(upgraded_preset), upgraded_preset, legacy_config
    end

    local function get_preset_entry(name)
        local str = database[name]

        if str == nil then
            return
        end

        local storage, preset, config = parse_preset_blob(str)

        if storage == nil then
            return
        end

        if storage ~= str then
            database[name] = storage
            save_database()
        end

        return storage, preset, config
    end

    local function update_information()
        local selected = get_selected_name()

        if selected == nil then
            return
        end

        local _, preset = get_preset_entry(selected)

        if preset == nil then
            return
        end

        local preset_time = type(preset.time) == "number" and preset.time or common.get_unixtime()
        local format = common.get_date("%m/%d %H:%M", preset_time)

        menu.info.presets.information.creator:name(string.format("\v%s\r    |    \v%s\r", preset.author, format))
    end

    local function update_list()
        local m = {};

        for _, name in ipairs(pinned) do
            m[#m + 1] = name
        end

        for name, _ in pairs(database) do
            local already_added = false
            for _, added_name in ipairs(m) do
                if added_name == name then
                    already_added = true
                    break
                end
            end
            if not already_added then
                m[#m + 1] = name
            end
        end



        menu.info.presets.list:update(m);

        local list = menu.info.presets.list
        local name = list:list()[list:get()];

        if name == nil then
            return
        end

        if name ~= sep then
            menu.info.presets.name:set(name)
            update_information();
        end

        local selected_pinned = is_pinned_name(name)

        menu.info.presets.save:disabled(selected_pinned);
        menu.info.presets.export:disabled(selected_pinned);
        menu.info.presets.delete:disabled(selected_pinned);
        menu.info.presets.delete_confirm:disabled(selected_pinned);
        menu.info.presets.delete_cancel:disabled(selected_pinned);
    end

    local function update_preset(name, data)
        database[name] = data;

        save_database();
        update_list();
    end

    local function on_create()
        local name = menu.info.presets.name:get();

        if name == nil or name:gsub(" ", "") == "" then
            log:error("Unable to create preset with empty name")
            notify.new({"Unable to create preset with empty name"})
            return
        end

        if name == sep then
            return
        end

        if database[name] ~= nil then
            log:error("Preset already exists")
            notify.new({"Preset already exists"})
            return
        end

        local settings = {
            config = encrypt_preset(pui.save()),
            author = common.get_username(),
            time = common.get_unixtime()
        }

        notify.new({"Created preset with name - ", name})

        update_preset(name, encrypt_preset(settings)); 
    end

    local function on_load()
        local name = get_selected_name()

        if name == nil then
            log:error("Unable to find selected preset")
            notify.new({"Unable to find selected preset"})
            return
        end

        local _, preset, config = get_preset_entry(name)

        if preset == nil or config == nil then
            log:error("Unable to load preset")
            notify.new({"Unable to load preset"})
            return
        end

        local success = pcall(function()
            return pui.load(config)
        end)

        if success then
            log:message(string.format("Loaded %s's config (%s)", preset.author, name))
            notify.new({"Loaded ", preset.author, "'s config - ", name})
        else
            log:error("Unable to load preset")
            notify.new({"Unable to load preset"})
        end
    end

    local function on_save()
        local list = menu.info.presets.list;
        local name = menu.info.presets.name:get();
        if name == nil or name:gsub(" ", "") == "" then
            log:error("Unable to create preset with empty name")
            notify.new({"Unable to create preset with empty name"})
            return
        end

        if name == sep then
            return
        end

        local _, preset = get_preset_entry(name)

        if preset == nil then
            log:error("Unable to find preset")
            notify.new({"Unable to find preset"})
            return
        end

        preset.config = encrypt_preset(pui.save());
        preset.time = common.get_unixtime()

        update_preset(name, encrypt_preset(preset))
        log:message(string.format("Overwrited %s's config (%s)", preset.author, name))
        notify.new({"Overwrited ", preset.author, "'s config - ", name})
    end

    local function on_import()
        local cbdata = clipboard.get()

        if cbdata == nil or cbdata:gsub(" ", "") == "" then
            log:error("Unable to find clipboard data")
            notify.new({"Unable to find clipboard data"})
            return
        end

        local name = menu.info.presets.name:get();

        if name == nil or name:gsub(" ", "") == "" then
            log:error("Unable to import preset with empty name")
            notify.new({"Unable to import preset with empty name"})
            return
        end

        if name == sep then
            return
        end

        if is_pinned_name(name) then
            log:error("Unable to overwrite pinned preset")
            notify.new({"Unable to overwrite pinned preset"})
            return
        end

        local already_exists = database[name] ~= nil
        local storage, preset, config = parse_preset_blob(cbdata)

        if storage == nil or preset == nil or config == nil then
            log:error("Unable to import preset")
            notify.new({"Unable to import preset"})
            return
        end

        update_preset(name, storage)

        local load_success = pcall(function()
            return pui.load(config)
        end)

        if load_success then
            if already_exists then
                log:message(string.format("Imported %s's config and overwrote (%s)", preset.author, name))
                notify.new({"Imported ", preset.author, "'s config and overwrote - ", name})
            else
                log:message(string.format("Imported %s's config (%s)", preset.author, name))
                notify.new({"Imported ", preset.author, "'s config - ", name})
            end
        else
            log:error("Imported preset, but failed to load it")
            notify.new({"Imported preset, but failed to load it"})
        end
    end

    local function on_export()
        local name = get_selected_name()

        if name == nil then
            log:error("Unable to find selected preset")
            notify.new({"Unable to find selected preset"})
            return
        end

        local str, preset = get_preset_entry(name)

        if preset == nil then
            log:error("Unable to export preset")
            notify.new({"Unable to export preset"})
            return
        end

        local success = pcall(function()
            return clipboard.set(str);
        end)

        if success then
            log:message(string.format("Copied %s's config (%s)", preset.author, name))
            notify.new({"Copied ", preset.author, "'s config - ", name})
        else
            log:error("Unable to export preset")
            notify.new({"Unable to export preset"})
        end
    end

    local function on_delete()
        local list = menu.info.presets.list;
        local name = menu.info.presets.name:get();

        if name == nil or name:gsub(" ", "") == "" then
            log:error("Unable to find preset.")
            notify.new({"Unable to find preset."})
            return
        end

        if name == sep then
            return
        end

        local _, preset = get_preset_entry(name)

        if preset == nil then
            log:error("Unable to find preset")
            notify.new({"Unable to find preset."})
            return
        end
        
        log:message(string.format("Deleted %s's config (%s)", preset.author, name))
        notify.new({"Deleted ", preset.author, "'s config - ", name})

        update_preset(name, nil)
    end

    menu.info.presets.create:set_callback(on_create);
    menu.info.presets.load:set_callback(on_load);
    menu.info.presets.save:set_callback(on_save);
    menu.info.presets.export:set_callback(on_export);
    menu.info.presets.import:set_callback(on_import);
    menu.info.presets.delete_confirm:set_callback(on_delete);
    menu.info.presets.list:set_callback(update_list, true);

    events.shutdown(save_database)
    save_database();
end
 
local conditions = {};  do

    function conditions.get(is_legit_aa)
        local player = entity.get_local_player()

        if player == nil or not player:is_alive() then
            return;
        end

        local animstate = player:get_anim_state();

        if animstate == nil then
            return
        end

        local duck_amount = player.m_flDuckAmount;
        local speed = player.m_vecVelocity:length2d();

        local on_ground = animstate.on_ground and not animstate.landed_on_ground_this_frame

        local team = player.m_iTeamNum == 2 and "T" or "CT";

        local legit_data = menu.antiaim.angles.builder["Legit AA"][team];
        local freestand_data = menu.antiaim.angles.builder["Freestanding"][team];

        if is_legit_aa and legit_data.allow_state:get() then
            return "Legit AA";
        end

        if (reference.antiaim.angles.freestanding:get() or reference.antiaim.angles.freestanding:get_override()) and freestand_data.allow_state:get() then
            return "Freestanding";
        end

        if on_ground then
            if reference.antiaim.misc.slow_walk:get() then
                return "Slowing"
            end

            if speed < 5 then
                if duck_amount > 0 then
                    return "Crouching"
                end

                return "Standing"
            end

            if duck_amount > 0 then
                return "Sneaking"
            end

            return "Running"
        end

        return duck_amount > 0 and "Air Crouching" or "Air"
    end
end

local manual_aa = {}; do
    local list = {
        ["Forward"] = 180,
        ["Left"] = -90,
        ["Right"] = 90
    }

    function manual_aa.think()
        local value = menu.antiaim.main.additional.manual_yaw.select:get()

        if value == "Disabled" then
            return false, 0
        end

        local offset = list[value]

        if not offset then
            return false, 0
        end

        return true, offset;
    end

    function manual_aa.update(e, ctx, data)
        local is_manual_aa, offset = manual_aa.think();
        local is_static = menu.antiaim.main.additional.manual_yaw.static:get();
        local inverter = menu.antiaim.main.additional.manual_yaw.inverter:get();

        if is_manual_aa then
            ctx.yaw_offset = offset;
            ctx.yaw_base = "Local View"

            if is_static then
                ctx.yaw_modifier = "Disabled";
                rage.antiaim:inverter(inverter)
            end
        end
    end
end

local safe_head = {}; do

    function safe_head.think(e)
        local me = entity.get_local_player()

        if me == nil or not me:is_alive() then
            return false;
        end

        local weapon = me:get_player_weapon()

        if weapon == nil then
            return false;
        end

        if not menu.antiaim.main.additional.safe_head.switch:get() then
            return false;
        end

        local threat = entity.get_threat();

        if threat == nil or not threat:is_alive() then
            return false;
        end
        
        local class = weapon:get_classname();

        local is_knife = class == "CKnife";
        local is_zeus = class == "CWeaponTaser";

        local origin = me:get_origin();
        local delta = origin - threat:get_origin();

        local height = menu.antiaim.main.additional.safe_head.height:get();

        return {
            ["Air Crouch"] = conditions.get() == "Air Crouching",
            ["Zeus"] = is_zeus,
            ["Knife"] = is_knife,
            ["Height Advantage"] = delta.z >= height
        }
    end

    function safe_head.update(e, ctx, data)
        local is_safe_head_table = safe_head.think(e)

        if type(is_safe_head_table) == "boolean" and not is_safe_head_table then
            return
        end

        for name, value in pairs(is_safe_head_table) do
            if menu.antiaim.main.additional.safe_head.states:get(name) then
                if value then
                    ctx.body_yaw = true;
                    ctx.yaw_offset = 0;
                    ctx.left_limit = 1;
                    ctx.right_limit = 1;
                    ctx.body_yaw_options = {};
                    ctx.yaw_modifier = "Disabled";
                    return true;
                end
            end
        end
    end
end

local warmup_aa = {}; do
    local distortion = 0;

    function warmup_aa.think()
        local me = entity.get_local_player();
    
        if me == nil or not me:is_alive() then
            return false;
        end

        local game_rules = entity.get_game_rules();

        if game_rules == nil then
            return false;
        end

        local mode = menu.antiaim.main.additional.warmup_aa.select:get()

        if mode == "Disabled" then
            return false;
        end

        local are_all_enemies_dead = true

        for i=1, globals.max_players do
            local player = entity.get(i)
            
            if player ~= nil then
                local player_resource = player:get_resource();

                if player_resource.m_bConnected and player_resource.m_bConnected == true then
                    if player:is_enemy() and player:is_alive() then
                        are_all_enemies_dead = false;
                        break;
                    end
                end
            end
        end


        local check_for_idiots = game_rules.m_bWarmupPeriod;
        
        if not check_for_idiots then
            check_for_idiots = are_all_enemies_dead;

            if not check_for_idiots then
                check_for_idiots = game_rules.m_bWarmupPeriod
            end
        end

        return {
            ["Warmup"] = game_rules.m_bWarmupPeriod,
            ["No Enemies"] = are_all_enemies_dead,
            ["Force"] = check_for_idiots     
        }
    end

    function warmup_aa.update(e, ctx, data)
        local is_warmup_aa_table = warmup_aa.think();

        if type(is_warmup_aa_table) ~= "boolean" and not is_warmup_aa_table then
            return
        end

        local mode = menu.antiaim.main.additional.warmup_aa.select:get()

        if mode == "Disabled" then
            return;
        end

        local yaw = menu.antiaim.main.additional.warmup_aa.yaw:get();
        
        local range = menu.antiaim.main.additional.warmup_aa.range:get();
        local speed = menu.antiaim.main.additional.warmup_aa.speed:get();

        local left_yaw = menu.antiaim.main.additional.warmup_aa.left_yaw:get();
        local right_yaw = menu.antiaim.main.additional.warmup_aa.right_yaw:get();

        if is_warmup_aa_table[ mode ] and mode ~= "Disabled" then
            ctx.pitch = menu.antiaim.main.additional.warmup_aa.pitch:get();
            ctx.yaw = "Backward";
            ctx.yaw_modifier = "Disabled";
            
            if yaw == "L&R" then
                ctx.body_yaw = true;
                ctx.body_yaw_options = {"Jitter"}
                ctx.yaw_offset = rage.antiaim:inverter() and left_yaw or right_yaw
            else
                if yaw == "Distortion" then
                    if globals.tickcount % speed == 0 then
                        distortion = utils.random_int(-range, range)
                    end

                    ctx.yaw_offset = distortion
                end

                if yaw == "Spin" then
                    ctx.yaw_offset = (globals.framecount * (speed * .1)) % range
                end

                ctx.body_yaw = false; 
            end
        end
    end
end

local legit_aa = {}; do
    legit_aa.is_working = false;

    local function is_pickup_available(player)
        local eye_position = player:get_eye_position();
        local camera_angles = render.camera_angles();
        local forward = vector():angles(camera_angles)
        local eye_angle = eye_position + forward * 128

        local trace = utils.trace_line(eye_position, eye_angle, 0xFFFFFFFF)
        if trace.entity == nil then
            return false
        end

        local classname = trace.entity:get_classname()

        if classname:find("Weapon") or classname:find("Door") then
            return true
        end

        return false
    end

    local function is_bomb_defuse(player)
        if player.m_iTeamNum ~= 3 then
            return false;
        end

        local origin_ = player:get_origin()

        local CPlantedC4 = entity.get_entities("CPlantedC4");

        for i = 1, #CPlantedC4 do
            local c4 = CPlantedC4[i];

            if c4 == nil then
                return false;
            end
            
            local origin = c4:get_origin()

            if origin == nil then
                return false;
            end
            
            if c4.m_bBombTicking and origin_:dist(origin) < 87.5 then
                return true;
            end
        end
    end

    local function is_hostage_pickup(player)
        local eye_position = player:get_eye_position();
        local camera_angles = render.camera_angles();
        local forward = vector():angles(camera_angles)
        local eye_angle = eye_position + forward * 128

        local mins = vector(-1, -1, -1)
        local maxs = vector(1, 1, 1)

        local mask = bit.bor(0x1, 0x2, 0x8, 0x4000, 0x2000000)

        local trace = utils.trace_hull(eye_position, eye_angle, mins, maxs, player, mask)

        if trace.entity == nil then
            return false;
        end

        local origin = player:get_origin();
        if origin:dist(trace.entity:get_origin()) < 125 and trace.entity:get_classid() == 97 then
            return true;
        end
    
        return false;
    end

    local function is_use_needed(e, player, weapon)
        if weapon then
            local wpn_classname = weapon:get_classname();

            if wpn_classname == 'CC4' then
                return true
            end
        end

        if is_pickup_available(player) then
            return true;
        end

        if is_bomb_defuse(player) then
            return true;
        end

        if is_hostage_pickup(player) then
            return true;
        end

        return false;
    end

    function legit_aa.think(e)
        local me = entity.get_local_player()

        if me == nil or not me:is_alive() then
            return false;
        end

        local weapon = me:get_player_weapon()

        if weapon == nil then
            return false;
        end

        if not menu.antiaim.main.additional.legit_aa.enabled:get() then
            return false;
        end

        if not e.in_use then
            return false;
        end

        if is_use_needed(e, me, weapon) then
            return false;
        end


        return true;
    end

    function legit_aa.update(e, ctx, data)
        legit_aa.is_working = legit_aa.think(e);
        if not legit_aa.is_working then
            return
        end

        e.in_use = false;

        ctx.pitch = "Disabled";
        ctx.yaw_base = menu.antiaim.main.additional.legit_aa.mode:get();
    end
end

local break_lc = {}; do
    local current_slider = 1;
    local switch_delay = 0;

    function break_lc.think(e)
        local me = entity.get_local_player();

        if me == nil or not me:is_alive() then
            return false;
        end

        local weapon = me:get_player_weapon()

        if weapon == nil then
            return false;
        end

        local state = conditions.get();

        if not menu.antiaim.angles.break_lc.select:get(state) then
            return false;
        end

        if menu.antiaim.angles.break_lc.disable_on_grenade:get() and weapon:get_weapon_info().weapon_type == 9 then
            return false;
        end
        
        return true;
    end

    function break_lc.update(e, ctx, data)
        local is_break_lc = break_lc.think(e);

        if not is_break_lc then
            return
        end

        local choke_mode = data.choke:get();
        local choke_random = data.random_choke:get();
        local choke_slider = data.choke_slider:get();
        local choke_method = data.choke_method:get();
        local choke_from = data.choke_from:get();
        local choke_to = data.choke_to:get();
        local choke_sliders = data.choke_sliders:get();

        if e.choked_commands == 0 then
            switch_delay = switch_delay + 1;
            local current_slider_value = data["choke1_" .. current_slider]:get() or 1;
            current_slider_value = math.max(current_slider_value, 1)
            
            if choke_sliders >= current_slider_value then
                switch_delay = 0;
                current_slider = current_slider + 1
                if current_slider > choke_sliders then
                    current_slider = 1
                end
            end
        end

        if choke_mode == "Custom" then
            if not choke_random then
                if globals.tickcount % choke_slider == 0 then
                    ctx.lag_options = "Always On";
                end
            else
                if choke_method == "Default" then
                    local slider = 1;

                    if globals.tickcount % choke_from == 0 then
                        slider = slider + 1;

                        if slider >= 3 then
                            slider = 1
                        end
                    end

                    local ui_slider = slider == 1 and choke_from or choke_to
                    if globals.tickcount % ui_slider == 0 then
                        ctx.lag_options = "Always On";
                    end
                else
                    local choke_value = data["choke1_" .. current_slider]:get() or 1;
                    if globals.tickcount % choke_value == 0 then
                        ctx.lag_options = "Always On"
                    end
                end
            end
        else
            ctx.lag_options = "Always On";
        end

        ctx.hs_options = menu.antiaim.angles.break_lc.hide_shots:get();
    end
end

local freestanding = {}; do

    local function condition_for_freestand()
        -- fuck it
        local player = entity.get_local_player()

        if player == nil or not player:is_alive() then
            return;
        end

        local animstate = player:get_anim_state();

        if animstate == nil then
            return
        end

        local duck_amount = player.m_flDuckAmount;
        local speed = player.m_vecVelocity:length2d();

        local on_ground = animstate.on_ground and not animstate.landed_on_ground_this_frame

        local team = player.m_iTeamNum == 2 and "T" or "CT";

        local legit_data = menu.antiaim.angles.builder["Legit AA"][team];

        if is_legit_aa and legit_data.allow_state:get() then
            return "Legit AA";
        end

        if on_ground then
            if reference.antiaim.misc.slow_walk:get() then
                return "Slowing"
            end

            if speed < 5 then
                if duck_amount > 0 then
                    return "Crouching"
                end

                return "Standing"
            end

            if duck_amount > 0 then
                return "Sneaking"
            end

            return "Running"
        end

        return duck_amount > 0 and "Air Crouching" or "Air"
    end
    function freestanding.think(e)
        local fs_condition = condition_for_freestand(legit_aa.is_working);
        if menu.antiaim.angles.freestanding.disablers:get(fs_condition) then
            return false;
        end

        if not menu.antiaim.angles.freestanding.switch:get() then
            return false;
        end

        return true
    end

    function freestanding.update(e, ctx, data)
        local is_freestanding = freestanding.think(e)

        ctx.freestanding = is_freestanding;
        ctx.body_freestanding = menu.antiaim.angles.freestanding.body_fs:get()
        ctx.disable_yaw_modifiers = menu.antiaim.angles.freestanding.yaw_mod:get()
    end
end

local anti_bruteforce = {}; do

    local last_tick_triggered = 0;
    local reset_time = 0;
    local is_working = false;

    local offset = 0;

    function anti_bruteforce.reset()
        is_working = false;
        last_tick_triggered = 0;
        reset_time = 0;
        offset = 0;
    end
    

    function anti_bruteforce.think(e)
        if not menu.antiaim.angles.anti_bruteforce.switch:get() then
            return false;
        end

        if not menu.antiaim.angles.anti_bruteforce.states:get(conditions.get(legit_aa.is_working)) then
            return false
        end

        return true;
    end

    function anti_bruteforce.bullet_impact(e)
        local player = entity.get_local_player()

        if player == nil or not player:is_alive() then
            return
        end

        local userid = entity.get(e.userid, true)
    
        if userid == nil or not userid:is_alive() or userid:is_dormant() or not userid:is_enemy() then
            return
        end

        if last_tick_triggered == globals.tickcount then 
            return 
        end

        local impact = vector(e.x, e.y, e.z)
        local userid_pos = userid:get_eye_position()
        local player_pos = player:get_hitbox_position(0);
        local distance = player_pos:closest_ray_point(userid_pos, impact):dist(player_pos)
    
        if distance > 40 then 
            return
        end

        notify.new({
            "Anti-Bruteforce updated by ",
            userid:get_name(),
            "'s shot ",
            "", 
            "[", 
            offset, 
            "°;", 
            math.floor(tostring(distance)), 
            "]"
        }, ui.get_style()["Link Active"], "sparkles")
    
        last_tick_triggered = globals.tickcount
        reset_time = globals.realtime + 3
    
        local mode = menu.antiaim.angles.anti_bruteforce.mode:get();

        if mode == "Increasing" then
            offset = math.random(-5, 10)
        elseif mode == "Decreasing" then
            offset = 5
        else
            offset = math.random(-15, 15)
        end
    end

    function anti_bruteforce.update(e, ctx)
        if not anti_bruteforce.think(e) then
            return
        end

        if reset_time <= globals.realtime then
            anti_bruteforce.reset()
        else
            is_working = true
        end

        if not is_working then
            return
        end

        ctx.yaw_offset = ctx.yaw_offset + (rage.antiaim:inverter() and offset or -offset)
    end

    events.bullet_impact(anti_bruteforce.bullet_impact)
end

local instance = {}; do

    local antiaim = {}; do
        function antiaim:reset()
            for key, value in pairs(reference.antiaim.angles) do
                value:override();
            end
        end

        function antiaim:define()
            self.pitch = nil;
            self.yaw = nil;
            self.yaw_offset = nil;
            self.yaw_base = nil;
            self.yaw_modifier = nil;
            self.modifier_offset = nil;
            self.left_limit = nil;
            self.right_limit = nil;

            self.body_yaw = nil;
            self.body_yaw_options = nil;

            self.disable_yaw_modifiers = nil;
            self.body_freestanding = nil;

            self.freestanding = nil;
            self.freestand_peek = nil;

            self.lag_options = nil;
            self.hs_options = nil;

            self.avoid_backstab = nil;

            self.ignore_inverter = false;
        end

        function antiaim:run()
            local pitch = self.pitch or "Disabled";
            reference.antiaim.angles.pitch:override(pitch);

            local yaw = self.yaw or "Disabled";
            reference.antiaim.angles.yaw:override(yaw);

            local yaw_offset = self.yaw_offset or 0;
            reference.antiaim.angles.yaw_add:override(yaw_offset);

            local yaw_base = self.yaw_base or "Local View";
            reference.antiaim.angles.yaw_base:override(yaw_base);

            local yaw_modifier = self.yaw_modifier or "Disabled";
            reference.antiaim.angles.yaw_modifier:override(yaw_modifier);

            local modifier_offset = self.modifier_offset or 0;
            reference.antiaim.angles.modifier_offset:override(modifier_offset);

            local left_limit, right_limit = self.left_limit or 0, self.right_limit or 0;
            reference.antiaim.angles.left_limit:override(left_limit);
            reference.antiaim.angles.right_limit:override(right_limit);

            local body_yaw = self.body_yaw or false;
            reference.antiaim.angles.body_yaw:override(body_yaw);

            local body_yaw_options = self.body_yaw_options or {};
            reference.antiaim.angles.options:override(body_yaw_options);

            local disable_yaw_modifiers = self.disable_yaw_modifiers or false;
            reference.antiaim.angles.disable_yaw_modifiers:override(disable_yaw_modifiers);

            local body_freestanding = self.body_freestanding or false;
            reference.antiaim.angles.body_freestanding:override(body_freestanding);

            local freestanding = self.freestanding or false;
            reference.antiaim.angles.freestanding:override(freestanding);

            local freestand_peek = self.freestand_peek or "Off";
            reference.antiaim.angles.freestand_peek:override(freestand_peek);

            local lag_options = self.lag_options or "On Peek";
            reference.rage.main.double_tap_lag_options:override(lag_options)

            local hs_options = self.hs_options or "Favor Fire Rate";
            reference.rage.main.hide_shots_options:override(hs_options)

            local avoid_backstab = self.avoid_backstab or false;
            reference.antiaim.angles.avoid_backstab:override(avoid_backstab);
        end

        antiaim:reset()
    end

    instance.create_antiaim = function()
        return setmetatable({}, {__index = antiaim})
    end
end

local builder = {}; do
    local data = instance.create_antiaim();

    local current_slider = 1;
    local current_modifier_slider = 1;

    local switch_delay = 0;
    local switch_modifier = 0;

    local side = false;
    local switch = false;

    local ticks = 0;
    local bobro = 1;

    local from_to_ticks = 0;
    local from_to_swap = false;

    function builder.get_exploit_values(offset, index)
        return ({
            [1] = -offset,
            [2] = -offset/2,
            [3] = -offset/3,
            [4] = offset/3,
            [5] = offset/2,
            [6] = offset
        })[index or 1]
    end

    function builder.get_preset(state, team)
        local items = menu.antiaim.angles.builder[state]

        if items == nil then
            return nil
        end

        return items[team]
    end

    function builder.update_yaw(e, ctx, data)
        ctx.pitch = "Down";
        ctx.yaw = data.yaw:get();
        ctx.yaw_base = "At Target";

        local yaw_type = data.yaw_mode:get();
        local is_delay = data.delay:get();

        local left_yaw = data.yaw_left:get();
        local right_yaw = data.yaw_right:get();

        local delay_mode = data.delay_method:get();
        local delay_ticks = data.delay_default:get();
        
        local min_delay = data.delay_random_min:get();
        local max_delay = data.delay_random_max:get();

        local delay_sliders = data.delay_custom_sliders:get();
        local current_slider_value = data["delay_" .. current_slider]:get() or 1;
        current_slider_value = math.max(current_slider_value, 1);

        local div = 1.95

        if yaw_type == "Solo" then
            ctx.yaw_offset = data.offset:get();
        elseif yaw_type == "L/R" then

            if is_delay then
                if e.choked_commands == 0 then
                    switch_delay = switch_delay + 1

                    if delay_mode == "Default" then
                        if switch_delay >= delay_ticks/div then
                            switch_delay = 0;
                            side = not side;
                        end
                    elseif delay_mode == "Random" then
                        if switch_delay >= utils.random_int(min_delay, max_delay)/div then
                            switch_delay = 0;
                            side = not side;
                        end
                    else
                        if switch_delay >= current_slider_value/div then
                            switch_delay = 0;
                            side = not side;

                            current_slider = current_slider + 1

                            if current_slider > delay_sliders then
                                current_slider = 1;
                            end
                        end
                    end
                end
                
                rage.antiaim:inverter(side);
                ctx.yaw_offset = side and left_yaw or right_yaw;
            else
                ctx.yaw_offset = rage.antiaim:inverter() and left_yaw or right_yaw;
            end
        end
    end

    function builder.update_body_yaw(e, ctx, data)
        local body_yaw = data.body_yaw:get();
        local body_yaw_options = data.body_yaw_options:get();
        local body_yaw_mode = data.mode:get()
        local body_yaw_ticks = data.mode_ticks:get();
        local body_yaw_ticks_random = data.mode_random:get();

        if body_yaw_mode == "Static" then
            ctx.body_yaw = body_yaw;
        elseif body_yaw_mode == "Ticks" and not reference.antiaim.misc.fake_duck:get() then
            local amount = body_yaw_ticks;

            if globals.tickcount % amount == 0 then
                switch = not switch
                ticks = 0
            end

            if not switch then
                ticks = ticks + 1
            end

            if ticks >= utils.random_int(2, 6) then
                switch = true
                ticks = 0
            end

            local trigger = utils.random_int(3, 6)


            if trigger == 1 or trigger == 2 then
                trigger = 9
            else
                trigger = trigger + 1
            end

            ctx.body_yaw = switch
        elseif body_yaw_mode == "Random" and not reference.antiaim.misc.fake_duck:get() then
            ctx.body_yaw = globals.tickcount % body_yaw_ticks_random == 0;
        end

        local body_yaw_limit_mode = data.limit_mode:get();
        local body_yaw_limit_minimum = data.minimum_limit:get();
        local body_yaw_limit_maximum = data.maximum_limit:get();

        local body_yaw_limit_from = data.from_limit:get();
        local body_yaw_limit_to = data.to_limit:get();

        local inverter = rage.antiaim:inverter();
        
        if body_yaw_limit_mode == "Speed-based Switch" then
            if e.choked_commands == 0 then
                from_to_ticks = from_to_ticks + 1
            end

            if from_to_ticks >= data.sb_speed:get() then
                from_to_ticks = 0;
                from_to_swap = not from_to_swap;
            end

            inverter = from_to_swap;
        end

        local left, right = 0, 0; do
            if body_yaw_limit_mode == "Static" then
                left = data.left_limit:get();
                right = data.right_limit:get();
            elseif body_yaw_limit_mode == "Random" then
                left = math.random(body_yaw_limit_minimum, body_yaw_limit_maximum);
                right = math.random(body_yaw_limit_minimum, body_yaw_limit_maximum)
            else
                left = inverter and body_yaw_limit_from or body_yaw_limit_to;
                right = inverter and body_yaw_limit_from or body_yaw_limit_to;
            end

            ctx.left_limit = left;
            ctx.right_limit = right;
        end

        ctx.freestand_peek = data.body_freestanding:get()
        ctx.body_yaw_options = body_yaw_options;
    end
    
    function builder.update_modifier(e, ctx, data)
        local yaw_modifier = data.modifier:get();
        local yaw_modifier_mode = data.modifier_mode:get();
        local yaw_modifier_randomize = data.randomize:get();
        local yaw_modifier_minimum = data.min:get();
        local yaw_modifier_maximum = data.max:get();
        local yaw_modifier_sliders = data.modifier_custom_sliders:get();
        local yaw_modifier_offset = data.modifier_offset:get();

        local current_slider_value = data["modifier_sliders_" .. current_modifier_slider]:get() or 1;
        current_slider_value = math.max(current_slider_value, 1);

        if e.choked_commands == 0 then  
            bobro = bobro + 1;
            if bobro >= 7 then
                bobro = 1;
            end
        end


        if yaw_modifier_randomize then
            if yaw_modifier_mode == "Default" then
                local value = math.random(yaw_modifier_minimum, yaw_modifier_maximum);
                ctx.modifier_offset = yaw_modifier == "Bobro" and builder.get_exploit_values(value, bobro) or value; 
            elseif yaw_modifier_mode == "Custom" then
                if e.choked_commands == 0 then
                    switch_modifier = switch_modifier + 1;
                    if switch_modifier >= current_slider_value then
                        switch_modifier = 0;
                        current_modifier_slider = current_modifier_slider + 1;

                        if current_modifier_slider > yaw_modifier_sliders then
                            current_modifier_slider = 1;
                        end
                    end
                end

                local default_value = data["modifier_sliders_" .. current_modifier_slider]:get();
                local bober_value = builder.get_exploit_values(default_value, bobro);
                ctx.modifier_offset = yaw_modifier == "Bobro" and bober_value or default_value;
            end
        else
            local bober_value = builder.get_exploit_values(yaw_modifier_offset, bobro);
            ctx.modifier_offset = yaw_modifier == "Bobro" and bober_value or yaw_modifier_offset;
        end

        ctx.yaw_modifier = yaw_modifier == "Bobro" and "3-Way" or yaw_modifier;
    end 

    function builder.update(e, condition, player)
        data:define();

        local team = player.m_iTeamNum == 2 and "T" or "CT";
        local items = builder.get_preset(condition, team)

        if items == nil then
            return
        end

        if not items.allow_state:get() then goto continue end

        data.avoid_backstab = menu.antiaim.main.additional.backstab.switch:get();
        
        builder.update_yaw(e, data, items)
        builder.update_body_yaw(e, data, items)
        builder.update_modifier(e, data, items)

        anti_bruteforce.update(e, data)

        break_lc.update(e, data, items)
        warmup_aa.update(e, data, items)

        local is_legit_aa = legit_aa.think(e);
        if is_legit_aa then
            legit_aa.update(e, data, items)
            data:run()
            return
        end;

        safe_head.update(e, data, items)
        
        local is_manual_aa = manual_aa.think()
        local is_freestand = freestanding.think()
        

        if menu.antiaim.angles.freestanding.prefer_manual:get() and is_manual_aa then
            manual_aa.update(e, data, items)
        elseif is_freestand then
            freestanding.update(e, data, items)
        else
            manual_aa.update(e, data, items)
        end


        data:run()

        ::continue::
    end

    local function callback(e)
        local me = entity.get_local_player()
        local is_legit_aa = legit_aa.think(e)
        local condition = conditions.get(is_legit_aa);

        builder.update(e, condition, me)
    end

    events.createmove(callback)
end

local player_animations = {}; do
    local animlayer_t = ffi.typeof [[
        struct { 
            bool client_blend; 
            float blend_in; 
            void *studio_hdr; 
            int dispatch_sequence; 
            int second_dispatch_sequence; 
            uint32_t order; 
            uint32_t sequence; 
            float prev_cycle; 
            float weight; 
            float weight_delta_rate; 
            float playback_rate; 
            float cycle; 
            void *entity; 
            char pad_0x0038[0x4]; 
        } **
    ]];

    function player_animations.get_anim_overlay(player, idx)
        return ffi.cast(animlayer_t, ffi.cast("char*", player[0]) + 0x2990)[0][idx]
    end
    
    local in_use = false;

    local function createmove(e)
        in_use = e.in_use;
        
        if menu.misc.player_animations.jitter_legs.switch:get() then
            reference.antiaim.misc.leg_movement:override(e.command_number % 3 == 0 and "Walking" or "Sliding")
        else
            reference.antiaim.misc.leg_movement:override()
        end
    end
    local function apply(player)
        if not menu.misc.player_animations.jitter_legs.switch:get() then
            return
        end

        local me = entity.get_local_player()

        if me == nil or not me:is_alive() then
            return
        end

        local weapon = me:get_player_weapon()

        if weapon == nil then
            return
        end

        if me ~= player then
            return
        end

        local overlay = player_animations.get_anim_overlay(player, 12)
        if overlay and me.m_vecVelocity:length2d() > 5 then
            overlay.weight = menu.misc.player_animations.leaning.value:get() / 100;
        end

        if weapon:get_index() == 668 then
            if in_use then
                local bomb_overlay = player_animations.get_anim_overlay(player, 10);

                if bomb_overlay then
                    bomb_overlay.weight = 1
                    bomb_overlay.sequence = 200;
                    bomb_overlay.cycle = 0.1 
                end
            end
        end

        local from = menu.misc.player_animations.jitter_legs.from:get() / 100;
        local to = menu.misc.player_animations.jitter_legs.to:get() / 100;


        if menu.misc.player_animations.jitter_legs.switch:get() then
            player.m_flPoseParameter[0] = (globals.clock_offset + globals.client_tick) % 3 == 0 and from or to
        end

        me.m_flPoseParameter[6] = menu.misc.player_animations.falling.value:get() / 100;
    end

    events.post_update_clientside_animation(apply)
    events.createmove(createmove);
end

local unlock_fakeduck_speed do
    local function apply(e)
        if not menu.misc.aimbot.fakeduck.unlock:get() then
            return
        end

        if not reference.antiaim.misc.fake_duck:get() then
            return
        end

        local threshold = 5.0
        local forwardmove = e.forwardmove
        local sidemove = e.sidemove
        
        if math.abs(forwardmove) > threshold or math.abs(sidemove) > threshold then
            local speed = (forwardmove * forwardmove + sidemove * sidemove) ^ 0.5
            local factor = 450 / speed
            e.forwardmove = forwardmove * factor
            e.sidemove = sidemove * factor
        end
    end

    events.createmove_run(apply)
end

local unlock_freeze_period do

    local function createmove(e)
        if not menu.misc.aimbot.fakeduck.freeze_period:get() then
            return
        end

        if not reference.antiaim.misc.fake_duck:get() then
            return
        end

        local rules = entity.get_game_rules()
        if not rules then 
            return 
        end

        if not rules.m_bFreezePeriod then
            return
        end

        e.in_bullrush = true
    
        if e.choked_commands < 7 then
            e.in_duck = false
        else
            e.in_duck = true
        end
        
        e.send_packet = not e.choked_commands == 14
    end

    local function on_override_view(ctx)
        local me = entity.get_local_player()
        
        if me == nil or not me:is_alive() then
            return
        end

        local rules = entity.get_game_rules()
        if not rules then 
            return 
        end

        if not rules.m_bFreezePeriod then
            return
        end
        
        local offset = ctx.camera;
        if menu.misc.aimbot.fakeduck.freeze_period:get() and reference.antiaim.misc.fake_duck:get() then
            ctx.camera = vector(
                offset.x,
                offset.y,
                offset.z - me.m_vecViewOffset.z + 64
            )
        end
    end

    events.createmove(createmove)
    events.override_view(on_override_view)
end


local events_logging do
    local jmp_ecx = utils.opcode_scan('engine.dll', 'FF E1')
    local fnGetModuleHandle = ffi.cast('uint32_t(__fastcall*)(unsigned int, unsigned int, const char*)', jmp_ecx)
    local fnGetProcAddress = ffi.cast('uint32_t(__fastcall*)(unsigned int, unsigned int, uint32_t, const char*)', jmp_ecx)
    local pGetProcAddress = ffi.cast('uint32_t**', ffi.cast('uint32_t', utils.opcode_scan('engine.dll', 'FF 15 ? ? ? ? A3 ? ? ? ? EB 05')) + 2)[0][0]
    local pGetModuleHandle = ffi.cast('uint32_t**', ffi.cast('uint32_t', utils.opcode_scan('engine.dll', 'FF 15 ? ? ? ? 85 C0 74 0B')) + 2)[0][0]
    
    local function proc_bind(sModuleName, sFunctionName, sTypeOf)
        local ctype = ffi.typeof(sTypeOf)
        return function(...)
            return ffi.cast(ctype, jmp_ecx)(fnGetProcAddress(pGetProcAddress, 0, fnGetModuleHandle(pGetModuleHandle, 0, sModuleName), sFunctionName), 0, ...)
        end
    end
    
    local fnEnumDisplaySettingsA = proc_bind('user32.dll', 'EnumDisplaySettingsA', 'int(__fastcall*)(unsigned int, unsigned int, unsigned int, unsigned long, void*)');
    local pLpDevMode = ffi.new('struct { char pad_0[120]; unsigned long dmDisplayFrequency; char pad_2[32]; }[1]')
    
    fnEnumDisplaySettingsA(0, 4294967295, pLpDevMode[0])

    local function fps_problem()
        local fps = 1 / globals.absoluteframetime;
        local frequency = tonumber(pLpDevMode[0].dmDisplayFrequency)
        local is_fps = fps < frequency or fps <= 30;

        if is_fps and menu.misc.aimbot.logging.mode.select:get(3) then
            notify.new({
                "Alert! ",
                "FPS ",
                "is too ",
                "low ", "[", math.floor(fps),":",frequency,"]",""
            }, ui.get_style()["Link Active"])
    
        end

        utils.execute_after(5, fps_problem)
    end

    local function connection_error()
        local me = entity.get_local_player();

        if me == nil or not me:is_alive() then
            return;
        end

        local resource = me:get_resource();

        if resource == nil then
            return
        end

        local net_channel = utils.net_channel();

        if net_channel == nil then
            return
        end

        local loss = (net_channel.loss[0] + net_channel.loss[1]) * 100;

        if (loss >= 8 or resource.m_iPing >= 120) and menu.misc.aimbot.logging.mode.select:get(2) then
            notify.new({
                "Alert! ",
                "Connection ",
                "issue detected ",
                "", "[", math.floor(loss),":",resource.m_iPing,"]",""
            }, ui.get_style()["Link Active"])
    
        end

        utils.execute_after(5, connection_error)
    end

    connection_error();
    fps_problem();
end

local aimbot_logs do
    local hitgroup_str = {
        [0] = 'generic',
        'head', 'chest', 'stomach',
        'left arm', 'right arm',
        'left leg', 'right leg',
        'neck', 'generic', 'gear'
    }

    local function fmt(str, color) 
        return "\a" .. color .. str .. "\aDEFAULT" 
    end

    local function aim_ack(e)
        if not menu.misc.aimbot.logging.switch:get() then
            return;
        end

        if not menu.misc.aimbot.logging.mode.select:get(1) then
            return;
        end

        local me = entity.get_local_player();

        if me == nil or not me:is_alive() then
            return;
        end

        local target = e.target;

        if target == nil then
            return;
        end

        local prefix = menu.misc.aimbot.logging.colors.prefix:get():to_hex();
        local accent = menu.misc.aimbot.logging.colors.main:get():to_hex();

        local name = fmt(target:get_name(), accent)
        local script = fmt(_G.SCRIPT_NAME, prefix)
        local hc = fmt(e.hitchance, accent)
        local bt = fmt(e.backtrack, accent)
        local bt_ms = fmt(math.floor(to_time(e.backtrack) * 1000), accent)

        if e.state == nil then
            local hitgroup = fmt(hitgroup_str[e.hitgroup], accent)..(e.wanted_hitgroup ~= e.hitgroup and fmt("("..hitgroup_str[e.wanted_hitgroup]..")", "DEFAULT") or "")
            local damage = fmt(e.damage, accent)..(e.wanted_damage ~= e.damage and fmt("("..e.wanted_damage..")", "DEFAULT") or "")

            if menu.misc.aimbot.logging.mode.is_notification:get() then
                notify.new({
                    "Hit ",
                    target:get_name(),
                    "'s ",
                    hitgroup_str[e.hitgroup],
                    " for ",
                    e.damage,
                    " damage"
                }, ui.get_style()["Link Active"], "poo-storm")
            end

            print_dev(("%s · Hit %s's %s for %s damage [hc: %s%% · bt: %st]"):format(script, name, hitgroup, damage, hc, bt))
            print_raw(("%s · Hit %s's %s for %s damage [hc: %s%% · bt: %st(%sms)]"):format(script, name, hitgroup, damage, hc, bt, bt_ms))
        else
            local wanted_dmg = fmt(e.wanted_damage, accent)
            local wanted_hg = fmt(hitgroup_str[e.wanted_hitgroup], accent)
            local state = fmt(e.state, accent)

            if menu.misc.aimbot.logging.mode.is_notification:get() then
                notify.new({
                    "Missed ",
                    target:get_name(),
                    " in ",
                    hitgroup_str[e.wanted_hitgroup],
                    " due to ",
                    e.state
                }, color(255, 0, 0, 255), "poo")
            end

            print_dev(("%s · Missed %s's %s due to %s [dmg: %s · hc: %s%% · bt: %st]"):format(script, name, wanted_hg, state, wanted_dmg, hc, bt))
            print_raw(("%s · Missed %s's %s due to %s [dmg: %s · hc: %s%% · bt: %st(%sms)]"):format(script, name, wanted_hg, state, wanted_dmg, hc, bt, bt_ms))
        end
    end

    events.aim_ack(aim_ack);
end
local watermark = {}; do
    watermark.window = windows:new("watermark", vector(screen.x / 2, screen.y * 0.8));


    local holding = smoothy.new(0);
    function watermark.frame()
        local window = watermark.window
        local watermark_info = menu.info.watermark
        local font_map = {
            ["Default"] = 1,
            ["Small"] = 2, 
            ["Console"] = 3,
            ["Bold"] = 4
        }

        local text = _G.SCRIPT_NAME
        if watermark_info.mode:get(1) then
            local custom_text = watermark_info.text:get():gsub(" ", "")
            if custom_text ~= "" then
                text = watermark_info.text:get()
            end
        end

        if watermark_info.mode:get(2) then
            if watermark_info.gradient:get() then
                local colors = watermark_info.color
                text = text_effects:animate(
                    watermark_info.speed:get(),
                    colors:get("Outter")[1], 
                    colors:get("Inner")[1],
                    text
                )
            else
                text = "\a" .. watermark_info.non_gradient:get():to_hex() .. text
            end
        end

        local font = 1
        if watermark_info.mode:get(3) then
            font = font_map[watermark_info.font:get()] or 1
        end

        local is_dragging = window:is_dragging();

        holding(.05, is_dragging and .6 or 1)

        local pos = window.position;
        local text_size = render.measure_text(1, nil, text);

        render.text(font, pos, color(255, 255 * holding.value), nil, text)
        window:update(text_size);
    end

    events.render(watermark.frame)
end

local sidebar do
    local function update()
        if ui.get_alpha() <= 0 then
            return
        end

        local text = menu.info.sidebar.text:get();
        if text:gsub(" ", "") == "" then text = _G.SCRIPT_NAME; end

        local speed = menu.info.sidebar.speed:get();
        local from, to = menu.info.sidebar.color:get("Outter")[1], menu.info.sidebar.color:get("Inner")[1]
        local animated = text_effects:animate(speed, from, to, text);
        ui.sidebar(animated, "👑")
    end

    events.render(update);
end

local scope_overlay do
    local alpha = smoothy.new(0);
    local scope = smoothy.new(0);

    local ref = ui.find("Visuals", "World", "Main", "Override Zoom", "Scope Overlay")

    local function on_draw()
        local me = entity.get_local_player()

        if me == nil or not me:is_alive() then
            return
        end

        local weapon = me:get_player_weapon()

        if weapon == nil then
            return
        end
        
        local can_show_scope = menu.visuals.scope_overlay.switch:get();
        local is_scoped = me.m_bIsScoped

        alpha(.05, can_show_scope);
        scope(.05, can_show_scope and is_scoped);

        if alpha.value <= 0 then
            ref:override();
            return
        end

        ref:override("Remove All");

        local alpha = alpha.value * scope.value;

        local center = screen * 0.5

        local offset = menu.visuals.scope_overlay.gap:get() * screen.y * (1 / screen.y)
        local position = menu.visuals.scope_overlay.length:get() * screen.y * (1 / screen.y)

        offset = math.floor(offset)
        position = math.floor(position)

        local delta = position - offset

        local color_a = menu.visuals.scope_overlay.colors.main:get()
        local color_b = menu.visuals.scope_overlay.colors.edge:get()


        if menu.visuals.scope_overlay.options:get(2) then
            color_a = menu.visuals.scope_overlay.colors.edge:get();
            color_b = menu.visuals.scope_overlay.colors.main:get()
        end

        color_a.a = color_a.a * alpha; 
        color_b.a = color_b.a * alpha; 

        local rotation = 45;
        local should_rotate = menu.visuals.scope_overlay.options:get(1)
        if should_rotate and menu.visuals.scope_overlay.animation:get() and me.m_vecVelocity:length2d() >= 5 then
            rotation = globals.framecount % 360;
        end

        if should_rotate then
            render.push_rotation(rotation)
        end

        render.gradient(vector(center.x, center.y - offset + 1), vector(center.x + 1, center.y - position * alpha), color_a, color_a, color_b, color_b) -- up
        render.gradient(vector(center.x, center.y + offset), vector(center.x + 1, center.y + position * alpha), color_a, color_a, color_b, color_b) -- down
        render.gradient(vector(center.x - offset + 1, center.y), vector(center.x - offset + 1 - delta * alpha, center.y + 1), color_a, color_b, color_a, color_b) -- left
        render.gradient(vector(center.x + offset, center.y), vector(center.x + offset + delta * alpha + 1, center.y + 1), color_a, color_b, color_a, color_b) -- right

        if should_rotate then
            render.pop_rotation()
        end
    end

    events.render(on_draw)
end

local manual_arrows do
    local data = {
        ["Left"] = {
            text = menu.visuals.manual_arrows.symbols.left,
            size = vector(-10, 0),
            alpha = smoothy.new(0)
        },
        ["Right"] = {
            text = menu.visuals.manual_arrows.symbols.right,
            size = vector(12, 0),
            alpha = smoothy.new(0)
        },
        ["Forward"] = {
            text = menu.visuals.manual_arrows.symbols.forward,
            size = vector(0, -10),
            alpha = smoothy.new(0)  
        }
    }

    local function on_draw()
        local me = entity.get_local_player()

        if me == nil or not me:is_alive() then
            return
        end

        local center = render.screen_size() / 2
        local enabled = menu.visuals.manual_arrows.switch:get()
        local value = menu.antiaim.main.additional.manual_yaw.select:get()

        local font = ({
            ["Default"] = 1,
            ["Small"] = 2,
            ["Console"] = 3,
            ["Bold"] = 4
        })[menu.visuals.manual_arrows.font:get()];

        local accent = menu.visuals.manual_arrows.color:get();
        local offset = menu.visuals.manual_arrows.offset:get();

        local list = {
            ["Left"] = vector(-offset, 0),
            ["Right"] = vector(offset, 0),
            ["Forward"] = vector(0, -offset)
        }

        for i, ctx in pairs(data) do
            ctx.alpha(.04, value == i and enabled);

            if ctx.alpha.value <= 0 then goto continue end

            local alpha = ctx.alpha.value;
            if alpha > 0 then
                render.text(font, center + ctx.size + list[i], accent:alpha_modulate(alpha * accent.a), "c", ctx.text:get())
            end

            ::continue::
        end
    end

    events.render(on_draw)
end

local draw = {}; do
    draw.data = {};
    draw.icon = render.load_image_from_file('materials/panorama/images/icons/ui/bomb_c4.svg', vector(32, 32));
    draw.font = render.load_font("Calibri Bold", vector(25, 23.5, 0), "da");

    function draw.progress_bar(r, g, b, progress, height)
        local progress_height = height * progress;
        render.rect(vector(0, 0), vector(20, height), color(0, 0, 0, 120));
        render.rect(vector(1, (0 + progress_height) + 1), vector(19, ((((0 + progress_height) + 1) + height) - progress_height) - 3), color(r, g, b, 120));
    end

    function draw.indicator(color, text, pct, should_draw_bomb)
        draw.data[#draw.data + 1] = {
            clr = color, 
            text = text, 
            pct = pct or -1,
            should_draw_bomb = should_draw_bomb or false
        };
    end
end

local bomb = {}; do
    bomb.site = nil;
    bomb.plant_start_time = nil;
    bomb.planter = nil;
    
    local function on_reset()
        bomb.site = nil;
        bomb.planter = nil;
    end

    local function on_plant(event)
        local resource = entity.get_player_resource();

        if not resource then
            return
        end

        local a_center, b_center = resource.m_bombsiteCenterA, resource.m_bombsiteCenterB;
        local site_entity = entity.get(event.site);

        if not site_entity then
            return
        else
            local center = site_entity.m_vecMins:lerp(site_entity.m_vecMaxs, 0.5);

            bomb.site = center:distsqr(a_center) < center:distsqr(b_center) and "A" or "B";
            bomb.plant_start_time = globals.curtime;
            bomb.planter = entity.get(event.userid, true);
        end
    end
    
    function bomb.scale_damage(damage, armor)
        if armor > 0 then
            local reduced_damage = damage * 0.5;
            if armor < (damage - reduced_damage) * 0.5 then
                reduced_damage = damage - armor * 2;
            end;

            damage = reduced_damage;
        end;

        return damage;
    end

    events.bomb_beginplant(on_plant)
    events.bomb_abortplant(on_reset);
    events.bomb_planted(on_reset);
    events.round_start(on_reset);
    events.round_end(on_reset);
end

local skeet_indicators do
    local data = {};

    local function draw_indicator(text, color, should_draw_bomb, progress)
        table.insert(draw.data, {
            text = text,
            clr = color,
            should_draw_bomb = should_draw_bomb,
            pct = progress or -1
        })
    end

    local function get_lerp_time(entity)
        local v6 = 0
        local v7 = 0
        local v8 = 0
        local v10 = 0
        
        local net_channel = {
            [1] = utils.net_channel(),
            [2] = utils.net_channel()
        }
        
        if entity ~= nil and entity:is_alive() then
            net_channel[1] = utils.net_channel()
            net_channel[2] = net_channel[1]
        
            if net_channel[1] then
                v8 = net_channel[1].sequence_nr[0]
                v8 = net_channel[2].sequence_nr[1] + v8
        
                v6 = v8
        
                v10 = v6 / math.min(math.max(0.1, 0.001), 0.2)
                
                return math.clamp(-1.7014636e38, math.min(math.max(v10, 0), 1), v10)
            end
        end
    end

    local function get_value(ref)
        return ref:get() or ref:get_override()
    end

    local function draw_bomb_info(me, curtime)
        if not menu.visuals.skeet_indicators.bomb:get() then return end

        local bomb_entity = entity.get_entities(129)[1]
        if bomb_entity and bomb_entity.m_hBombDefuser ~= nil then
            local defuse_progress = 1 - (10 - (bomb_entity.m_flDefuseCountDown - curtime)) * 0.1
            if defuse_progress > 0 and defuse_progress < 1 then
                local color = bomb_entity.m_flC4Blow - curtime < bomb_entity.m_flDefuseCountDown - curtime 
                    and color(255, 0, 0, 200)
                    or color(44, 131, 52, 200)
                draw.progress_bar(color.r, color.g, color.b, 1 - defuse_progress, screen.y)
            end
        end

        if bomb.planter then
            local plant_progress = (curtime - bomb.plant_start_time) / 3.125
            if plant_progress > 0 and plant_progress < 1 and entity.get_game_rules().m_bBombPlanted ~= 1 then
                draw_indicator(bomb.site, color(251, 237, 117, 200), true, plant_progress)
            end
            return
        end

        local armor = me.m_ArmorValue
        local health = me.m_iHealth

        entity.get_entities("CPlantedC4", true, function(ctx)
            if ctx.m_bBombDefused then return end
            
            local blow_time = ctx.m_flC4Blow
            local site = ctx.m_nBombSite == 0 and "A" or "B"

            if blow_time - curtime >= 0 then
                draw_indicator(string.format("%s - %.1fs", site, blow_time - curtime), color(255, 255, 255, 200), true)

                if me:is_alive() then
                    local distance = me:get_eye_position():dist(ctx:get_origin())
                    local damage = bomb.scale_damage(
                        math.max(500 * math.exp(-((distance * distance) / ((1750 * 2) / 3) * (1750 / 3))), 0),
                        armor
                    )

                    if damage >= 1 then
                        if damage < health then
                            draw_indicator(string.format("-%d HP", damage), color(235, 236, 124, 200))
                        else
                            draw_indicator("FATAL", color(255, 0, 50, 200))
                        end
                    end
                end
            end
        end)
    end

    local function draw_features(me, is_alive)
        local features = menu.visuals.skeet_indicators.features
        local additional = menu.visuals.skeet_indicators.additional
        if #features:get() == 0 and #additional:get() == 0 then return end
        
        local features = {
            {
                text = "PING",
                condition = function() return features:get("Ping spike") and get_value(reference.ping_spike) > 0 and is_alive end,
                color = function()
                    local factor = get_lerp_time(me);
                    return color(255, 200):lerp(color(151, 175, 54, 200), factor)
                end
            },
            {
                text = "DUCK",
                condition = function() return features:get("Duck peek assist") and get_value(reference.antiaim.misc.fake_duck) end,
                color = color(255, 255, 255, 200)
            },
            {
                text = "OSAA", 
                condition = function() return features:get("On shot anti-aim") and get_value(reference.rage.main.hide_shots) and not get_value(reference.rage.main.double_tap) end,
                color = color(255, 255, 255, 200)
            },
            {
                text = "DT",
                condition = function() return features:get("Double tap") and get_value(reference.rage.main.double_tap) end,
                color = function() return rage.exploit:get() == 1 and color(255, 255, 255, 200) or color(255, 0, 50, 200) end
            },
            {
                text = "DA",
                condition = function() return additional:get("Dormant aimbot") and get_value(reference.rage.main.dormant_aimbot) end,
                color = color(255, 255, 255, 200)
            },
            {
                text = "SAFE",
                condition = function() return features:get("Force safe point") and get_value(reference.rage.selection.safe_points) == "Force" end,
                color = color(255, 255, 255, 200)
            },
            {
                text = "BODY",
                condition = function() return features:get("Force body aim") and get_value(reference.rage.selection.body_aim) == "Force" end,
                color = color(255, 255, 255, 200)
            },
            {
                text = "MD",
                condition = function() return features:get("Minimum damage override") and keybinds:get_state("Min. Damage")[2] end,
                color = color(255, 255, 255, 200)
            },
            {
                text = "H1TCHANCE",
                condition = function() return additional:get("Hitchance override") and keybinds:get_state("Hit Chance")[2] end,
                color = color(255, 255, 255, 200)
            },
            {
                text = "FS",
                condition = function() return features:get("Freestanding") and get_value(reference.antiaim.angles.freestanding) end,
                color = color(255, 255, 255, 200)
            }
        }

        for _, feature in ipairs(features) do
            if feature.condition() then
                local color = type(feature.color) == "function" and feature.color() or feature.color
                draw_indicator(feature.text, color)
            end
        end
    end

    local function draw_indicators()
        local position = vector(19, screen.y - 353)
        local add_y = 0
        
        for _, ctx in ipairs(draw.data) do
            if ctx.should_draw_bomb then
                ctx.text = "      \xE2\x80\x8A" .. ctx.text
            end

            local size = render.measure_text(draw.font, "d", ctx.text)
            size.y = size.y * 1.19

            render.gradient(
                position - vector(size.x, 4) + vector(0, add_y),
                position + vector(size.x, size.y) + vector(0, add_y),
                color(0, 0),
                color(0, 51),
                color(0, 0),
                color(0, 51)
            )

            render.gradient(
                position + vector(size.x + 0.5,  -4) + vector(0, add_y),
                position + vector(size.x * 1.5, size.y) + vector(0, add_y),
                color(0, 51),
                color(0, 0),
                color(0, 51),
                color(0, 0)
            )

            if ctx.pct ~= -1 then
                local circle_pos = vector(((position.x + 10) + size.x) + 20, ((position.y + add_y) + size.y * 0.5) - 2)
                render.circle_outline(circle_pos, color(0, 200), 10, 0, 1, 5)
                render.circle_outline(circle_pos, color(255, 200), 9, 0, ctx.pct, 3)
            end

            if ctx.should_draw_bomb then
                render.texture(draw.icon, vector(position.x + 11, ((position.y + 2) + add_y) - 7), ctx.clr)
            end

            render.text(draw.font, vector(position.x + 10, ((position.y + 2) + add_y)), ctx.clr, "d", ctx.text)

            add_y = add_y - (size.y + 12.5)
        end
    end

    local function on_draw()
        if not menu.visuals.skeet_indicators.switch:get() then return end
        local me = entity.get_local_player()
        if not me then return end

        local is_alive = me:is_alive()
        
        draw_features(me, is_alive)
        draw_bomb_info(me, globals.curtime)
        draw_indicators()
        
        draw.data = {}
    end

    events.render(on_draw)
end

local velocity_warning = {}; do
    velocity_warning.window = windows:new("velocity_warning", vector(screen.x / 2, screen.y * 0.2));

    local alpha = smoothy.new(0);
    local holding = smoothy.new(0);
    
    function velocity_warning.frame()
        local me = entity.get_local_player()
        if me == nil then return end

        local window = velocity_warning.window;

        local modifier = me.m_flVelocityModifier;

        local menu_check = ui.get_alpha() > 0;
        local alive_check = me:is_alive();
        local velocity_check = modifier < 1;
        

        local is_dragging = window:is_dragging();
        local can_show_warning = menu.visuals.velocity_warning.switch:get() and ((alive_check and velocity_check) or menu_check);

        alpha(.05, can_show_warning);
        holding(.5, can_show_warning and is_dragging and .6 or 1);

        if alpha.value <= 0 then return end

        if menu_check and (not velocity_check or not alive_check) then
            modifier = math.min(1, globals.tickcount % 200 / 150)
        end

        local alpha = alpha.value * holding.value;

        local bar_color = menu.visuals.velocity_warning.color:get();
        
        local position = window.position;
        local size = window.size + vector(0, 2);

        local text = ("Max velocity was reduced by %d%%"):format(modifier * 100)
        local text_size = render.measure_text(1, "", text)

        local bar_pos = position + vector(9, 24);
        local bar_size = vector(size.x, 4);

        render.text(1, 
            position + vector(19, 7), color(255, 255, 255, bar_color.a * alpha), 
            "", text
        )
        
        render.rect(bar_pos - vector(1, 1), bar_pos + bar_size + vector(1, 1), color(0, alpha * bar_color.a), 2)
        render.rect(bar_pos, bar_pos + vector(bar_size.x * alpha * modifier, bar_size.y), bar_color:alpha_modulate(bar_color.a * alpha), 2)

        window:update(vector(
            math.max(text_size.x + 15, bar_size.x), 
            text_size.y + bar_size.y + 25
        ), vector(10, -2))
    end

    events.render(velocity_warning.frame)
end


local hitmarker do
    local data = {
        time = globals.realtime,
        alpha = smoothy.new(0),
        wait_time = 0.4
    }; 
     
    local function aim_ack(ctx)
        if ctx.state ~= nil then return end
        local duration = menu.visuals.hitmarker.time:get() / 10;
        local time = globals.realtime + duration;
        local position = ctx.aim;
    
        data = {
            time = time,
            point = position,
            alpha = smoothy.new(0)
        }
    end


    local function on_draw()
        local me = entity.get_local_player();
        if me == nil then return end;
        
        local element = menu.visuals.hitmarker.select;
        local center = screen / 2;

        local colors = {
            menu.visuals.hitmarker.color:get("2D")[1],
            menu.visuals.hitmarker.color:get("3D")[1]
        }
        
        data.alpha(.025, globals.realtime <= data.time and me:is_alive());
        if data.alpha.value <= 0 then return end

        local pct = data.alpha.value;

        if element:get(1) then
            local accent = colors[1]:alpha_modulate(colors[1].a * pct);
           
            local offset = 5;
            local length = 10;

            render.line(center + vector(offset, offset), center + vector((length / screen.x) * screen.x, (length / screen.y * screen.y)), accent)
            render.line(center - vector(offset, -offset), center - vector((length / screen.x) * screen.x, -(length / screen.y) * screen.y), accent)

            render.line(center - vector(offset, offset), center - vector((length / screen.x) * screen.x, (length / screen.y) * screen.y), accent)
            render.line(center + vector(offset, -offset), center + vector((length / screen.x) * screen.x, -(length / screen.y) * screen.y), accent)
        end

        if element:get(2) then
            local accent = colors[2]:alpha_modulate(colors[2].a * pct);
            local point = data.point;

            if point == nil then
                return;
            end

            local position = point:to_screen()

            local size = 5

            if position and position.x then
                render.rect(position - vector(size, 0), position + vector(size, 0), accent)
                render.rect(position - vector(0, size), position + vector(0, size), accent)
            end
        end
    end

    events.aim_ack(aim_ack)
    events.render(on_draw)
end

local player_transparency do
    local function on_change(alpha)
        local me = entity.get_local_player();
        if me == nil or not me:is_alive() then return end
        if not menu.visuals.player_transparency.switch:get() then return end
        
        if me.m_bIsScoped or me.m_bResumeZoom then
            alpha = 59
        end
    end

    events.localplayer_transparency(on_change);
end

local damage_indicator = {} do
    damage_indicator.window = windows:new("damage_indicator", vector(screen.x * 0.51, screen.y * 0.51))

    local alpha = smoothy.new(0);
    local holding = smoothy.new(0);

    function damage_indicator.frame()
        local me = entity.get_local_player()
        if me == nil or not me:is_alive() then return end

        local window = damage_indicator.window
        local min_damage = keybinds:get_state("Min. Damage");

        local can_show_damage = (min_damage[2] or ui.get_alpha() > 0) and menu.visuals.damage_indicator.switch:get();

        alpha(.05, can_show_damage);
        holding(.05, can_show_damage and window:is_dragging() and .6 or 1);

        if alpha.value <= 0 then return end

        local alpha = alpha.value * holding.value;
        local position = window.position;

        local text = tostring(min_damage[1])
        local text_size = render.measure_text(1, nil, text) / 2

        render.text(1, position + vector(7, 1), color(255, 255 * alpha), nil, text)

        window:update(vector(
            math.max(text_size.x, 10), 
            text_size.y + 10)
        )
    end

    events.render(damage_indicator.frame)
end

--[[local legacy_desync do

    local sv_legacy_desync = cvar.sv_legacy_desync;

    local function shutdown()
        sv_legacy_desync:float(cvars:get_original(sv_legacy_desync), false)
    end

    local function on_createmove(e)
        local me = entity.get_local_player();
        if me == nil or not me:is_alive() then shutdown() return end
        if not menu.visuals.legacy_desync.switch:get() then return shutdown() end

        local weapon = me:get_player_weapon();
        if weapon == nil then shutdown() return end

        local last_shot_time = weapon.m_fLastShotTime;
        local is_shot = last_shot_time > me:get_simulation_time().old and last_shot_time <= me:get_simulation_time().current;
        sv_legacy_desync:float(is_shot and 0 or 1, true)
    end

    events.shutdown(shutdown);
    events.createmove(on_createmove)
end]]

local remove_sleeves do
    local thirdperson = ui.find("Visuals", "World", "Main", "Force Thirdperson");

    local function on_draw(e)
        local me = entity.get_local_player();
        if me == nil or not me:is_alive() then return end
        if not menu.visuals.remove_sleeves.switch:get() then return end
        if thirdperson:get() or thirdperson:get_override() then return end
        if e.name:find("sleeve") then return false end 

        return true;
    end

    events.draw_model(on_draw);
end

local fall_damage do
    local state = false

    local function trace(player, length)
        if not menu.misc.movement.fall_damage:get() then return false end
    
        local origin = player:get_origin()
        local pi = math.pi;
        
        for angle = 0, pi * 2, pi / 4 do
            local tr = utils.trace_line(origin, origin + vector(10 * math.cos(angle), 10 * math.sin(angle), -length), player)
            if tr.fraction < 1 - (1 / 128) then
                return true
            end
        end

        return false
    end

    local function createmove(e)
        if not menu.misc.movement.fall_damage:get() then return false end
        local me = entity.get_local_player()
        if me == nil or not me:is_alive() then return end
        local velocity = me.m_vecVelocity
        if velocity.z >= -500 then state = false return end

        e.in_duck = not trace(me, 15) and trace(me, 75)
    end

    events.createmove(createmove)
end

local fast_ladder do
    local function change_view_angle(e, value)
        e.view_angles.y = e.view_angles.y + value
    end

    local function createmove(e)
        if not menu.misc.movement.fast_ladder:get() then return end
        if e.in_use then return end

        local me = entity.get_local_player()
        if me == nil or not me:is_alive() then return end
        if me.m_MoveType ~= 9 then return end

        local pitch = render.camera_angles().x

        if e.forwardmove <= 0 then return end
        if pitch > 45 then return end

        e.view_angles.x = 89
        e.in_moveright = 1
        e.in_moveleft = 0
        e.in_forward = 0
        e.in_back = 1

        if e.sidemove == 0 then
            change_view_angle(e, 90)
        end

        if e.sidemove < 0 then
            change_view_angle(e, 150)
            
        end

        if e.sidemove > 0 then
            change_view_angle(e, 30)
        end
    end
    

    events.createmove(createmove)
end

local air_duck_collision do

    local function create_ctx(player)
        return player:simulate_movement(
            player.m_vecOrigin, player.m_vecVelocity, player.m_fFlags
        )
    end

    local function on_createmove(e)
        if not menu.misc.movement.air_duck_collision:get() then return false end
        local me = entity.get_local_player()
        if me == nil or not me:is_alive() then return end
        if me.m_MoveType == 9 or me.m_MoveType == 8 then return; end
        if e.in_duck then return end

        local flags = me.m_fFlags
        if bit.band(flags, bit.lshift(1, 0)) ~= 0 then return end

        local ctx = create_ctx(me)

        e.in_duck = true
        ctx:think(1)

        local hit_with_duck = (
            bit.band(ctx.flags, bit.lshift(1, 0)) == 0
            and ctx.did_hit_collision
        )

        local ctx = create_ctx(me)

        e.in_duck = false
        ctx:think(1)

        local hit_without_duck = (
            bit.band(ctx.flags, bit.lshift(1, 0)) == 0
            and ctx.did_hit_collision
        )

        if not hit_with_duck and hit_without_duck then
            e.in_duck = true
        end
    end

    events.createmove(on_createmove)
end

local edge_quick_stop do
    local function create_ctx(player)
        return player:simulate_movement(
            player.m_vecOrigin, player.m_vecVelocity, player.m_fFlags
        )
    end

    local function on_createmove(e)
        if not menu.misc.movement.edge_quick_stop:get() then return end
        local me = entity.get_local_player()
        if me == nil or not me:is_alive() then return end
        if me.m_MoveType == 9 or me.m_MoveType == 8 then return end

        local ctx = create_ctx(me);
        ctx:think(4);

        if ctx.velocity.z < 0 then
            e.block_movement = 2
        end
    end

    events.createmove(on_createmove)
end

pui.setup(menu);
