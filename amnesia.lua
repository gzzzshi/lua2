--[[
    zazahook [DEV] v2
]]
-- ════════════════════════════════════════════════════════════════
--  WHITELIST PROTECTION — gz v1.0
-- ════════════════════════════════════════════════════════════════
do
    local WHITELIST = {
        "oouushi",
        "salt09",
      
    }
    local nl_user = common.get_username() or ""
    local allowed = false
    for _, v in ipairs(WHITELIST) do
        if nl_user:lower() == v:lower() then allowed = true; break end
    end
    if not allowed then
        print("\aFF3333FF[zazahook] \aFFFFFFFFNot whitelisted: \aFF8C00FF" .. nl_user .. "\aFFFFFFFF - access denied.")
        error("", 0)
    end
end



local TEAM_T  = 2
local TEAM_CT = 3
local MISS_ANGLE    = 20
local CUSTOM_TAG    = "myTag"
local _evaded_shots = db.gz_evaded or 0

local teams  = { "T", "CT" }
local states = { "Stand", "Run", "Jump", "Jump+", "Duck", "Slowwalk", "Fake Duck" }

local STATE_TO_CONDITION = {
    [1]="Standing",[2]="Moving",[3]="Air",
    [4]="Air + Crouch",[5]="Crouching",[6]="Slow Walking",[7]="Fake Ducking",
}
local hitgroup_str = {
    [0]="generic","head","chest","stomach","left arm","right arm",
    "left leg","right leg","neck","generic","gear",
}
local CTAG_FRAMES = {
    "zazahook","\xf0\x9f\x8d\x83zazahook","\xf0\x9f\x8d\x83azahook",
    "z\xf0\x9f\x8d\x83zahook","za\xf0\x9f\x8d\x83ahook","zaz\xf0\x9f\x8d\x83hook",
    "zaza\xf0\x9f\x8d\x83ook","zazah\xf0\x9f\x8d\x83ok","zazaho\xf0\x9f\x8d\x83k",
    "zazahoo\xf0\x9f\x8d\x83","zazahook\xf0\x9f\x8d\x83","zazahook",
}
local KILLSAY_MSGS = {
    "\xe4\xb8\xad\xe5\x9b\xbd\xe7\xac\xac\xe4\xb8\x80",
    "\xe8\x82\xbf\xe4\xbd\xa0\xe7\xa5\x96\xe5\xae\x97\xe5\x8d\x81\xe5\x85\xab\xe4\xbb\xa3",
    "\xe5\xa6\x88\xe4\xba\x86\xe4\xb8\xaa\xe9\x80\xbc \xe5\xba\x9f\xe7\x89\xa9",
    "(\xe8\x84\xb3\xe5\xad\x90\xe8\xbf\x9b\xe6\xb0\xb4\xe4\xba\x86?",
    "\xe5\x82\xbb\xe5\xb1\x84","\xe6\x9c\x89\xe7\x97\x85","\xe7\x8e\x8b\xe5\x85\xab\xe8\x9b\x8b",
}
local SAFE_HEAD_GRACE=8; local AIR_GROUND_GRACE=4; local GROUND_CONFIRM=2

do
    local seed=math.floor((globals.realtime or 0)*1000)+(globals.tickcount or 0)
    pcall(function() seed=seed+(os.time() or 0) end)
    math.randomseed(seed)
    for _=1,8 do math.random() end
end

local function get_team()
    local lp=entity.get_local_player()
    if not lp or not lp:is_alive() then return 1 end
    return lp.m_iTeamNum==TEAM_CT and 2 or 1
end
local function get_state()
    local lp=entity.get_local_player()
    if not lp or not lp:is_alive() then return 1 end
    do
        local ok,fd=pcall(ui.find,"Aimbot","Anti Aim","Misc","Fake Duck")
        if ok and fd and (fd:get_override() or fd:get()) then return 7 end
    end
    local vel=math.sqrt(lp.m_vecVelocity.x^2+lp.m_vecVelocity.y^2)
    local flags=lp.m_fFlags
    local on_ground=bit.band(flags,1)~=0
    local ducking_flag=bit.band(flags,2)~=0
    local crouching=lp.m_flDuckAmount>0.8
    local sw_ref=ui.find("Aimbot","Anti Aim","Misc","Slow Walk")
    local slowwalk=sw_ref and sw_ref:get() or false
    if slowwalk then return 6 end
    if not on_ground and ducking_flag then return 4 end
    if not on_ground then return 3 end
    if crouching then return 5 end
    if vel<5 then return 1 end
    return 2
end
local function get_cond_idx() return (get_team()-1)*#states+get_state() end
local function angles_to_fwd(angles)
    local p=math.rad(angles.x); local y=math.rad(angles.y)
    return vector(math.cos(p)*math.cos(y),math.cos(p)*math.sin(y),-math.sin(p))
end

-- ════════════════════════════════════════════════════════════════
--  REFS
-- ════════════════════════════════════════════════════════════════
local refs = {
    pitch          = ui.find("Aimbot","Anti Aim","Angles","Pitch"),
    yaw            = ui.find("Aimbot","Anti Aim","Angles","Yaw"),
    yaw_base       = ui.find("Aimbot","Anti Aim","Angles","Yaw","Base"),
    yaw_offset     = ui.find("Aimbot","Anti Aim","Angles","Yaw","Offset"),
    yaw_mod        = ui.find("Aimbot","Anti Aim","Angles","Yaw Modifier"),
    yaw_mod_offset = ui.find("Aimbot","Anti Aim","Angles","Yaw Modifier","Offset"),
    body_yaw       = ui.find("Aimbot","Anti Aim","Angles","Body Yaw"),
    body_left      = ui.find("Aimbot","Anti Aim","Angles","Body Yaw","Left Limit"),
    body_right     = ui.find("Aimbot","Anti Aim","Angles","Body Yaw","Right Limit"),
    body_opts      = ui.find("Aimbot","Anti Aim","Angles","Body Yaw","Options"),
    lag_opts       = ui.find("Aimbot","Ragebot","Main","Double Tap","Lag Options"),
    hs_opts        = ui.find("Aimbot","Ragebot","Main","Hide Shots","Options"),
    dt_main        = ui.find("Aimbot","Ragebot","Main","Double Tap"),
    hs_main        = ui.find("Aimbot","Ragebot","Main","Hide Shots"),
    slow_walk      = ui.find("Aimbot","Anti Aim","Misc","Slow Walk"),
    freestanding   = (function() local ok,v=pcall(ui.find,"Aimbot","Anti Aim","Angles","Freestanding"); return ok and v or nil end)(),
    avoid_backstab = (function() local ok,v=pcall(ui.find,"Aimbot","Anti Aim","Angles","Yaw","Avoid Backstab"); return ok and v or nil end)(),
    fakelag        = (function() local ok,v=pcall(ui.find,"Aimbot","Anti Aim","Misc","Fake Lag"); return ok and v or nil end)(),
    min_damage     = (function()
        local ok,v=pcall(ui.find,"Aimbot","Ragebot","Main","Minimum Damage")
        if ok and v then return v end
        ok,v=pcall(ui.find,"Aimbot","Ragebot","Main","Damage","Minimum"); return ok and v or nil
    end)(),
    hidden         = (function() local ok,v=pcall(ui.find,"Aimbot","Anti Aim","Angles","Yaw","Hidden"); return ok and v or nil end)(),
    leg_movement   = (function() local ok,v=pcall(ui.find,"Aimbot","Anti Aim","Misc","Leg Movement"); return ok and v or nil end)(),
    hitchance      = (function() local ok,v=pcall(ui.find,"Aimbot","Ragebot","Selection","Hit Chance"); return ok and v or nil end)(),
    fakeduck_ref   = (function() local ok,v=pcall(ui.find,"Aimbot","Anti Aim","Misc","Fake Duck"); return ok and v or nil end)(),
}

local function make_sidebar_text(t)
    local style=ui.get_style(); local accent=color(249,86,86,0)
    if style and type(style)=="table" and style["Link Active"] then accent=style["Link Active"] end
    local dark=color(116,131,195,255); local name="zazahook"; local out=""
    for i=1,#name do
        local frac=math.sin(t+(i-1)*0.45)*0.5+0.5
        out=out.."\a"..dark:lerp(accent,frac):to_hex()..name:sub(i,i)
    end
    return out
end

local _last_ctag=nil
local function get_ctag_frame()
    local tp=globals.tickcount
    local ok_net,net=pcall(utils.net_channel)
    if ok_net and net then
        local lat; local ok2,v=pcall(function() return net.latency[0] end)
        if ok2 and type(v)=="number" then lat=v
        else local ok3,v2=pcall(function() return net.latency end); if ok3 and type(v2)=="number" then lat=v2 end end
        if lat and globals.tickinterval>0 then tp=tp+lat/globals.tickinterval end
    end
    local iter=math.floor(math.fmod(tp/25,#CTAG_FRAMES+1)+1)
    if iter>=1 and iter<=#CTAG_FRAMES then return CTAG_FRAMES[iter] end
    return nil
end
local function apply_ctag(frame)
    if frame==nil or frame==_last_ctag then return end
    pcall(common.set_clan_tag,frame); _last_ctag=frame
end

-- ════════════════════════════════════════════════════════════════
--  UI GROUPS
-- ════════════════════════════════════════════════════════════════
local TAB="~"
local grp_nav    = ui.create(TAB,"##NAV",1)
local grp_info   = ui.create(TAB,"##INFO",1)
local grp_aa_nav = ui.create(TAB,"##AANAV",2)
local grp_aa     = ui.create(TAB,"##AA",2)
local grp_rb     = ui.create(TAB,"##RB",2)
local grp_vis    = ui.create(TAB,"##VIS",2)
local grp_msc_nav= ui.create(TAB,"##MSCNAV",2)
local grp_msc    = ui.create(TAB,"##MSC",2)
local grp_stats  = ui.create(TAB,"##STATS",2)

local NAV={AA=1,RB=2,VIS=3,MSC=4}

local nav_list=grp_nav:list("##NAVLIST",{
    ui.get_icon("shield-halved").."  Anti-Aim",
    ui.get_icon("crosshairs").."  Ragebot",
    ui.get_icon("eye").."  Visuals",
    ui.get_icon("sliders").."  Misc",
})
nav_list:set(NAV.AA)

grp_info:label(ui.get_icon("circle-user").." \a888888FFWelcome back, \a7483c3FF"..(common.get_username() or "unknown"))
grp_info:label(ui.get_icon("code").." \a888888FFYour build is, \af95656FF[DEV]")
grp_info:label(ui.get_icon("clock").." \a888888FFLatest Update, \af95656FFtoday nigga ")
grp_info:label(ui.get_icon("floppy-disk").." \a888888FFPresets")
local preset_list=grp_info:list("##PRESETS",{"<no presets>"})
local preset_name=grp_info:input("Name","")
local btns={
    load  =grp_info:button("\r"..ui.get_icon("folder-open"),nil,true),
    save  =grp_info:button("\r"..ui.get_icon("floppy-disk"),nil,true),
    delete=grp_info:button("\r"..ui.get_icon("trash"),nil,true),
    export=grp_info:button("\r"..ui.get_icon("file-export"),nil,true),
    import=grp_info:button("\r"..ui.get_icon("file-import"),nil,true),
}
btns.load:tooltip("Load"); btns.save:tooltip("Save"); btns.delete:tooltip("Delete")
btns.export:tooltip("Export"); btns.import:tooltip("Import")

local _evaded_shots = db.gz_evaded or 0
grp_stats:label("\a7483c3FF"..ui.get_icon("chart-simple").."  Statistics")
local evaded_label = grp_stats:label(ui.get_icon("shield-halved").."  \a888888FFEvaded Shots (W.I.P)  \a4ff641FF"..tostring(_evaded_shots))
grp_stats:visibility(false)  -- hidden by default

-- AA sub-nav: 1=Builder  2=Snap Builder  3=Settings
local AA_SUB={SETTINGS=1, WIP=2}

local aa_sub_nav=grp_aa_nav:list("##AASUBNAV",{
    ui.get_icon("shield-halved").."  Builder",
    ui.get_icon("gear").."  Settings",
})
aa_sub_nav:set(AA_SUB.SETTINGS); aa_sub_nav:visibility(false)
local wip_label=grp_aa_nav:label(
    "\a555555FF\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\n"..
    "\a888888FF         Coming Soon\n"..
    "\a555555FF\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80")
wip_label:visibility(false)

local MSC_SUB={MISC=1,PL=2}
local msc_sub_nav=grp_msc_nav:list("##MSCSUBNAV",{
    ui.get_icon("sliders").."  Misc",
    ui.get_icon("users").."  Player List",
})
msc_sub_nav:set(MSC_SUB.MISC)
msc_sub_nav:visibility(false)

local states_with_global={"Global"}
for _,s in ipairs(states) do states_with_global[#states_with_global+1]=s end
local team_sel =grp_aa:combo("Team",teams)
local state_sel=grp_aa:combo(ui.get_icon("person-falling").."  State",states_with_global)
local state_lbl=grp_aa:label("\a888888FFCurrent team: detecting...")

local aa_builder={}
local serialize_entry,deserialize_entry

local cb_get, cb_set
do
    local _cb_char=ffi.typeof("char[?]")
    local _cb_cnt =utils.get_vfunc("vgui2.dll","VGUI_System010",7,"int(__thiscall*)(void*)")
    local _cb_set_vf=utils.get_vfunc("vgui2.dll","VGUI_System010",9,"void(__thiscall*)(void*, const char*, int)")
    local _cb_read=utils.get_vfunc("vgui2.dll","VGUI_System010",11,"int(__thiscall*)(void*, int, const char*, int)")
    cb_get = function()
        local ok,n=pcall(_cb_cnt); if not ok or n<=0 then return "" end
        local buf=_cb_char(n); _cb_read(0,buf,n); return ffi.string(buf,n-1)
    end
    cb_set = function(txt) pcall(_cb_set_vf,txt,#txt) end
end

local function builder_current_ci()
    local team=team_sel:get(); local state=state_sel:get()
    if state=="Global" then return 0 end
    local ti,si=1,1
    for i,t in ipairs(teams) do if t==team then ti=i break end end
    for i,s in ipairs(states) do if s==state then si=i break end end
    return (ti-1)*#states+si
end

do
    local ss=state_sel:create()
    ss:button(ui.get_icon("arrow-up-from-bracket").."  Copy",function()
        local ci=builder_current_ci(); local cfg=aa_builder[ci]; if not cfg then return end
        local d=serialize_entry and serialize_entry(cfg) or {}
        if ci>0 and cfg.override_global then d.override_global=cfg.override_global:get() end
        local ok,str=pcall(json.stringify,d); if ok then cb_set(str) end
    end,true)
    ss:button(ui.get_icon("arrow-down-to-bracket").."  Paste",function()
        local ci=builder_current_ci(); local cfg=aa_builder[ci]; if not cfg then return end
        local str=cb_get(); if str=="" then return end
        local ok,d=pcall(json.parse,str)
        if ok and type(d)=="table" then
            if deserialize_entry then deserialize_entry(cfg,d,ci) end
            if d.override_global~=nil and ci>0 and cfg.override_global then cfg.override_global:set(d.override_global) end
        end
    end,true)
    ss:button(ui.get_icon("send-backward").."  Send to another team",function()
        local state=state_sel:get(); if state=="Global" then return end
        local team=team_sel:get(); local ti,si=1,1
        for i,t in ipairs(teams) do if t==team then ti=i break end end
        for i,s in ipairs(states) do if s==state then si=i break end end
        local ci_src=(ti-1)*#states+si; local ci_dst=(3-ti-1)*#states+si
        local src=aa_builder[ci_src]; local dst=aa_builder[ci_dst]
        if not(src and dst and serialize_entry and deserialize_entry) then return end
        local d=serialize_entry(src); d.override_global=src.override_global and src.override_global:get() or nil
        deserialize_entry(dst,d,ci_dst)
        if d.override_global~=nil and dst.override_global then dst.override_global:set(d.override_global) end
    end,true)
end
team_sel:visibility(false); state_sel:visibility(false); state_lbl:visibility(false)

local DEF_AA_LABEL="\aFFAA00FF"..ui.get_icon("triangle-exclamation").."  Defensive AA"
local DEF_AA_TIP=ui.get_icon("triangle-exclamation").." W.I.P"

local function make_snap_sub(sw)
    local s={}; local sub=sw:create()
    s.no_gren=sub:switch("Disable on Grenade",false)
    s.no_gren:tooltip("Skips Break LC while holding a grenade.")
    s.hs_mode=sub:combo("Hide Shots",{"Favor Fire Rate","Favor Fake Lag","Break LC"})
    s.hs_mode:tooltip("Override Hide Shots option while Break LC is active.")
    s.choke=sub:combo("Tickbase",{"Default","Custom","Sliders"})
    s.choke:tooltip("Default = always force send.\nCustom = modulo-based choke.\nSliders = cycle through N values.")
    s.rand=sub:switch("Random Choke",false)
    s.choke_v=sub:slider("Choke",2,22,14,1,function(v) return v.."t" end)
    s.from_v=sub:slider("From",2,22,8,1,function(v) return v.."t" end)
    s.to_v=sub:slider("To",2,22,16,1,function(v) return v.."t" end)
    s.slider_count=sub:slider("Sliders",1,8,4,1,function(v) return v end)
    s.sliders={}
    for _si=1,8 do
        s.sliders[_si]=sub:slider("â³ ".._si,2,22,2,1,function(v) return v.."t" end)
    end
    local function rf()
        local mode=s.choke:get()
        local ic=mode=="Custom"; local isl=mode=="Sliders"; local ir=ic and s.rand:get()
        s.rand:visibility(ic); s.choke_v:visibility(ic and not ir)
        s.from_v:visibility(ic and ir); s.to_v:visibility(ic and ir)
        s.slider_count:visibility(isl)
        local cnt=isl and s.slider_count:get() or 0
        for _si2=1,8 do s.sliders[_si2]:visibility(_si2<=cnt) end
    end
    s.choke:set_callback(rf,true); s.rand:set_callback(rf,true); s.slider_count:set_callback(rf)
    return s
end

local function make_yaw_switch_sub(grp_widget)
    local ys={}; local sub=grp_widget:create()
    ys.mode=sub:combo("Mode",{"L&R Yaw","Delayed Switch"})
    ys.left=sub:slider("Left",-180,180,0); ys.right=sub:slider("Right",-180,180,0)
    ys.delay=sub:slider("Hold Time",2,40,10,1,function(v) return v.." pk" end)
    ys.jitter=sub:slider("Variance",0,20,5,1,function(v) return v==0 and "Off" or ("+"..v.." pk") end)
    ys.micro=sub:slider("Micro Jitter",0,10,0,1,function(v) return v==0 and "Off" or ("\xc2\xb1"..v.."\xc2\xb0") end)
    ys.ap_on=sub:switch("Anti-Pattern",false)
    ys.ap_chance=sub:slider("AP Chance",1,30,10,1,function(v) return v.."%" end)
    ys.ap_kind=sub:combo("AP Behavior",{"Snap Flip","Long Hold","Random Mix"})
    ys.info=sub:label("\aFFAA00FFVariance: random extra packets per flip.\n\aFFAA00FF\n\a888888FFAP automatically generates optimal patterns  ")
    local function refresh()
        local d=ys.mode:get()=="Delayed Switch"
        ys.delay:visibility(d); ys.jitter:visibility(d); ys.ap_on:visibility(d)
        local ap=d and ys.ap_on:get()
        ys.ap_chance:visibility(ap); ys.ap_kind:visibility(ap); ys.info:visibility(d)
    end
    ys.mode:set_callback(refresh,true); ys.ap_on:set_callback(refresh,true)
    return ys
end

local function make_defensive_sub(sw)
    local def={}; local sub=sw:create()
    def.triggers=sub:selectable("Triggers",{"DT Ready","Hide Shots"})
    def.force_defensive=sub:switch("Force Defensive",false)
    def.custom_choke=sub:switch("Custom Choke",false)
    def.random_choke=sub:switch("Randomize Choke",false)
    def.choke_1=sub:slider("Choke",1,22,16,1,function(v) return v.."t" end)
    def.choke_2=sub:slider("2nd Choke",1,22,16,1,function(v) return v.."t" end)
    def.enabled=sub:switch("Hidden Angles",false)
    def.pitch=sub:combo("Pitch",{"Static","Jitter","Random","Spin","Sway"})
    def.pitch_offset=sub:slider("Pitch Offset",-89,89,-45,1,function(v) return v.."\xc2\xb0" end)
    def.pitch_1=sub:slider("Pitch From",-89,89,-45,1,function(v) return v.."\xc2\xb0" end)
    def.pitch_2=sub:slider("Pitch To",-89,89,45,1,function(v) return v.."\xc2\xb0" end)
    def.yaw=sub:combo("Yaw",{"Static","Switch","Random","Spin","Sway"})
    def.yaw_offset=sub:slider("Yaw Offset",0,360,180,1,function(v) return v.."\xc2\xb0" end)
    def.yaw_1=sub:slider("Yaw From",-180,180,-90,1,function(v) return v.."\xc2\xb0" end)
    def.yaw_2=sub:slider("Yaw To",-180,180,90,1,function(v) return v.."\xc2\xb0" end)
    def.yaw_rand=sub:slider("Randomization",0,20,0,1,function(v) return v.."t" end)
    def.yaw_speed=sub:slider("Speed",-50,50,20,0.1)
    local function rd()
        local fd=def.force_defensive:get(); local cc=fd and def.custom_choke:get(); local rc=cc and def.random_choke:get()
        local pm=def.pitch:get(); local ym=def.yaw:get()
        local ysrn=ym=="Switch" or ym=="Random"; local ysps=ym=="Spin" or ym=="Sway"
        def.custom_choke:visibility(fd); def.random_choke:visibility(cc); def.choke_1:visibility(cc); def.choke_2:visibility(rc)
        def.pitch_offset:visibility(pm=="Static"); def.pitch_1:visibility(pm~="Static"); def.pitch_2:visibility(pm~="Static")
        def.yaw_offset:visibility(not ysrn); def.yaw_1:visibility(ysrn); def.yaw_2:visibility(ysrn)
        def.yaw_rand:visibility(ym=="Switch"); def.yaw_speed:visibility(ysps)
    end
    def.force_defensive:set_callback(rd,true); def.custom_choke:set_callback(rd,true)
    def.random_choke:set_callback(rd,true); def.pitch:set_callback(rd,true); def.yaw:set_callback(rd,true)
    return def
end

do
    local m={}; aa_builder[0]=m
    m.yaw_switch=grp_aa:switch("Yaw",false); m.ys=make_yaw_switch_sub(m.yaw_switch)
    m.yaw_mod=grp_aa:combo("Yaw Modifier",{"Disabled","Center","Offset","Random","Spin","3-Way","5-Way"})
    local ym={}; m.ym=ym
    do
        local sub=m.yaw_mod:create()
        ym.offset=sub:slider("Offset",-180,180,0)
        ym.randomize=sub:slider("Randomize",0,180,0,1,function(v) return v==0 and "Off" or v.."\xc2\xb0" end)
        m.yaw_mod:set_callback(function() local io=m.yaw_mod:get()=="Offset"; ym.offset:visibility(io); ym.randomize:visibility(io) end,true)
    end
    m.desync=grp_aa:switch("Desync",false)
    local ds={}; m.ds=ds
    do
        local sub=m.desync:create()
        ds.left=sub:slider("Left Limit",1,60,60); ds.right=sub:slider("Right Limit",1,60,60)
        ds.opts=sub:selectable("Options",{"Avoid Overlap","Jitter","Randomize Jitter","Anti Bruteforce"})
    end
    m.defensive=grp_aa:switch(DEF_AA_LABEL,false); m.defensive:tooltip(DEF_AA_TIP); m.def=make_defensive_sub(m.defensive)
    m.snap=grp_aa:switch(ui.get_icon("bolt").."  Break LC",false)
    m.snap:tooltip("Override tickbase and hide-shots for this state.")
    m.snap_ui=make_snap_sub(m.snap)
    for _,w in ipairs({m.yaw_switch,m.yaw_mod,m.desync,m.defensive,m.snap}) do w:visibility(false) end
end

for team_idx=1,#teams do
    for state_idx=1,#states do
        local ci=(team_idx-1)*#states+state_idx; local m={}; aa_builder[ci]=m
        m.override_global=grp_aa:switch("Per-State Override",false)
        m.yaw_switch=grp_aa:switch("Yaw",false); m.ys=make_yaw_switch_sub(m.yaw_switch)
        m.yaw_mod=grp_aa:combo("Yaw Modifier",{"Disabled","Center","Offset","Random","Spin","3-Way","5-Way"})
        local ym={}; m.ym=ym
        do
            local sub=m.yaw_mod:create()
            ym.offset=sub:slider("Offset",-180,180,0)
            ym.randomize=sub:slider("Randomize",0,180,0,1,function(v) return v==0 and "Off" or v.."\xc2\xb0" end)
            m.yaw_mod:set_callback(function() local io=m.yaw_mod:get()=="Offset"; ym.offset:visibility(io); ym.randomize:visibility(io) end,true)
        end
        m.desync=grp_aa:switch("Desync",false)
        local ds={}; m.ds=ds
        do
            local sub=m.desync:create()
            ds.left=sub:slider("Left Limit",1,60,60); ds.right=sub:slider("Right Limit",1,60,60)
            ds.opts=sub:selectable("Options",{"Avoid Overlap","Jitter","Randomize Jitter","Anti Bruteforce"})
        end
        m.defensive=grp_aa:switch(DEF_AA_LABEL,false); m.defensive:tooltip(DEF_AA_TIP); m.def=make_defensive_sub(m.defensive)
        m.snap=grp_aa:switch(ui.get_icon("bolt").."  Break LC",false)
        m.snap:tooltip("Override tickbase and hide-shots for this state.")
        m.snap_ui=make_snap_sub(m.snap)
        for _,w in ipairs({m.override_global,m.yaw_switch,m.yaw_mod,m.desync,m.defensive,m.snap}) do w:visibility(false) end
    end
end

-- ════════════════════════════════════════════════════════════════
--  SNAP BUILDER (Break LC) — separate sub-tab
-- ════════════════════════════════════════════════════════════════

-- SETTINGS TAB widgets
local set_freestanding_sw=grp_aa:switch(ui.get_icon("eye").."  Freestanding",false)
local avoid_backstab_sw=grp_aa:switch(ui.get_icon("person-falling-burst").."  Avoid Backstab",false)
avoid_backstab_sw:tooltip("Override the built-in Avoid Backstab option."); avoid_backstab_sw:visibility(false)
local safe_head_sw=grp_aa:switch(ui.get_icon("shield-halved").."  Safe Head",false)
safe_head_sw:tooltip("Forces yaw 0 (backward, no modifiers).\nKnife/Zeus: Air+Crouch only.\nFar from Enemy: all states.")
local safe_head_opts,safe_head_dist,safe_head_def_sw
do
    local sub=safe_head_sw:create()
    safe_head_opts=sub:selectable("Trigger On",{"Knife","Zeus","Far from Enemy"})
    safe_head_dist=sub:slider("Distance",100,2000,800,50,function(v) return v.."u" end)
    safe_head_dist:tooltip("Activate safe head when closest enemy is further than this distance.")
    safe_head_dist:visibility(false)
    safe_head_opts:set_callback(function()
        local t=safe_head_opts:get() or {}
        local has_far=false
        for _,v in ipairs(t) do if v=="Far from Enemy" then has_far=true break end end
        safe_head_dist:visibility(has_far)
    end)
    safe_head_def_sw=sub:switch("Enable Defensive",false)
    safe_head_def_sw:tooltip("Allow Defensive AA to run while Safe Head is active.\nWhen OFF, Defensive AA is always suppressed during Safe Head.")
    sub:label("\a888888FFKnife/Zeus: Air+Crouch only.\n\a888888FFFar from Enemy: all states.\n\a888888FFOverrides yaw switch and modifiers.")
end
safe_head_sw:visibility(false)
local manual_aa_sw=grp_aa:switch(ui.get_icon("hand").."  Manual AA",false)
local manual_dir,manual_static_sw,manual_disablers_sel
do
    local sub=manual_aa_sw:create()
    manual_dir=sub:combo("Manual Yaw",{"Disabled","Left","Right","Backward","Forward"})
    manual_dir:tooltip("Sets a persistent manual yaw direction.\nLeft = -90\xc2\xb0  Right = +90\xc2\xb0  Backward = 0\xc2\xb0  Forward = 180\xc2\xb0")
    manual_static_sw=sub:switch("Static Manual Yaw",false)
    manual_static_sw:tooltip("When enabled, also resets body yaw modifiers\nso the direction is always clean.")
    manual_disablers_sel=sub:selectable("Disablers",states)
end
local function refresh_manual_dir()
    local a=manual_dir:get()~="Disabled"; manual_static_sw:visibility(a); manual_disablers_sel:visibility(a)
end
manual_dir:set_callback(refresh_manual_dir,true)
local falling_combo=grp_aa:combo(ui.get_icon("person-falling").."  Falling Animation",{"Default","Force","Legacy"})
falling_combo:tooltip("'Force' forces the falling animation playback.\n'Legacy' uses pre-Danger Zone falling behavior.")
local dir_legs_sel=grp_aa:selectable(ui.get_icon("person-walking").."  Directional Legs",{"Ground","Jumping","Jitter"})
dir_legs_sel:tooltip("Ground - ground leg lock.\nJumping - airborne.\nJitter - rapid slide animation.")

-- Gazolina Anti-Bruteforce (Settings tab)
local new_abf_sw=grp_aa:switch(ui.get_icon("reply-clock").."  Anti-Bruteforce",false)
new_abf_sw:tooltip("\a179effFF• \affffffFFautomatic sensei presets to avoid hs.")
local new_abf_ui={}
do
    local sub=new_abf_sw:create() -- increasing = random-5..+10, decreasing = fixed +5, meta = random -15..+15
    new_abf_ui.states=sub:selectable("States",states)
    new_abf_ui.mode=sub:combo("Mode",{"Increasing","Decreasing","Meta"})
    new_abf_ui.mode:tooltip("\a179effFF• \a888888FFuse meta for wide jitter, decreasing for smaller jitter, increasing is inbetween.")
    sub:label("\a888888FFTriggers when shot lands within 40u of your head.")
end

-- hide all settings tab stuff initially
set_freestanding_sw:visibility(false); manual_aa_sw:visibility(false)
falling_combo:visibility(false); dir_legs_sel:visibility(false)
new_abf_sw:visibility(false)

-- ════════════════════════════════════════════════════════════════
--  RAGEBOT
-- ════════════════════════════════════════════════════════════════
local curse_sw=grp_rb:switch(ui.get_icon("person-burst").."  Voodoo",false)
curse_sw:tooltip("\aFF3333FFCurses your enemy.")
do local sub=curse_sw:create(); sub:selectable("Curse Type",{"Tuan Le Curse","Pro Edate Curse"}) end

local disable_fl_sw=grp_rb:switch(ui.get_icon("ban").."  Disable FL on Exploits",false)
disable_fl_sw:tooltip("Automatically disables Fake Lag while\nDouble Tap or Hide Shots is active.")

local air_hc_sw=grp_rb:switch(ui.get_icon("wind").."  In Air Hitchance",false)
air_hc_sw:tooltip("Overrides hit chance for specific weapons when you are in the air.")
local air_hc_ui={}
do
    local sub=air_hc_sw:create()
    air_hc_ui.scout   =sub:slider("SSG-08",     -1,100,-1,1,function(v) return v==-1 and "off" or v.."%" end)
    air_hc_ui.revolver=sub:slider("R8 Revolver",-1,100,-1,1,function(v) return v==-1 and "off" or v.."%" end)
end
local airhc_route = { [40]=air_hc_ui.scout, [64]=air_hc_ui.revolver }

for _,w in ipairs({curse_sw,disable_fl_sw,air_hc_sw}) do w:visibility(false) end

-- ════════════════════════════════════════════════════════════════
--  VISUALS
-- ════════════════════════════════════════════════════════════════
local aimlog_sw=grp_vis:switch(ui.get_icon("terminal").."  Aimbot Logs",false)
aimlog_sw:tooltip("Prints logs to console.")
local mindmg_ind=grp_vis:switch(ui.get_icon("heart-pulse").."  Min Damage Indicator",false)
local mindmg_cp=mindmg_ind:color_picker(color(80,220,80,255))
local mindmg_val
do local sub=mindmg_ind:create(); mindmg_val=sub:slider("Value",1,126,1,function(v) return v.." dmg" end) end
local scope_sw=grp_vis:switch(ui.get_icon("circle-dot").."  Custom Scope Overlay",false)
local scope_ui={}
do
    local sub=scope_sw:create()
    scope_ui.gap=sub:slider("Gap",0,300,15); scope_ui.len=sub:slider("Length",0,300,150)
    scope_ui.col=sub:color_picker("Color",color(255,255,255,255))
end
local crosshair_ind=grp_vis:switch(ui.get_icon("plus").."  Crosshair Indicators",true)
local crosshair_cp; local ci_ui={}
do
    local sub=crosshair_ind:create()
    crosshair_cp=sub:color_picker("Accent",color(255,255,255,220))
    ci_ui.show_dt=sub:switch("  Show DT",true); ci_ui.dt_cp=ci_ui.show_dt:color_picker(color(100,255,100,255))
    ci_ui.show_osaa=sub:switch("  Show OSAA",true); ci_ui.osaa_cp=ci_ui.show_osaa:color_picker(color(100,200,255,255))
    ci_ui.scope_shift=sub:switch("  Shift When Scoped",false)
    ci_ui.scope_x=sub:slider("X Offset",10,200,60); ci_ui.scope_y=sub:slider("Y Offset",-50,50,0)
    ci_ui.glow=sub:switch("  Glow",false); ci_ui.glow_cp=ci_ui.glow:color_picker(color(100,200,255,200))
    ci_ui.glow_int=sub:slider("  Intensity",1,10,4,1,function(v) return v end)
end
local notif_sw=grp_vis:switch(ui.get_icon("bell").."  Notifications",false)
local n_ui={}
do
    local sub=notif_sw:create()
    sub:label("\a888888FFOptions")
    n_ui.speed=sub:slider("Fade Speed",10,100,60,1,function(v) return v.."%" end)
    n_ui.pos_spd=sub:slider("Position Speed",10,100,40,1,function(v) return v.."%" end)
    n_ui.limit=sub:slider("Limit",1,10,4,1); n_ui.rounding=sub:slider("Rounding",0,20,14,1)
    n_ui.duration=sub:slider("Duration",10,100,30,1,function(v) return string.format("%.1fs",v*0.1) end)
    sub:label("\a888888FFColors")
    n_ui.cp_accent=sub:color_picker("Accent",color(255,255,255,255))
    n_ui.cp_bg=sub:color_picker("Background",color(18,20,26,220))
    n_ui.cp_text=sub:color_picker("Text",color(220,220,220,255))
    n_ui.cp_shadow=sub:color_picker("Shadow",color(0,0,0,160))
    n_ui.glow_sw=sub:switch("Glow",false); n_ui.glow_cp=n_ui.glow_sw:color_picker(color(100,180,255,200))
    n_ui.glow_int=sub:slider("Intensity",1,8,3,1); n_ui.glow_int:visibility(false)
    n_ui.glow_sw:set_callback(function() n_ui.glow_int:visibility(n_ui.glow_sw:get()) end)
end
local keep_trans_sw=grp_vis:switch(ui.get_icon("face-dotted").."  Keep Model Transparency",false)
keep_trans_sw:tooltip("1:1 replica from \a00CC44FFgamesense")
local si_sw=grp_vis:switch(ui.get_icon("circle-info").."  Screen Indicators",false)
local si_ui={}
do
    local sub=si_sw:create()
    si_ui.sel=sub:selectable("Indicators",{
        "Aimbot Stats","Double Tap","Hide Shots","Fake Duck",
        "Safe Point","Body Aim","Min Damage","Hit Chance",
        "Freestanding","Defusing","Bomb Info","Ping",
    })
    si_ui.clr=sub:color_picker("Color",color(255,255,255,255))
end
local wm_sw=grp_vis:switch(ui.get_icon("signature").."  Watermark",false)
local wm_ui={}
do
    local sub=wm_sw:create()
    wm_ui.name=sub:input("Name","zazahook")
    wm_ui.pos =sub:combo("Position",{"Top Right","Bottom Center","Left Center","Right Center"})
    wm_ui.col =sub:color_picker("Color",color(255,255,255,220))
end
wm_sw:visibility(false)
local gren_warn_sw=grp_vis:switch(ui.get_icon("hexagon-exclamation").."  Grenade Proximity Warning",false)
gren_warn_sw:tooltip("\194\183 1:1 replica from \a00CC44FFgamesense\aDEFAULT.\n\n\aFFAA00FF\194\183 Requires Neverlose's built-in \"Grenade Proximity Warning\" ON.")
gren_warn_sw:visibility(false)
for _,item in ipairs({aimlog_sw,mindmg_ind,scope_sw,crosshair_ind,
                      ci_ui.show_dt,ci_ui.show_osaa,ci_ui.scope_shift,
                      ci_ui.scope_x,ci_ui.scope_y,ci_ui.glow,ci_ui.glow_int,
                      notif_sw,keep_trans_sw,si_sw}) do
    item:visibility(false)
end

-- ════════════════════════════════════════════════════════════════
--  MISC
-- ════════════════════════════════════════════════════════════════
local clantag_sw=grp_msc:switch(ui.get_icon("tag").."  Clantag",false)
local fastladder_sw=grp_msc:switch(ui.get_icon("arrow-up").."  Fast Ladder",false)
local killsay_sw=grp_msc:switch(ui.get_icon("comment-dots").."  Kill Say",false)
local killsay_delay_sl,killsay_mode
do
    local sub=killsay_sw:create()
    killsay_delay_sl=sub:slider("Delay",1,5,1,1,function(v) return v.."s" end)
    killsay_mode=sub:combo("Chat Mode",{"All Chat","Team Chat"})
end
local ar_sw=grp_msc:switch(ui.get_icon("expand").."  Aspect Ratio",false)
local ar_slider
do local sub=ar_sw:create(); ar_slider=sub:slider("Ratio",100,240,178,1,function(v) return string.format("%.2f",v*0.01) end) end
local vm_sw=grp_msc:switch(ui.get_icon("gun").."  Viewmodel",false)
local vm_ui={}
do
    local sub=vm_sw:create()
    vm_ui.fov=sub:slider("FOV",54,68,68,1,function(v) return v end)
    vm_ui.x=sub:slider("X",-25,25,0,1,function(v) return string.format("%.1f",v*0.1) end)
    vm_ui.y=sub:slider("Y",-20,20,0,1,function(v) return string.format("%.1f",v*0.1) end)
    vm_ui.z=sub:slider("Z",-20,20,0,1,function(v) return string.format("%.1f",v*0.1) end)
    vm_ui.lh=sub:switch("Opposite Knife Hand",false)
end
for _,item in ipairs({clantag_sw,fastladder_sw,killsay_sw,ar_sw,vm_sw}) do item:visibility(false) end
local avoid_coll_sw=grp_msc:switch(ui.get_icon("arrows-turn-to-dots").."  Avoid Collisions",false)
avoid_coll_sw:tooltip("Attempts to avoid obstacles by overriding Air Strafe direction.")
local no_fall_sw=grp_msc:switch(ui.get_icon("person-falling-burst").."  No Fall Damage",false)
no_fall_sw:tooltip("Attempts to perform a jumpbug when possible.")
local edge_qs_sw=grp_msc:switch(ui.get_icon("person-circle-exclamation").."  Edge Quick Stop",false)
edge_qs_sw:tooltip("Works best with Peek Assist")
local fd_speed_sw=grp_msc:switch(ui.get_icon("person-falling").."  Fake Duck Speed",false)
fd_speed_sw:tooltip("Unlocks movement speed while fake ducking, letting you move a bit faster.")
for _,item in ipairs({avoid_coll_sw,no_fall_sw,edge_qs_sw,fd_speed_sw}) do item:visibility(false) end

local fl_sw=grp_msc:switch(ui.get_icon("tower-broadcast").."  Fake Latency",false)
fl_sw:tooltip("Override NL Fake Latency with a custom value.")
local fl_val
do
    local sub=fl_sw:create()
    fl_val=sub:slider("Value",0,400,100,1,function(v) return v.."ms" end)
end
fl_sw:visibility(false)
local _fl_ref=(function()
    local ok,v=pcall(ui.find,"Miscellaneous","Main","Other","Fake Latency")
    return ok and v or nil
end)()

-- ════════════════════════════════════════════════════════════════
--  PLAYER LIST / WHITELIST
-- ════════════════════════════════════════════════════════════════
local WL_ICO = {
    ENEMY = ui.get_icon("crosshairs"),
    ALLY  = ui.get_icon("shield-halved"),
    ALIVE = ui.get_icon("user"),
    DEAD  = ui.get_icon("skull"),
}

local wl_whitelist   = {}
local wl_pdata       = {}
local wl_spoofed     = {}
local wl_rebuilding  = false
local wl_last_time   = -999
local wl_last_xuids  = {}
local wl_was_visible = false
local WL_INTERVAL    = 1.5

local wl_lbl_none = grp_msc:label("  No players in server")
local wl_list     = grp_msc:listable("Players \a474747FF Click to whitelist"," ")
wl_lbl_none:visibility(false)
wl_list:visibility(false)

local function restore_wl_teams()
    for _,s in ipairs(wl_spoofed) do
        if s.ent then pcall(function() s.ent.m_iTeamNum=s.team end) end
    end
    wl_spoofed={}
end

local function wl_reapply_sels()
    if #wl_pdata == 0 then return end
    wl_rebuilding = true
    local sels = {}
    for i, pd in ipairs(wl_pdata) do sels[i] = (wl_whitelist[pd.xuid] == true) end
    pcall(function() wl_list:set(table.unpack(sels)) end)
    utils.execute_after(0.3, function() wl_rebuilding = false end)
end

local function rebuild_wl()
    local lp = entity.get_local_player()
    if not lp then wl_pdata = {}; wl_last_xuids = {}; return end
    local raw = entity.get_players(false, true)
    local new_pdata = {}
    for _, p in ipairs(raw) do
        if p ~= lp and p:is_enemy() then
            new_pdata[#new_pdata + 1] = {
                xuid  = p:get_xuid(),
                name  = p:get_name(),
                alive = p:is_alive(),
                enemy = p:is_enemy(),
            }
        end
    end
    wl_pdata = new_pdata
    if #wl_pdata == 0 then wl_last_xuids = {}; return end
    local current_xuids = {}
    for _, pd in ipairs(wl_pdata) do current_xuids[#current_xuids + 1] = pd.xuid end
    local structural = (#current_xuids ~= #wl_last_xuids)
    if not structural then
        for i, x in ipairs(current_xuids) do
            if x ~= wl_last_xuids[i] then structural = true; break end
        end
    end
    local labels = {}
    for _, pd in ipairs(wl_pdata) do
        local t = pd.enemy and WL_ICO.ENEMY or WL_ICO.ALLY
        local l = pd.alive and WL_ICO.ALIVE  or WL_ICO.DEAD
        labels[#labels + 1] = t .. "  " .. l .. "  " .. pd.name
    end
    if structural then
        wl_last_xuids = current_xuids
        wl_rebuilding = true
        wl_list:update(table.unpack(labels))
        local sels = {}
        for i, pd in ipairs(wl_pdata) do sels[i] = (wl_whitelist[pd.xuid] == true) end
        pcall(function() wl_list:set(table.unpack(sels)) end)
        utils.execute_after(0.3, function() wl_rebuilding = false end)
    end
end

wl_list:set_callback(function()
    if wl_rebuilding then return end
    local val = wl_list:get()
    if type(val) ~= "table" then return end
    local prev = wl_whitelist
    wl_whitelist = {}
    for i, v in ipairs(val) do
        if wl_pdata[i] then
            local sel = (v == true)
                or (type(v) == "string" and v ~= "" and v ~= " ")
                or (type(v) == "number" and v ~= 0)
            if sel then wl_whitelist[wl_pdata[i].xuid] = true end
        end
    end
    for xuid in pairs(prev) do
        if not wl_whitelist[xuid] then restore_wl_teams(); break end
    end
end)

-- ════════════════════════════════════════════════════════════════
--  MASTER VISIBILITY
-- ════════════════════════════════════════════════════════════════
local function list_idx(widget)
    local raw=widget:get()
    if type(raw)=="number" then return raw end
    if type(raw)=="table" then return raw[1] or 1 end
    return 1
end
local function hide_all_builder()
    for ci=1,#teams*#states do
        local m=aa_builder[ci]
        if m then
            m.override_global:visibility(false); m.yaw_switch:visibility(false)
            m.yaw_mod:visibility(false); m.desync:visibility(false) 
            m.defensive:visibility(false); m.snap:visibility(false)
        end
    end
end
local function hide_global_builder()
    local g=aa_builder[0]
    if g then g.yaw_switch:visibility(false); g.yaw_mod:visibility(false); g.desync:visibility(false); g.defensive:visibility(false); g.snap:visibility(false) end
end
local function show_global_builder()
    local g=aa_builder[0]
    if g then g.yaw_switch:visibility(true); g.yaw_mod:visibility(true); g.desync:visibility(true); g.defensive:visibility(true); g.snap:visibility(true) end
end

local function update_visibility()
    local top_idx=list_idx(nav_list)
    local is_aa=top_idx==NAV.AA; local is_rb=top_idx==NAV.RB
    local is_vis=top_idx==NAV.VIS; local is_msc=top_idx==NAV.MSC
    aa_sub_nav:visibility(is_aa)
    grp_stats:visibility(is_aa)
    if is_aa then
        local sub_idx=list_idx(aa_sub_nav)
        local on_builder = sub_idx==AA_SUB.SETTINGS
        local on_config  = sub_idx==AA_SUB.WIP

        wip_label:visibility(false)

        -- always hide settings widgets first
        set_freestanding_sw:visibility(false); avoid_backstab_sw:visibility(false)
        safe_head_sw:visibility(false); manual_aa_sw:visibility(false)
        falling_combo:visibility(false); dir_legs_sel:visibility(false)
        new_abf_sw:visibility(false)
        -- always hide snap widget first

        state_sel:visibility(on_builder); state_lbl:visibility(on_builder)

        if on_builder then
            local cs=state_sel:get()
            if cs=="Global" then
                team_sel:visibility(false); show_global_builder(); hide_all_builder()
            else
                team_sel:visibility(true); hide_global_builder()
                local ct=team_sel:get()
                for ti,tn in ipairs(teams) do
                    for si,sn in ipairs(states) do
                        local ci=(ti-1)*#states+si; local m=aa_builder[ci]
                        if m then
                            local v=(ct==tn) and (cs==sn); local v_aa=v and m.override_global:get()
                            m.override_global:visibility(v); m.yaw_switch:visibility(v_aa)
                            m.yaw_mod:visibility(v_aa); m.desync:visibility(v_aa)
                            m.defensive:visibility(v_aa); m.snap:visibility(v_aa)
                        end
                    end
                end
            end

        elseif on_config then
            -- Settings tab
            team_sel:visibility(false)
            hide_global_builder(); hide_all_builder()
            set_freestanding_sw:visibility(true); avoid_backstab_sw:visibility(true)
            safe_head_sw:visibility(true); manual_aa_sw:visibility(true)
            falling_combo:visibility(true); dir_legs_sel:visibility(true)
            new_abf_sw:visibility(true)
        else
            team_sel:visibility(false)
            hide_global_builder(); hide_all_builder()
        end
    else
        wip_label:visibility(false); team_sel:visibility(false)
        state_sel:visibility(false); state_lbl:visibility(false)
        hide_global_builder(); hide_all_builder()
        set_freestanding_sw:visibility(false); avoid_backstab_sw:visibility(false)
        safe_head_sw:visibility(false); manual_aa_sw:visibility(false)
        falling_combo:visibility(false); dir_legs_sel:visibility(false)
        new_abf_sw:visibility(false)
    end
    curse_sw:visibility(is_rb); disable_fl_sw:visibility(is_rb)
    air_hc_sw:visibility(is_rb)
    aimlog_sw:visibility(is_vis); mindmg_ind:visibility(is_vis); scope_sw:visibility(is_vis)
    crosshair_ind:visibility(is_vis)
    local ci_on=is_vis and crosshair_ind:get()
    ci_ui.show_dt:visibility(ci_on); ci_ui.show_osaa:visibility(ci_on)
    ci_ui.scope_shift:visibility(ci_on)
    ci_ui.scope_x:visibility(ci_on and ci_ui.scope_shift:get())
    ci_ui.scope_y:visibility(ci_on and ci_ui.scope_shift:get())
    ci_ui.glow:visibility(ci_on); ci_ui.glow_int:visibility(ci_on and ci_ui.glow:get())
    notif_sw:visibility(is_vis); keep_trans_sw:visibility(is_vis)
    si_sw:visibility(is_vis); wm_sw:visibility(is_vis); gren_warn_sw:visibility(is_vis)

    msc_sub_nav:visibility(is_msc)
    if is_msc then
        local msc_idx  = list_idx(msc_sub_nav)
        local on_misc  = msc_idx == MSC_SUB.MISC
        local on_pl    = msc_idx == MSC_SUB.PL
        clantag_sw:visibility(on_misc); fastladder_sw:visibility(on_misc)
        killsay_sw:visibility(on_misc); ar_sw:visibility(on_misc); vm_sw:visibility(on_misc)
        avoid_coll_sw:visibility(on_misc); no_fall_sw:visibility(on_misc)
        edge_qs_sw:visibility(on_misc); fd_speed_sw:visibility(on_misc); fl_sw:visibility(on_misc)
        local has_players = #wl_pdata > 0
        local should_show = on_pl and has_players
        wl_lbl_none:visibility(on_pl and not has_players)
        if should_show ~= wl_was_visible then
            wl_list:visibility(should_show)
            if should_show then wl_reapply_sels() end
            wl_was_visible = should_show
        end
    else
        clantag_sw:visibility(false); fastladder_sw:visibility(false)
        killsay_sw:visibility(false); ar_sw:visibility(false); vm_sw:visibility(false)
        avoid_coll_sw:visibility(false); no_fall_sw:visibility(false)
        edge_qs_sw:visibility(false); fd_speed_sw:visibility(false); fl_sw:visibility(false)
        wl_lbl_none:visibility(false)
        if wl_was_visible then wl_list:visibility(false); wl_was_visible = false end
    end
end

nav_list:set_callback(update_visibility,true)
aa_sub_nav:set_callback(update_visibility)
msc_sub_nav:set_callback(update_visibility)
team_sel:set_callback(update_visibility); state_sel:set_callback(update_visibility)
aimlog_sw:set_callback(update_visibility); mindmg_ind:set_callback(update_visibility)
crosshair_ind:set_callback(update_visibility); ci_ui.glow:set_callback(update_visibility)
ci_ui.scope_shift:set_callback(update_visibility); notif_sw:set_callback(update_visibility)
ar_sw:set_callback(update_visibility); vm_sw:set_callback(update_visibility)
si_sw:set_callback(update_visibility)
for ci=1,#teams*#states do
    local m=aa_builder[ci]
    if m and m.override_global then m.override_global:set_callback(update_visibility) end
end

-- ════════════════════════════════════════════════════════════════
--  FAST LADDER
-- ════════════════════════════════════════════════════════════════
local function apply_fast_ladder(cmd,lp)
    if not fastladder_sw:get() then return end
    if lp.m_MoveType~=9 then return end
    local ok_ang,cam_ang=pcall(render.camera_angles)
    local pitch_x=(ok_ang and cam_ang) and cam_ang.x or cmd.view_angles.x
    local cur_y=cmd.view_angles.y
    if cmd.forwardmove>0 then
        if pitch_x<45 then
            cmd.view_angles=vector(89,cur_y+89,0)
            cmd.in_moveright=1; cmd.in_moveleft=0; cmd.in_forward=0; cmd.in_back=1
            local sm=cmd.sidemove
            if sm==0 then cmd.move_yaw=cmd.move_yaw+90
            elseif sm<0 then cmd.move_yaw=cmd.move_yaw+150
            elseif sm>0 then cmd.move_yaw=cmd.move_yaw+30 end
        end
    elseif cmd.forwardmove<0 then
        cmd.view_angles=vector(89,cur_y+89,0)
        cmd.in_moveright=1; cmd.in_moveleft=0; cmd.in_forward=1; cmd.in_back=0
        local sm=cmd.sidemove
        if sm==0 then cmd.move_yaw=cmd.move_yaw+90
        elseif sm>0 then cmd.move_yaw=cmd.move_yaw+150
        elseif sm<0 then cmd.move_yaw=cmd.move_yaw+30 end
    end
end

local ds_data={}
ds_data[0]={sent_packets=0,direction=true,next_flip_at=-1,snap_idx=1,snap_lc=0}
for i=1,#teams*#states do ds_data[i]={sent_packets=0,direction=true,next_flip_at=-1,snap_idx=1,snap_lc=0} end

local st={
    last_cond_idx=-1,def_jitter=false,def_aa_pitch=nil,def_aa_yaw=nil,def_aa_hold=0,
    safe_head_latch=0,air_ground_latch=0,air_latch_cond=-1,ground_ticks=0,
    fall_air_time=0.0,ktrans_cur=255.0,ktrans_from=255.0,ktrans_start=0.0,
    ktrans_dur=0.0,ktrans_prev=255.0,sc_gap=0,sc_len=0,
}


-- ════════════════════════════════════════════════════════════════
--  SNAP BUILDER LOGIC (Break LC) — per-state, called in createmove
-- ════════════════════════════════════════════════════════════════
local function snap_builder_tick(active_cfg, ds)
    if not active_cfg.snap or not active_cfg.snap:get() then
        if ds then ds.snap_idx=1; ds.snap_lc=0 end
        return
    end
    local s   = active_cfg.snap_ui
    local lp  = entity.get_local_player()
    if not lp or not lp:is_alive() then return end
    local weapon = lp:get_player_weapon()
    if not weapon then return end
    if s.no_gren:get() then
        local wi=weapon:get_weapon_info()
        if wi and wi.weapon_type==9 then return end
    end
    local mode=s.choke:get()
    if mode=="Custom" then
        if s.rand:get() then
            local lo=math.min(s.from_v:get(),s.to_v:get())
            local hi=math.max(s.from_v:get(),s.to_v:get())
            if globals.tickcount%math.random(lo,hi)==0 then refs.lag_opts:override("Always on") end
        else
            if globals.tickcount%s.choke_v:get()==0 then refs.lag_opts:override("Always on") end
        end
    elseif mode=="Sliders" then
        local count=math.max(1,math.min(8,s.slider_count:get()))
        if ds.snap_idx>count then ds.snap_idx=1 end
        local val=math.max(1,s.sliders[ds.snap_idx]:get())
        if globals.tickcount%val==0 then refs.lag_opts:override("Always on") end
        local cur=globals.choked_commands
        if cur==0 and ds.snap_lc>0 then ds.snap_idx=ds.snap_idx%count+1 end
        ds.snap_lc=cur
    else
        refs.lag_opts:override("Always on")
    end
    refs.hs_opts:override(s.hs_mode:get())
end
-- ─────────────────────────────────────────────────────────────


-- ════════════════════════════════════════════════════════════════
--  GAZOLINA ABF LOGIC
-- ════════════════════════════════════════════════════════════════
local push_notif  -- forward-declared; defined after notif_queue below

local new_abf = {}
do
    local _last_tick=0; local _reset_time=0; local _active=false; local _offset=0
    local function _reset() _active=false; _last_tick=0; _reset_time=0; _offset=0 end

    events.bullet_impact:set(function(e)
        local lp=entity.get_local_player()
        if not lp or not lp:is_alive() then return end
        if not new_abf_sw:get() then return end
        local shooter=entity.get(e.userid,true)
        if not shooter or not shooter:is_alive() or shooter:is_dormant() then return end
        if shooter.m_iTeamNum==lp.m_iTeamNum then return end
        if _last_tick==globals.tickcount then return end
        local impact=vector(e.x,e.y,e.z)
        local sep=shooter:get_eye_position()
        local hp; pcall(function() hp=lp:get_hitbox_position(0) end)
        if not hp then hp=lp.m_vecOrigin+vector(0,0,64) end
        local ok_cp,closest=pcall(function() return hp:closest_ray_point(sep,impact) end)
        if not ok_cp or not closest then return end
        local dist=closest:dist(hp)
        if dist>40 then return end
        local cur_state=states[get_state()] or ""
        local sel=new_abf_ui.states:get() or {}
        local ok=false
        for _,s in ipairs(sel) do if s==cur_state then ok=true; break end end
        if not ok then return end
        _last_tick=globals.tickcount; _reset_time=globals.realtime+3
        local mode=new_abf_ui.mode:get()
        if     mode=="Increasing" then _offset=math.random(-5,10)
        elseif mode=="Decreasing" then _offset=5
        else                           _offset=math.random(-15,15) end
        push_notif(string.format("ABF triggered by %s [%.0fu]",shooter:get_name(),dist),color(100,200,255,255))
    end)

    function new_abf.tick()
        if not new_abf_sw:get() then _reset(); return end
        if _reset_time<=globals.realtime then _reset(); return end
        _active=true
        local cur=refs.yaw_offset:get_override() or 0
        refs.yaw_offset:override(cur+(rage.antiaim:inverter() and _offset or -_offset))
    end
end
-- ─────────────────────────────────────────────────────────────

local function reset_ds(ci)
    ds_data[ci].sent_packets=0; ds_data[ci].next_flip_at=-1
end
local function next_flip_offset(hold,variance)
    local extra=(variance>0) and math.random(0,variance) or 0
    return math.max(2,hold+extra)
end

local si_st={
    hits=0, misses=0, site=nil,
    ping_fl=ui.find("Miscellaneous","Main","Other","Fake Latency"),
    plant_t=0.0, planter=nil, anim_dur=3.125,
    font=render.load_font("Calibri Bold",vector(25,23.5),"da"),
    bomb_tex=nil,
}
pcall(function() si_st.bomb_tex=render.load_image_from_file("materials/panorama/images/icons/ui/bomb_c4.svg",vector(32,32)) end)

local notif_queue={}; local NOTIF_H=30; local NOTIF_GAP=5
local notif_icon_font=render.load_font("Verdana",12,"u")
push_notif = function(text,accent_col)
    if not notif_sw:get() then return end
    local lim=n_ui.limit:get()
    while #notif_queue>=lim do table.remove(notif_queue,1) end
    table.insert(notif_queue,{
        text=text,accent=accent_col or color(80,220,100,255),
        spawn_t=globals.realtime,alpha=0.0,drop_y=0.0,cur_y=0,target_y=0,ready=false,
    })
end



-- ════════════════════════════════════════════════════════════════
--  EVENTS
-- ════════════════════════════════════════════════════════════════


local _last_fire={}
events.aim_fire:set(function(e)
    local idx=e.target and e.target:get_index() or 0
    _last_fire[idx]={hg=hitgroup_str[e.hitgroup] or ("hg"..tostring(e.hitgroup)),pred_dmg=e.damage,hitchance=e.hitchance,backtrack=e.backtrack}
end)
events.aim_ack:set(function(e)
    if e.state==nil then si_st.hits=si_st.hits+1 else si_st.misses=si_st.misses+1 end
    local target=e.target and e.target:get_name() or "?"
    local hg=e.hitgroup and (hitgroup_str[e.hitgroup] or "hg"..e.hitgroup) or "?"
    local idx=e.target and e.target:get_index() or 0
    local fire=_last_fire[idx] or {}
    local pred=fire.pred_dmg or 0; local hc=fire.hitchance or e.hitchance or 0; local bt=fire.backtrack or e.backtrack or 0
    _last_fire[idx]=nil
    local PFX="\a7483c3FF[zazahook]\a888888FF "
    if e.state==nil then
        if aimlog_sw:get() then
            print_raw(string.format("%s\a7483c3FF HIT  \a888888FF│ \aFFFFFFFF%-16s\a888888FF│ hb \a88ccFFFF%-11s\a888888FF│ pred \a888888FF~\a55aaffFF%-4d\a888888FF│ dealt \a22CC44FF%-4d\a888888FF│ hc \a55aaffFF%d%%\a888888FF│ bt \a55aaffFF%dtk",PFX,target,hg,pred,e.damage,hc,bt))
        end
        push_notif(string.format("Hit %s's %s for %d damage (bt: %d)",target,hg,e.damage,bt),n_ui.cp_accent:get())
    else
        if aimlog_sw:get() then
            print_raw(string.format("%s\aFF3333FF MISS \a888888FF│ \aFFFFFFFF%-16s\a888888FF│ hb \a88ccFFFF%-11s\a888888FF│ pred \a888888FF~\a55aaffFF%-4d\a888888FF│ hc \a55aaffFF%d%%\a888888FF│ bt \a55aaffFF%dtk\a888888FF│ \aFF8800FF%s",PFX,target,hg,pred,hc,bt,e.state))
        end
        push_notif(string.format("Missed %s's %s \xe2\x80\x94 %s",target,hg,e.state),color(255,75,75,255))
    end
end)

events.player_death:set(function(e)
    local me=entity.get_local_player()
    if me then
        if entity.get(e.userid,true)==me then si_st.hits=0; si_st.misses=0 end
        if killsay_sw:get() then
            local attacker=entity.get(e.attacker,true)
            if attacker==me and e.attacker~=e.userid then
                local msg=KILLSAY_MSGS[math.random(#KILLSAY_MSGS)]
                local say_cmd=killsay_mode:get()=="Team Chat" and "say_team" or "say"
                local delay=killsay_delay_sl:get()
                utils.execute_after(delay,function() utils.console_exec(say_cmd..' "'..msg..'"') end)
            end
        end
    end
end)
events.round_start:set(function() si_st.site=nil; si_st.planter=nil; si_st.hits=0; si_st.misses=0 end)
events.level_init:set(function() si_st.hits=0; si_st.misses=0 end)
events.bomb_beginplant:set(function(e)
    local pr=entity.get_player_resource(); if not pr then return end
    local se=entity.get(e.site); if not se then return end
    local center=se.m_vecMins:lerp(se.m_vecMaxs,0.5)
    si_st.site=center:distsqr(pr.m_bombsiteCenterA)<center:distsqr(pr.m_bombsiteCenterB) and "A" or "B"
    si_st.plant_t=globals.curtime; si_st.planter=entity.get(e.userid,true)
end)
events.bomb_abortplant:set(function() si_st.site=nil; si_st.planter=nil end)
events.bomb_planted:set(function() si_st.site=nil; si_st.planter=nil end)

local function get_weapon_class(lp)
    local ok,cls=pcall(function()
        local handle=lp.m_hActiveWeapon; if not handle then return nil end
        local wp=entity.get(handle); if not wp then return nil end
        return wp:get_classname()
    end)
    if ok and type(cls)=="string" then return cls:lower() end
    return nil
end
local function safe_head_active(lp)
    if not safe_head_sw:get() then st.safe_head_latch=0; return false end
    local triggers=safe_head_opts:get() or {}
    if #triggers==0 then st.safe_head_latch=0; return false end
    local want_knife,want_zeus,want_far=false,false,false
    for _,t in ipairs(triggers) do
        if t=="Knife" then want_knife=true end
        if t=="Zeus"  then want_zeus=true end
        if t=="Far from Enemy" then want_far=true end
    end
    if want_far then
        local my_pos=lp:get_origin()
        local min_dist=math.huge
        for _,p in ipairs(entity.get_players(true)) do
            if p:is_alive() then
                local d=my_pos:dist(p:get_origin())
                if d<min_dist then min_dist=d end
            end
        end
        if min_dist>safe_head_dist:get() then return true end
    end
    if want_knife or want_zeus then
        local cls=get_weapon_class(lp)
        if cls then
            local weapon_ok=(want_knife and cls:find("knife")~=nil) or (want_zeus and cls:find("taser")~=nil)
            if weapon_ok then
                if get_state()==4 then st.safe_head_latch=SAFE_HEAD_GRACE; return true end
                if st.safe_head_latch>0 then st.safe_head_latch=st.safe_head_latch-1; return true end
                return false
            end
        end
    end
    st.safe_head_latch=0; return false
end

-- ════════════════════════════════════════════════════════════════
--  CREATEMOVE
-- ════════════════════════════════════════════════════════════════
events.createmove:set(function(cmd)
    restore_wl_teams()
    local lp=entity.get_local_player()
    if not lp or not lp:is_alive() then return end
    local my_team=lp.m_iTeamNum
    for _,p in ipairs(entity.get_players(true)) do
        if wl_whitelist[p:get_xuid()] then
            local real=p.m_iTeamNum
            wl_spoofed[#wl_spoofed+1]={ent=p,team=real}
            p.m_iTeamNum=my_team
        end
    end

    -- In Air Hitchance
    if air_hc_sw:get() and refs.hitchance then
        local anim_st=lp:get_anim_state()
        local on_ground_hc=anim_st and (anim_st.on_ground==true) and (cmd.in_jump==false)
        local weapon_hc=lp:get_player_weapon()
        if weapon_hc then
            local wi_hc=weapon_hc:get_weapon_info()
            if wi_hc then
                local wid=weapon_hc:get_weapon_index()
                if not on_ground_hc then
                    if (wid==40 or wid==64) and airhc_route[wid] and airhc_route[wid]:get()~=-1 then
                        refs.hitchance:override(airhc_route[wid]:get())
                    else
                        refs.hitchance:override()
                    end
                else
                    refs.hitchance:override()
                end
            end
        end
    elseif refs.hitchance then
        refs.hitchance:override()
    end

    if bit.band(lp.m_fFlags,1)~=0 then st.fall_air_time=0.0
    else st.fall_air_time=st.fall_air_time+globals.tickinterval end
    apply_fast_ladder(cmd,lp)
    if refs.freestanding then refs.freestanding:override(set_freestanding_sw:get() or nil) end
    if refs.avoid_backstab then refs.avoid_backstab:override(avoid_backstab_sw:get() or nil) end
    if refs.fakelag and disable_fl_sw:get() then
        local dt_on=refs.dt_main and refs.dt_main:get() or false
        local hs_on=refs.hs_main and refs.hs_main:get() or false
        refs.fakelag:override((dt_on or hs_on) and false or nil)
    elseif refs.fakelag then refs.fakelag:override() end
    local raw_cond_idx=get_cond_idx(cmd); local cond_idx
    do
        local raw_s=(raw_cond_idx-1)%#states+1; local now_air=raw_s==3 or raw_s==4
        if st.air_ground_latch>0 then
            if now_air then st.air_ground_latch=0; st.ground_ticks=0
            else
                st.ground_ticks=st.ground_ticks+1
                if st.ground_ticks>=GROUND_CONFIRM then st.air_ground_latch=0; st.ground_ticks=0
                else st.air_ground_latch=st.air_ground_latch-1 end
            end
        else
            st.ground_ticks=0
            if st.last_cond_idx>0 then
                local prev_s=(st.last_cond_idx-1)%#states+1; local was_air=prev_s==3 or prev_s==4
                if was_air and not now_air then
                    st.air_latch_cond=st.last_cond_idx; st.air_ground_latch=AIR_GROUND_GRACE; st.ground_ticks=1
                end
            end
        end
        cond_idx=(st.air_ground_latch>0) and st.air_latch_cond or raw_cond_idx
    end
    local cfg=aa_builder[cond_idx]; if not cfg then return end
    local override=cfg.override_global and cfg.override_global:get()
    local active_cfg=override and cfg or aa_builder[0]; local ds_idx=override and cond_idx or 0
    if cond_idx~=st.last_cond_idx then if override then reset_ds(cond_idx) end; st.last_cond_idx=cond_idx end
    local is_sent=(globals.choked_commands==0); local ds=ds_data[ds_idx]
    if is_sent then ds.sent_packets=ds.sent_packets+1; st.def_jitter=not st.def_jitter end
    refs.pitch:override("Down"); refs.yaw:override("Backward"); refs.yaw_base:override("At Target")
    if refs.hidden then refs.hidden:override() end
    if st.def_aa_hold>0 then st.def_aa_hold=st.def_aa_hold-1
    else st.def_aa_pitch=nil; st.def_aa_yaw=nil end
    if active_cfg.desync:get() then
        refs.body_yaw:override(true); refs.body_left:override(active_cfg.ds.left:get())
        refs.body_right:override(active_cfg.ds.right:get()); refs.body_opts:override(active_cfg.ds.opts:get())
    else refs.body_yaw:override(false) end
    local sh_active=safe_head_active(lp)
    if sh_active then
        refs.yaw_mod:override("Disabled"); refs.yaw_mod_offset:override(0)
        refs.yaw_offset:override(0)
        refs.body_yaw:override(false)
    else
        local yaw_mod_sel=active_cfg.yaw_mod:get(); refs.yaw_mod:override(yaw_mod_sel)
        if yaw_mod_sel=="Offset" then
            local base_off=active_cfg.ym.offset:get(); local rand_val=active_cfg.ym.randomize:get()
            if rand_val>0 then base_off=base_off+math.random(-rand_val,rand_val) end
            refs.yaw_mod_offset:override(base_off)
        else refs.yaw_mod_offset:override(0) end
        if active_cfg.yaw_switch:get() then
            local mode=active_cfg.ys.mode:get(); local micro=active_cfg.ys.micro:get()
            local function with_micro(y) if micro>0 then return y+math.random(-micro,micro) end; return y end
            if mode=="L&R Yaw" then
                local inv=rage.antiaim:inverter()
                local base=inv and active_cfg.ys.right:get() or active_cfg.ys.left:get()
                refs.yaw_offset:override(with_micro(base))
            elseif mode=="Delayed Switch" then
                local hold=active_cfg.ys.delay:get(); local variance=active_cfg.ys.jitter:get(); local ap_on=active_cfg.ys.ap_on:get()
                if is_sent and ds.next_flip_at<0 then ds.next_flip_at=ds.sent_packets+next_flip_offset(hold,variance) end
                if is_sent and ds.next_flip_at>=0 and ds.sent_packets>=ds.next_flip_at then
                    ds.direction=not ds.direction
                    local offset=next_flip_offset(hold,variance)
                    if ap_on then
                        local chance=active_cfg.ys.ap_chance:get()
                        if math.random(1,100)<=chance then
                            local kind=active_cfg.ys.ap_kind:get()
                            if kind=="Random Mix" then kind=(math.random(1,2)==1) and "Snap Flip" or "Long Hold" end
                            if kind=="Snap Flip" then offset=math.max(2,math.floor(hold/4))
                            elseif kind=="Long Hold" then offset=next_flip_offset(hold*2,variance) end
                        end
                    end
                    ds.next_flip_at=ds.sent_packets+offset
                end
                rage.antiaim:inverter(ds.direction)
                local base=ds.direction and active_cfg.ys.left:get() or active_cfg.ys.right:get()
                refs.yaw_offset:override(with_micro(base))
            end
        else refs.yaw_offset:override(0) end
    end
    if (not sh_active or safe_head_def_sw:get()) and active_cfg.defensive:get() then
        local def=active_cfg.def; local triggers=def.triggers:get() or {}
        local dt_ready=rage.exploit:get()==1; local hs_on=refs.hs_main and refs.hs_main:get() or false
        local fake_ducking=false
        pcall(function() local fd_ref=ui.find("Aimbot","Anti Aim","Misc","Fake Duck"); if fd_ref then fake_ducking=fd_ref:get() end end)
        if refs.lag_opts then refs.lag_opts:override() end
        if refs.hs_opts  then refs.hs_opts:override() end
        if def.force_defensive:get() then
            if def.custom_choke:get() then
                local choke=def.random_choke:get() and math.random(def.choke_1:get(),def.choke_2:get()) or def.choke_1:get()
                pcall(function() cmd.force_defensive=cmd.command_number%choke==0 end)
            else
                pcall(function() cmd.force_defensive=cmd.command_number%16==0 end)
                if refs.lag_opts then refs.lag_opts:override("Always on") end
                if refs.hs_opts  then refs.hs_opts:override("Break LC") end
            end
        end
        local trigger_met=false
        for _,t in ipairs(triggers) do
            if t=="DT Ready" and dt_ready then trigger_met=true end
            if t=="Hide Shots" and hs_on then trigger_met=true end
        end
        if trigger_met and def.enabled:get() and dt_ready and not fake_ducking then
            local pm=def.pitch:get(); local pitch_val=0
            if pm=="Static" then pitch_val=def.pitch_offset:get()
            elseif pm=="Jitter" then pitch_val=st.def_jitter and def.pitch_1:get() or def.pitch_2:get()
            elseif pm=="Random" then
                local p1,p2=def.pitch_1:get(),def.pitch_2:get()
                pitch_val=(p1<=p2) and utils.random_int(p1,p2) or utils.random_int(p2,p1)
            elseif pm=="Spin" then
                local t2=globals.curtime*1.5
                pitch_val=def.pitch_1:get()+(def.pitch_2:get()-def.pitch_1:get())*(t2%1)
            elseif pm=="Sway" then
                local t2=globals.curtime*5
                pitch_val=def.pitch_1:get()+(def.pitch_2:get()-def.pitch_1:get())*(math.sin(t2)%1)
            end
            local ym2=def.yaw:get(); local yaw_val=0
            if ym2=="Static" then
                refs.body_yaw:override(true); refs.body_left:override(active_cfg.ds.left:get()); refs.body_right:override(active_cfg.ds.right:get())
                yaw_val=def.yaw_offset:get()
            elseif ym2=="Switch" then yaw_val=st.def_jitter and def.yaw_1:get() or def.yaw_2:get()
            elseif ym2=="Random" then
                refs.body_yaw:override(true); refs.body_left:override(active_cfg.ds.left:get()); refs.body_right:override(active_cfg.ds.right:get())
                local y1,y2=def.yaw_1:get(),def.yaw_2:get()
                yaw_val=(y1<=y2) and utils.random_int(y1,y2) or utils.random_int(y2,y1)
            elseif ym2=="Spin" then
                refs.body_yaw:override(true); refs.body_left:override(active_cfg.ds.left:get()); refs.body_right:override(active_cfg.ds.right:get())
                local spd=globals.curtime*def.yaw_speed:get()*0.1; local half=def.yaw_offset:get()*0.5
                yaw_val=-half+(half*2)*(spd%1)
            elseif ym2=="Sway" then
                refs.body_yaw:override(true); refs.body_left:override(active_cfg.ds.left:get()); refs.body_right:override(active_cfg.ds.right:get())
                local spd=globals.curtime*def.yaw_speed:get()*0.1; local half=def.yaw_offset:get()*0.5
                yaw_val=-half+(half*2)*(math.sin(spd)%1)
            end
            if refs.hidden then refs.hidden:override(true) end
            rage.antiaim:override_hidden_pitch(pitch_val); rage.antiaim:override_hidden_yaw_offset(yaw_val)
            st.def_aa_pitch=pitch_val; st.def_aa_yaw=yaw_val; st.def_aa_hold=3
        end
    end
    if manual_aa_sw:get() then
        local _mdir={Left=-90,Right=90,Backward=0,Forward=180}
        local moff=_mdir[manual_dir:get()]
        if moff~=nil then
            local cur_st=states[get_state()]
            if not manual_disablers_sel:get(cur_st) then
                if manual_static_sw:get() then
                    if refs.yaw_modifier then refs.yaw_modifier:override("Disabled") end
                    if refs.body_yaw then refs.body_yaw:override("Left") end
                    refs.yaw_offset:override(moff)
                else
                    local base=refs.yaw_offset:get_override() or refs.yaw_offset:get() or 0
                    refs.yaw_offset:override(base+moff)
                end
                refs.yaw_base:override("Local view")
                if refs.lag_opts then refs.lag_opts:override() end
                if refs.hs_opts  then refs.hs_opts:override() end
                return
            end
        end
    end
    -- clear lag/hs opts, then let snap builder and ABF override
    if refs.lag_opts then refs.lag_opts:override() end
    if refs.hs_opts  then refs.hs_opts:override() end

    -- ── Snap Builder (Break LC) ───────────────────────────────────
    snap_builder_tick(active_cfg, ds)
    -- ─────────────────────────────────────────────────────────────

    avoid_coll_tick(cmd); no_fall_tick(cmd); edge_qs_tick(cmd); gw_createmove_tick(cmd)
    new_abf.tick()
end)

-- Fake Duck Speed
local function event_fakeduck_speed(cmd)
    if not fd_speed_sw:get() then return end
    if not refs.fakeduck_ref or not refs.fakeduck_ref:get() then return end
    local move=vector(cmd.forwardmove,cmd.sidemove)
    if move:length2dsqr()<25 then return end
    move:normalize()
    cmd.forwardmove=move.x*150
    cmd.sidemove=move.y*150
end
events.createmove_run:set(function(cmd)
    restore_wl_teams()
    event_fakeduck_speed(cmd)
end)

events.post_update_clientside_animation:set(function(ent)
    local lp=entity.get_local_player(); if ent~=lp then return end
    if st.def_aa_pitch~=nil or st.def_aa_hold>0 then
        pcall(function()
            local eye=ent.m_angEyeAngles; if not eye then return end
            ent.m_angEyeAngles=vector(st.def_aa_pitch,eye.y,0)
        end)
    end
    local fall_str=falling_combo:get(); local fall_mode=0
    if fall_str=="Force" then fall_mode=1 elseif fall_str=="Legacy" then fall_mode=2 end
    if fall_mode>0 then
        pcall(function()
            local params=ent.m_flPoseParameter; if not params then return end
            if fall_mode==1 then params[0]=0.5; params[6]=0.5
            else
                local clamped=math.max(0.7,math.min(1.5,st.fall_air_time))
                params[6]=(clamped-0.7)/(1.5-0.7)
            end
        end)
    end
    local dl=dir_legs_sel:get() or {}
    local dl_ground,dl_jump,dl_jitter=false,false,false
    for _,v in ipairs(dl) do
        if v=="Ground"  then dl_ground=true end
        if v=="Jumping" then dl_jump=true end
        if v=="Jitter"  then dl_jitter=true end
    end
    if dl_ground or dl_jump then
        pcall(function()
            local params=ent.m_flPoseParameter; if not params then return end
            local grounded=bit.band(lp.m_fFlags,1)~=0
            if dl_ground and grounded then params[0]=0.5; params[7]=1.0 end
        end)
    end
    if dl_jitter then
        pcall(function()
            if refs.leg_movement then refs.leg_movement:override("Sliding") end
            if bit.band(globals.tickcount,3)>1 then
                local params=ent.m_flPoseParameter
                if params then params[0]=1; params[1]=1 end
            end
        end)
    else
        pcall(function() if refs.leg_movement then refs.leg_movement:override() end end)
    end
end)

events.localplayer_transparency:set(function(t)
    if not keep_trans_sw:get() then return end
    local lp=entity.get_local_player(); if not lp then return end
    local is_scoped=lp.m_bResumeZoom or false; local ct=globals.curtime
    local target=is_scoped and 59.0 or (t*1.0)
    if math.abs(target-st.ktrans_prev)>0.5 then
        st.ktrans_from=st.ktrans_cur; st.ktrans_start=ct
        st.ktrans_dur=math.abs(target-st.ktrans_from)*0.00035; st.ktrans_prev=target
    end
    if st.ktrans_dur>0.001 and ct<st.ktrans_start+st.ktrans_dur then
        local frac=(ct-st.ktrans_start)/st.ktrans_dur
        st.ktrans_cur=st.ktrans_from+(target-st.ktrans_from)*frac
    else st.ktrans_cur=target; st.ktrans_dur=0.0 end
    return math.floor(math.max(0,math.min(255,st.ktrans_cur))+0.5)
end)

-- ════════════════════════════════════════════════════════════════
--  PRESETS
-- ════════════════════════════════════════════════════════════════
local DB_LIST="builder_v9_list"; local DB_LAST="builder_v9_last"; local DB_PREFIX="builder_v9_p_"
local base64=require("neverlose/base64")
local clipboard=(function()
    local ok_ffi,ffi=pcall(require,"ffi"); if not ok_ffi then return nil end
    pcall(function()
        ffi.cdef[[
            typedef void* HWND; typedef void* HANDLE; typedef unsigned int UINT;
            int OpenClipboard(HWND); int CloseClipboard(); int EmptyClipboard();
            HANDLE GetClipboardData(UINT); HANDLE SetClipboardData(UINT,HANDLE);
            HANDLE GlobalAlloc(UINT,size_t); void* GlobalLock(HANDLE);
            int GlobalUnlock(HANDLE); int IsClipboardFormatAvailable(UINT);
        ]]
    end)
    local user32,kernel32; local ok_load=pcall(function() user32=ffi.load("user32"); kernel32=ffi.load("kernel32") end)
    if not ok_load or not user32 or not kernel32 then return nil end
    local CF_TEXT=1; local GMEM_MOVEABLE=0x0002
    local function set(text)
        if type(text)~="string" then return false end
        if user32.OpenClipboard(nil)==0 then return false end
        user32.EmptyClipboard()
        local hmem=kernel32.GlobalAlloc(GMEM_MOVEABLE,#text+1)
        if hmem==nil then user32.CloseClipboard(); return false end
        local p=kernel32.GlobalLock(hmem); if p==nil then user32.CloseClipboard(); return false end
        ffi.copy(p,text); kernel32.GlobalUnlock(hmem); user32.SetClipboardData(CF_TEXT,hmem); user32.CloseClipboard(); return true
    end
    local function get()
        if user32.IsClipboardFormatAvailable(CF_TEXT)==0 then return nil end
        if user32.OpenClipboard(nil)==0 then return nil end
        local h=user32.GetClipboardData(CF_TEXT); if h==nil then user32.CloseClipboard(); return nil end
        local p=kernel32.GlobalLock(h); if p==nil then user32.CloseClipboard(); return nil end
        local text=ffi.string(p); kernel32.GlobalUnlock(h); user32.CloseClipboard(); return text
    end
    return {set=set,get=get}
end)()

local function safe_key(n) return (tostring(n):gsub("[^%w_]","_")) end
local function notify(b) pcall(common.add_notify,"Config",b) end
local function read_preset_list()
    local raw=db[DB_LIST]; if type(raw)~="string" or raw=="" then return {} end
    local ok,p=pcall(json.parse,raw); return (ok and type(p)=="table") and p or {}
end
local function write_preset_list(list) db[DB_LIST]=json.stringify(list) end
local function list_contains(list,name) for _,n in ipairs(list) do if n==name then return true end end; return false end

serialize_entry=function(cfg)
    local d={}
    d.yaw_switch=cfg.yaw_switch:get() and {
        mode=cfg.ys.mode:get(),left=cfg.ys.left:get(),right=cfg.ys.right:get(),
        delay=cfg.ys.delay:get(),jitter=cfg.ys.jitter:get(),micro=cfg.ys.micro:get(),
        ap_on=cfg.ys.ap_on:get(),ap_chance=cfg.ys.ap_chance:get(),ap_kind=cfg.ys.ap_kind:get(),
    } or false
    d.yaw_mod={sel=cfg.yaw_mod:get(),offset=cfg.ym.offset:get(),randomize=cfg.ym.randomize:get()}
    d.desync=cfg.desync:get() and {left=cfg.ds.left:get(),right=cfg.ds.right:get(),opts=cfg.ds.opts:get()} or false
    d.defensive=cfg.defensive:get() and {
        triggers=cfg.def.triggers:get(),force_defensive=cfg.def.force_defensive:get(),
        custom_choke=cfg.def.custom_choke:get(),random_choke=cfg.def.random_choke:get(),
        choke_1=cfg.def.choke_1:get(),choke_2=cfg.def.choke_2:get(),
        enabled=cfg.def.enabled:get(),pitch=cfg.def.pitch:get(),
        pitch_offset=cfg.def.pitch_offset:get(),pitch_1=cfg.def.pitch_1:get(),
        pitch_2=cfg.def.pitch_2:get(),yaw=cfg.def.yaw:get(),
        yaw_offset=cfg.def.yaw_offset:get(),yaw_1=cfg.def.yaw_1:get(),
        yaw_2=cfg.def.yaw_2:get(),yaw_rand=cfg.def.yaw_rand:get(),yaw_speed=cfg.def.yaw_speed:get(),
    } or false
    local s=cfg.snap_ui
    d.snap=cfg.snap:get() and {
        no_gren=s.no_gren:get(),hs_mode=s.hs_mode:get(),
        choke=s.choke:get(),rand=s.rand:get(),
        choke_v=s.choke_v:get(),from_v=s.from_v:get(),to_v=s.to_v:get(),
        slider_count=s.slider_count:get(),
        sliders=(function() local t={}; for _i=1,8 do t[_i]=s.sliders[_i]:get() end; return t end)(),
    } or false
    return d
end

deserialize_entry=function(cfg,d,ci)
    cfg.yaw_switch:set(d.yaw_switch and true or false)
    if d.yaw_switch then
        cfg.ys.mode:set(d.yaw_switch.mode); cfg.ys.left:set(d.yaw_switch.left)
        cfg.ys.right:set(d.yaw_switch.right); cfg.ys.delay:set(d.yaw_switch.delay)
        cfg.ys.jitter:set(d.yaw_switch.jitter)
        if d.yaw_switch.micro~=nil then cfg.ys.micro:set(d.yaw_switch.micro) end
        if d.yaw_switch.ap_on~=nil then cfg.ys.ap_on:set(d.yaw_switch.ap_on) end
        if d.yaw_switch.ap_chance~=nil then cfg.ys.ap_chance:set(d.yaw_switch.ap_chance) end
        if d.yaw_switch.ap_kind~=nil then cfg.ys.ap_kind:set(d.yaw_switch.ap_kind) end
    end
    if d.yaw_mod then cfg.yaw_mod:set(d.yaw_mod.sel); cfg.ym.offset:set(d.yaw_mod.offset); cfg.ym.randomize:set(d.yaw_mod.randomize) end
    cfg.desync:set(d.desync and true or false)
    if d.desync then cfg.ds.left:set(d.desync.left); cfg.ds.right:set(d.desync.right); cfg.ds.opts:set(d.desync.opts) end
    cfg.defensive:set(d.defensive and true or false)
    if d.defensive then
        local dd=d.defensive
        if dd.triggers~=nil then cfg.def.triggers:set(dd.triggers) end
        if dd.force_defensive~=nil then cfg.def.force_defensive:set(dd.force_defensive) end
        if dd.custom_choke~=nil then cfg.def.custom_choke:set(dd.custom_choke) end
        if dd.random_choke~=nil then cfg.def.random_choke:set(dd.random_choke) end
        if dd.choke_1~=nil then cfg.def.choke_1:set(dd.choke_1) end
        if dd.choke_2~=nil then cfg.def.choke_2:set(dd.choke_2) end
        if dd.enabled~=nil then cfg.def.enabled:set(dd.enabled) end
        if dd.pitch~=nil then cfg.def.pitch:set(dd.pitch) end
        if dd.pitch_offset~=nil then cfg.def.pitch_offset:set(dd.pitch_offset) end
        if dd.pitch_1~=nil then cfg.def.pitch_1:set(dd.pitch_1) end
        if dd.pitch_2~=nil then cfg.def.pitch_2:set(dd.pitch_2) end
        if dd.yaw~=nil then cfg.def.yaw:set(dd.yaw) end
        if dd.yaw_offset~=nil then cfg.def.yaw_offset:set(dd.yaw_offset) end
        if dd.yaw_1~=nil then cfg.def.yaw_1:set(dd.yaw_1) end
        if dd.yaw_2~=nil then cfg.def.yaw_2:set(dd.yaw_2) end
        if dd.yaw_rand~=nil then cfg.def.yaw_rand:set(dd.yaw_rand) end
        if dd.yaw_speed~=nil then cfg.def.yaw_speed:set(dd.yaw_speed) end
    end
    cfg.snap:set(d.snap and true or false)
    if d.snap then
        local s=cfg.snap_ui
        if d.snap.no_gren~=nil then s.no_gren:set(d.snap.no_gren) end
        if d.snap.hs_mode~=nil then s.hs_mode:set(d.snap.hs_mode) end
        if d.snap.choke~=nil then s.choke:set(d.snap.choke) end
        if d.snap.rand~=nil then s.rand:set(d.snap.rand) end
        if d.snap.choke_v~=nil then s.choke_v:set(d.snap.choke_v) end
        if d.snap.from_v~=nil then s.from_v:set(d.snap.from_v) end
        if d.snap.to_v~=nil then s.to_v:set(d.snap.to_v) end
        if d.snap.slider_count~=nil then s.slider_count:set(d.snap.slider_count) end
        if d.snap.sliders~=nil then
            for _i=1,8 do if s.sliders[_i] and d.snap.sliders[_i]~=nil then s.sliders[_i]:set(d.snap.sliders[_i]) end end
        end
    end
    reset_ds(ci)
end

local function collect_state()
    local data={}
    for ci=1,#teams*#states do
        local cfg=aa_builder[ci]
        if cfg then local d=serialize_entry(cfg); d.override_global=cfg.override_global:get(); data[tostring(ci)]=d end
    end
    local g=aa_builder[0]; if g then data["global"]=serialize_entry(g) end
    local cp_v=mindmg_cp:get(); local ci_cp=crosshair_cp:get(); local si_c=si_ui.clr:get(); local ng_c=n_ui.glow_cp:get()
    data.visuals={
        aimlog=aimlog_sw:get(),mindmg_ind=mindmg_ind:get(),mindmg_val=mindmg_val:get(),
        mindmg_color=cp_v and cp_v:to_hex() or nil,
        scope_sw=scope_sw:get(),scope_gap=scope_ui.gap:get(),scope_length=scope_ui.len:get(),
        crosshair_ind=crosshair_ind:get(),crosshair_color=ci_cp and ci_cp:to_hex() or nil,
        ci_show_dt=ci_ui.show_dt:get(),ci_show_osaa=ci_ui.show_osaa:get(),
        ci_scope_shift=ci_ui.scope_shift:get(),ci_scope_x=ci_ui.scope_x:get(),ci_scope_y=ci_ui.scope_y:get(),
        ci_glow=ci_ui.glow:get(),ci_glow_color=(ci_ui.glow_cp:get() and ci_ui.glow_cp:get():to_hex()) or nil,
        ci_glow_int=ci_ui.glow_int:get(),keep_trans=keep_trans_sw:get(),
        wm_sw=wm_sw:get(),wm_name=wm_ui.name:get(),wm_pos=wm_ui.pos:get(),
        wm_color=(wm_ui.col:get() and wm_ui.col:get():to_hex()) or nil,
        si_sw=si_sw:get(),si_sel=si_ui.sel:get(),si_color=si_c and si_c:to_hex() or nil,
        notif_speed=n_ui.speed:get(),notif_pos_spd=n_ui.pos_spd:get(),
        notif_limit=n_ui.limit:get(),notif_rounding=n_ui.rounding:get(),notif_duration=n_ui.duration:get(),
        notif_cp_accent=(n_ui.cp_accent:get() and n_ui.cp_accent:get():to_hex()) or nil,
        notif_cp_bg=(n_ui.cp_bg:get() and n_ui.cp_bg:get():to_hex()) or nil,
        notif_cp_text=(n_ui.cp_text:get() and n_ui.cp_text:get():to_hex()) or nil,
        notif_cp_shadow=(n_ui.cp_shadow:get() and n_ui.cp_shadow:get():to_hex()) or nil,
        notif_glow=n_ui.glow_sw:get(),notif_glow_int=n_ui.glow_int:get(),
        notif_glow_color=ng_c and ng_c:to_hex() or nil,
    }
    data.misc={
        clantag_sw=clantag_sw:get(),fastladder=fastladder_sw:get(),
        killsay=killsay_sw:get(),killsay_delay=killsay_delay_sl:get(),killsay_mode=killsay_mode:get(),
        ar_sw=ar_sw:get(),ar_ratio=ar_slider:get(),vm_sw=vm_sw:get(),
        vm_fov=vm_ui.fov:get(),vm_x=vm_ui.x:get(),vm_y=vm_ui.y:get(),vm_z=vm_ui.z:get(),vm_lh=vm_ui.lh:get(),
        avoid_coll=avoid_coll_sw:get(),no_fall=no_fall_sw:get(),edge_qs=edge_qs_sw:get(),
        gren_warn=gren_warn_sw:get(),fd_speed=fd_speed_sw:get(),
        fl_sw=fl_sw:get(),fl_val=fl_val:get(),
    }
    data.ragebot={
        curse_sw=curse_sw:get(),disable_fl_sw=disable_fl_sw:get(),
        air_hc_sw=air_hc_sw:get(),
        air_hc_scout=air_hc_ui.scout:get(),air_hc_revolver=air_hc_ui.revolver:get(),
    }
    data.aa_settings={
        freestanding=set_freestanding_sw:get(),avoid_backstab=avoid_backstab_sw:get(),
        safe_head=safe_head_sw:get(),safe_head_opts=safe_head_opts:get(),
        safe_head_dist=safe_head_dist:get(),safe_head_def=safe_head_def_sw:get(),
        manual_aa=manual_aa_sw:get(),manual_dir=manual_dir:get(),
        manual_static=manual_static_sw:get(),manual_disablers=manual_disablers_sel:get(),
        falling=falling_combo:get(),dir_legs=dir_legs_sel:get(),
        -- Gazolina ABF
        new_abf_sw=new_abf_sw:get(),
        new_abf_states=new_abf_ui.states:get(),
        new_abf_mode=new_abf_ui.mode:get(),
    }
    return data
end

local function apply_state(data)
    if type(data)~="table" then return end
    for ci=1,#teams*#states do
        local d=data[tostring(ci)]; local cfg=aa_builder[ci]
        if d and cfg then
            deserialize_entry(cfg,d,ci)
            if d.override_global~=nil then cfg.override_global:set(d.override_global) end
        end
    end
    if data["global"] then local g=aa_builder[0]; if g then deserialize_entry(g,data["global"],0) end end
    local v=data.visuals or {}
    if v.aimlog~=nil then aimlog_sw:set(v.aimlog) end
    if v.mindmg_ind~=nil then mindmg_ind:set(v.mindmg_ind) end
    if v.mindmg_val~=nil then mindmg_val:set(v.mindmg_val) end
    if v.mindmg_color then mindmg_cp:set(color(v.mindmg_color)) end
    if v.scope_sw~=nil then scope_sw:set(v.scope_sw) end
    if v.scope_gap~=nil then scope_ui.gap:set(v.scope_gap) end
    if v.scope_length~=nil then scope_ui.len:set(v.scope_length) end
    if v.crosshair_ind~=nil then crosshair_ind:set(v.crosshair_ind) end
    if v.crosshair_color then crosshair_cp:set(color(v.crosshair_color)) end
    if v.ci_show_dt~=nil then ci_ui.show_dt:set(v.ci_show_dt) end
    if v.ci_show_osaa~=nil then ci_ui.show_osaa:set(v.ci_show_osaa) end
    if v.ci_scope_shift~=nil then ci_ui.scope_shift:set(v.ci_scope_shift) end
    if v.ci_scope_x~=nil then ci_ui.scope_x:set(v.ci_scope_x) end
    if v.ci_scope_y~=nil then ci_ui.scope_y:set(v.ci_scope_y) end
    if v.ci_glow~=nil then ci_ui.glow:set(v.ci_glow) end
    if v.ci_glow_color then ci_ui.glow_cp:set(color(v.ci_glow_color)) end
    if v.ci_glow_int~=nil then ci_ui.glow_int:set(v.ci_glow_int) end
    if v.keep_trans~=nil then keep_trans_sw:set(v.keep_trans) end
    if v.wm_sw~=nil then wm_sw:set(v.wm_sw) end
    if v.wm_name~=nil then wm_ui.name:set(v.wm_name) end
    if v.wm_pos~=nil then wm_ui.pos:set(v.wm_pos) end
    if v.wm_color then wm_ui.col:set(color(v.wm_color)) end
    if v.si_sw~=nil then si_sw:set(v.si_sw) end
    if v.si_sel~=nil then si_ui.sel:set(v.si_sel) end
    if v.si_color then si_ui.clr:set(color(v.si_color)) end
    if v.notif_speed~=nil then n_ui.speed:set(v.notif_speed) end
    if v.notif_pos_spd~=nil then n_ui.pos_spd:set(v.notif_pos_spd) end
    if v.notif_limit~=nil then n_ui.limit:set(v.notif_limit) end
    if v.notif_rounding~=nil then n_ui.rounding:set(v.notif_rounding) end
    if v.notif_duration~=nil then n_ui.duration:set(v.notif_duration) end
    if v.notif_cp_accent then n_ui.cp_accent:set(color(v.notif_cp_accent)) end
    if v.notif_cp_bg then n_ui.cp_bg:set(color(v.notif_cp_bg)) end
    if v.notif_cp_text then n_ui.cp_text:set(color(v.notif_cp_text)) end
    if v.notif_cp_shadow then n_ui.cp_shadow:set(color(v.notif_cp_shadow)) end
    if v.notif_glow~=nil then n_ui.glow_sw:set(v.notif_glow) end
    if v.notif_glow_int~=nil then n_ui.glow_int:set(v.notif_glow_int) end
    if v.notif_glow_color then n_ui.glow_cp:set(color(v.notif_glow_color)) end
    local m=data.misc or {}
    if m.clantag_sw~=nil then clantag_sw:set(m.clantag_sw) end
    if m.fastladder~=nil then fastladder_sw:set(m.fastladder) end
    if m.killsay~=nil then killsay_sw:set(m.killsay) end
    if m.killsay_delay~=nil then killsay_delay_sl:set(m.killsay_delay) end
    if m.killsay_mode~=nil then killsay_mode:set(m.killsay_mode) end
    if m.ar_sw~=nil then ar_sw:set(m.ar_sw) end
    if m.ar_ratio~=nil then
        local v2=m.ar_ratio
        if type(v2)=="string" then local legacy={["5:4"]=125,["4:3"]=133,["16:9"]=178,["16:10"]=160}; v2=legacy[v2] or 178 end
        ar_slider:set(v2)
    end
    if m.vm_sw~=nil then vm_sw:set(m.vm_sw) end
    if m.vm_fov~=nil then vm_ui.fov:set(m.vm_fov) end
    if m.vm_x~=nil then vm_ui.x:set(m.vm_x) end
    if m.vm_y~=nil then vm_ui.y:set(m.vm_y) end
    if m.vm_z~=nil then vm_ui.z:set(m.vm_z) end
    if m.vm_lh~=nil then vm_ui.lh:set(m.vm_lh) end
    if m.avoid_coll~=nil then avoid_coll_sw:set(m.avoid_coll) end
    if m.no_fall~=nil then no_fall_sw:set(m.no_fall) end
    if m.edge_qs~=nil then edge_qs_sw:set(m.edge_qs) end
    if m.gren_warn~=nil then gren_warn_sw:set(m.gren_warn) end
    if m.fd_speed~=nil then fd_speed_sw:set(m.fd_speed) end
    if m.fl_sw~=nil then fl_sw:set(m.fl_sw) end
    if m.fl_val~=nil then fl_val:set(m.fl_val) end
    local r=data.ragebot or {}
    local curse_val=r.curse_sw~=nil and r.curse_sw or (data.misc and data.misc.curse_sw)
    if curse_val~=nil then curse_sw:set(curse_val) end
    if r.disable_fl_sw~=nil then disable_fl_sw:set(r.disable_fl_sw) end
    if r.air_hc_sw~=nil then air_hc_sw:set(r.air_hc_sw) end
    if r.air_hc_scout~=nil then air_hc_ui.scout:set(r.air_hc_scout) end
    if r.air_hc_revolver~=nil then air_hc_ui.revolver:set(r.air_hc_revolver) end
    local s=data.aa_settings or {}
    if s.freestanding~=nil then set_freestanding_sw:set(s.freestanding) end
    if s.avoid_backstab~=nil then avoid_backstab_sw:set(s.avoid_backstab) end
    if s.safe_head~=nil then safe_head_sw:set(s.safe_head) end
    if s.safe_head_opts~=nil then safe_head_opts:set(s.safe_head_opts) end
    if s.safe_head_dist~=nil then safe_head_dist:set(s.safe_head_dist) end
    if s.safe_head_def~=nil then safe_head_def_sw:set(s.safe_head_def) end
    if s.manual_aa~=nil then manual_aa_sw:set(s.manual_aa) end
    if s.manual_dir~=nil then manual_dir:set(s.manual_dir) end
    if s.manual_static~=nil then manual_static_sw:set(s.manual_static) end
    if s.manual_disablers~=nil then manual_disablers_sel:set(s.manual_disablers) end
    if s.falling~=nil then falling_combo:set(s.falling) end
    if s.dir_legs~=nil then dir_legs_sel:set(s.dir_legs) end
    -- Gazolina ABF restore
    if s.new_abf_sw~=nil then new_abf_sw:set(s.new_abf_sw) end
    if s.new_abf_states~=nil then new_abf_ui.states:set(s.new_abf_states) end
    if s.new_abf_mode~=nil then new_abf_ui.mode:set(s.new_abf_mode) end
    update_visibility()
end

local function save_preset(name)
    local data=collect_state(); local ok,str=pcall(json.stringify,data)
    if not ok then return false,"stringify failed" end
    db[DB_PREFIX..safe_key(name)]=base64.encode(str)
    local list=read_preset_list()
    if not list_contains(list,name) then table.insert(list,name); write_preset_list(list) end
    db[DB_LAST]=name; return true
end
local function load_preset(name)
    local raw=db[DB_PREFIX..safe_key(name)]
    if type(raw)~="string" or raw=="" then return false,"not found" end
    local ok1,str=pcall(base64.decode,raw); if not ok1 then return false,"decode failed" end
    local ok2,data=pcall(json.parse,str); if not ok2 then return false,"parse failed" end
    apply_state(data); db[DB_LAST]=name; return true
end
local function delete_preset(name)
    db[DB_PREFIX..safe_key(name)]=nil
    local list=read_preset_list()
    for i,n in ipairs(list) do if n==name then table.remove(list,i); break end end
    write_preset_list(list); if db[DB_LAST]==name then db[DB_LAST]=nil end
end
local function export_preset(name)
    local raw=db[DB_PREFIX..safe_key(name)]
    if type(raw)~="string" or raw=="" then return nil,"not found" end; return raw
end
local function import_preset(name,encoded)
    if type(encoded)~="string" or encoded=="" then return false,"empty" end
    local ok1,str=pcall(base64.decode,encoded); if not ok1 then return false,"decode failed" end
    local ok2,p=pcall(json.parse,str); if not ok2 or type(p)~="table" then return false,"invalid data" end
    db[DB_PREFIX..safe_key(name)]=encoded
    local list=read_preset_list()
    if not list_contains(list,name) then table.insert(list,name); write_preset_list(list) end
    return true
end
local function migrate_v8()
    local list=read_preset_list(); if #list>0 then return end
    local old=db.builder_cfg_v8; if type(old)~="string" or old=="" then return end
    db[DB_PREFIX..safe_key("Migrated")]=old; table.insert(list,"Migrated"); write_preset_list(list)
    print_raw("\a22FF22FF[Builder]\aFFFFFFFF Migrated v8 config -> preset 'Migrated'.")
end
migrate_v8()

local DEFAULT_PRESET_NAME="Default"
local DEFAULT_PRESET_B64 = table.concat({
    "eyIxIjp7ImFiZiI6ZmFsc2UsImRlZmVuc2l2ZSI6ZmFsc2UsImRlc3luYyI6eyJsZWZ0Ijo2MC4w",
    "LCJvcHRzIjpbXSwicmlnaHQiOjYwLjB9LCJvdmVycmlkZV9nbG9iYWwiOnRydWUsInlhd19tb2Qi",
    "Onsib2Zmc2V0IjowLjAsInJhbmRvbWl6ZSI6MC4wLCJzZWwiOiJEaXNhYmxlZCJ9LCJ5YXdfc3dp",
    "dGNoIjp7ImFwX2NoYW5jZSI6MzAuMCwiYXBfa2luZCI6IlNuYXAgRmxpcCIsImFwX29uIjp0cnVl",
    "LCJkZWxheSI6Ny4wLCJqaXR0ZXIiOjMuMCwibGVmdCI6LTMxLjAsIm1pY3JvIjoxLjAsIm1vZGUi",
    "OiJEZWxheWVkIFN3aXRjaCIsInJpZ2h0IjozMi4wfX0sIjEwIjp7ImFiZiI6ZmFsc2UsImRlZmVu",
    "c2l2ZSI6ZmFsc2UsImRlc3luYyI6eyJsZWZ0Ijo2MC4wLCJvcHRzIjpbXSwicmlnaHQiOjYwLjB9",
    "LCJvdmVycmlkZV9nbG9iYWwiOnRydWUsInlhd19tb2QiOnsib2Zmc2V0IjowLjAsInJhbmRvbWl6",
    "ZSI6MC4wLCJzZWwiOiJEaXNhYmxlZCJ9LCJ5YXdfc3dpdGNoIjp7ImFwX2NoYW5jZSI6MzAuMCwi",
    "YXBfa2luZCI6IlJhbmRvbSBNaXgiLCJhcF9vbiI6dHJ1ZSwiZGVsYXkiOjUuMCwiaml0dGVyIjoy",
    "LjAsImxlZnQiOi0yNy4wLCJtaWNybyI6Mi4wLCJtb2RlIjoiRGVsYXllZCBTd2l0Y2giLCJyaWdo",
    "dCI6MzAuMH19LCIxMSI6eyJhYmYiOmZhbHNlLCJkZWZlbnNpdmUiOmZhbHNlLCJkZXN5bmMiOnsi",
    "bGVmdCI6NjAuMCwib3B0cyI6W10sInJpZ2h0Ijo2MC4wfSwib3ZlcnJpZGVfZ2xvYmFsIjp0cnVl",
    "LCJ5YXdfbW9kIjp7Im9mZnNldCI6MC4wLCJyYW5kb21pemUiOjAuMCwic2VsIjoiRGlzYWJsZWQi",
    "fSwieWF3X3N3aXRjaCI6eyJhcF9jaGFuY2UiOjMwLjAsImFwX2tpbmQiOiJTbmFwIEZsaXAiLCJh",
    "cF9vbiI6dHJ1ZSwiZGVsYXkiOjUuMCwiaml0dGVyIjozLjAsImxlZnQiOi0zNS4wLCJtaWNybyI6",
    "Mi4wLCJtb2RlIjoiRGVsYXllZCBTd2l0Y2giLCJyaWdodCI6MzUuMH19LCIxMiI6eyJhYmYiOmZh",
    "bHNlLCJkZWZlbnNpdmUiOmZhbHNlLCJkZXN5bmMiOnsibGVmdCI6NjAuMCwib3B0cyI6W10sInJp",
    "Z2h0Ijo2MC4wfSwib3ZlcnJpZGVfZ2xvYmFsIjp0cnVlLCJ5YXdfbW9kIjp7Im9mZnNldCI6MC4w",
    "LCJyYW5kb21pemUiOjAuMCwic2VsIjoiRGlzYWJsZWQifSwieWF3X3N3aXRjaCI6eyJhcF9jaGFu",
    "Y2UiOjMwLjAsImFwX2tpbmQiOiJSYW5kb20gTWl4IiwiYXBfb24iOnRydWUsImRlbGF5Ijo3LjAs",
    "ImppdHRlciI6MC4wLCJsZWZ0IjotMzIuMCwibWljcm8iOjMuMCwibW9kZSI6IkRlbGF5ZWQgU3dp",
    "dGNoIiwicmlnaHQiOjM0LjB9fSwiMiI6eyJhYmYiOmZhbHNlLCJkZWZlbnNpdmUiOmZhbHNlLCJk",
    "ZXN5bmMiOnsibGVmdCI6NjAuMCwib3B0cyI6WyJKaXR0ZXIiXSwicmlnaHQiOjYwLjB9LCJvdmVy",
    "cmlkZV9nbG9iYWwiOnRydWUsInlhd19tb2QiOnsib2Zmc2V0IjowLjAsInJhbmRvbWl6ZSI6MC4w",
    "LCJzZWwiOiJEaXNhYmxlZCJ9LCJ5YXdfc3dpdGNoIjp7ImFwX2NoYW5jZSI6MzAuMCwiYXBfa2lu",
    "ZCI6IlNuYXAgRmxpcCIsImFwX29uIjp0cnVlLCJkZWxheSI6Ni4wLCJqaXR0ZXIiOjAuMCwibGVm",
    "dCI6LTMyLjAsIm1pY3JvIjoxLjAsIm1vZGUiOiJEZWxheWVkIFN3aXRjaCIsInJpZ2h0IjozNC4w",
    "fX0sIjMiOnsiYWJmIjpmYWxzZSwiZGVmZW5zaXZlIjpmYWxzZSwiZGVzeW5jIjp7ImxlZnQiOjYw",
    "LjAsIm9wdHMiOlsiSml0dGVyIl0sInJpZ2h0Ijo2MC4wfSwib3ZlcnJpZGVfZ2xvYmFsIjp0cnVl",
    "LCJ5YXdfbW9kIjp7Im9mZnNldCI6MC4wLCJyYW5kb21pemUiOjAuMCwic2VsIjoiRGlzYWJsZWQi",
    "fSwieWF3X3N3aXRjaCI6eyJhcF9jaGFuY2UiOjMwLjAsImFwX2tpbmQiOiJMb25nIEhvbGQiLCJh",
    "cF9vbiI6ZmFsc2UsImRlbGF5IjozLjAsImppdHRlciI6MC4wLCJsZWZ0IjotMjQuMCwibWljcm8i",
    "OjIuMCwibW9kZSI6IkRlbGF5ZWQgU3dpdGNoIiwicmlnaHQiOjMwLjB9fSwiNCI6eyJhYmYiOmZh",
    "bHNlLCJkZWZlbnNpdmUiOmZhbHNlLCJkZXN5bmMiOnsibGVmdCI6NjAuMCwib3B0cyI6W10sInJp",
    "Z2h0Ijo2MC4wfSwib3ZlcnJpZGVfZ2xvYmFsIjp0cnVlLCJ5YXdfbW9kIjp7Im9mZnNldCI6MC4w",
    "LCJyYW5kb21pemUiOjAuMCwic2VsIjoiRGlzYWJsZWQifSwieWF3X3N3aXRjaCI6eyJhcF9jaGFu",
    "Y2UiOjMwLjAsImFwX2tpbmQiOiJTbmFwIEZsaXAiLCJhcF9vbiI6dHJ1ZSwiZGVsYXkiOjYuMCwi",
    "aml0dGVyIjowLjAsImxlZnQiOi0zMC4wLCJtaWNybyI6Mi4wLCJtb2RlIjoiRGVsYXllZCBTd2l0",
    "Y2giLCJyaWdodCI6MzQuMH19LCI1Ijp7ImFiZiI6ZmFsc2UsImRlZmVuc2l2ZSI6ZmFsc2UsImRl",
    "c3luYyI6eyJsZWZ0Ijo2MC4wLCJvcHRzIjpbXSwicmlnaHQiOjYwLjB9LCJvdmVycmlkZV9nbG9i",
    "YWwiOnRydWUsInlhd19tb2QiOnsib2Zmc2V0IjowLjAsInJhbmRvbWl6ZSI6MC4wLCJzZWwiOiJE",
    "aXNhYmxlZCJ9LCJ5YXdfc3dpdGNoIjp7ImFwX2NoYW5jZSI6MzAuMCwiYXBfa2luZCI6IlNuYXAg",
    "RmxpcCIsImFwX29uIjp0cnVlLCJkZWxheSI6Ni4wLCJqaXR0ZXIiOjAuMCwibGVmdCI6LTMxLjAs",
    "Im1pY3JvIjowLjAsIm1vZGUiOiJEZWxheWVkIFN3aXRjaCIsInJpZ2h0IjozMy4wfX0sIjYiOnsi",
    "YWJmIjpmYWxzZSwiZGVmZW5zaXZlIjpmYWxzZSwiZGVzeW5jIjp7ImxlZnQiOjYwLjAsIm9wdHMi",
    "OltdLCJyaWdodCI6NjAuMH0sIm92ZXJyaWRlX2dsb2JhbCI6dHJ1ZSwieWF3X21vZCI6eyJvZmZz",
    "ZXQiOjAuMCwicmFuZG9taXplIjowLjAsInNlbCI6IkRpc2FibGVkIn0sInlhd19zd2l0Y2giOnsi",
    "YXBfY2hhbmNlIjozMC4wLCJhcF9raW5kIjoiU25hcCBGbGlwIiwiYXBfb24iOnRydWUsImRlbGF5",
    "Ijo1LjAsImppdHRlciI6MC4wLCJsZWZ0IjotMzQuMCwibWljcm8iOjIuMCwibW9kZSI6IkRlbGF5",
    "ZWQgU3dpdGNoIiwicmlnaHQiOjQwLjB9fSwiNyI6eyJhYmYiOmZhbHNlLCJkZWZlbnNpdmUiOmZh",
    "bHNlLCJkZXN5bmMiOnsibGVmdCI6NjAuMCwib3B0cyI6W10sInJpZ2h0Ijo2MC4wfSwib3ZlcnJp",
    "ZGVfZ2xvYmFsIjp0cnVlLCJ5YXdfbW9kIjp7Im9mZnNldCI6MC4wLCJyYW5kb21pemUiOjAuMCwi",
    "c2VsIjoiRGlzYWJsZWQifSwieWF3X3N3aXRjaCI6eyJhcF9jaGFuY2UiOjMwLjAsImFwX2tpbmQi",
    "OiJTbmFwIEZsaXAiLCJhcF9vbiI6dHJ1ZSwiZGVsYXkiOjQuMCwiaml0dGVyIjo1LjAsImxlZnQi",
    "Oi0yOS4wLCJtaWNybyI6Mi4wLCJtb2RlIjoiRGVsYXllZCBTd2l0Y2giLCJyaWdodCI6MzIuMH19",
    "LCI4Ijp7ImFiZiI6ZmFsc2UsImRlZmVuc2l2ZSI6ZmFsc2UsImRlc3luYyI6eyJsZWZ0Ijo2MC4w",
    "LCJvcHRzIjpbIkppdHRlciJdLCJyaWdodCI6NjAuMH0sIm92ZXJyaWRlX2dsb2JhbCI6dHJ1ZSwi",
    "eWF3X21vZCI6eyJvZmZzZXQiOjAuMCwicmFuZG9taXplIjowLjAsInNlbCI6IkRpc2FibGVkIn0s",
    "Inlhd19zd2l0Y2giOnsiYXBfY2hhbmNlIjozMC4wLCJhcF9raW5kIjoiU25hcCBGbGlwIiwiYXBf",
    "b24iOnRydWUsImRlbGF5Ijo3LjAsImppdHRlciI6MC4wLCJsZWZ0IjotMzUuMCwibWljcm8iOjEu",
    "MCwibW9kZSI6IkRlbGF5ZWQgU3dpdGNoIiwicmlnaHQiOjM1LjB9fSwiOSI6eyJhYmYiOmZhbHNl",
    "LCJkZWZlbnNpdmUiOmZhbHNlLCJkZXN5bmMiOnsibGVmdCI6NjAuMCwib3B0cyI6WyJKaXR0ZXIi",
    "XSwicmlnaHQiOjYwLjB9LCJvdmVycmlkZV9nbG9iYWwiOnRydWUsInlhd19tb2QiOnsib2Zmc2V0",
    "IjowLjAsInJhbmRvbWl6ZSI6MC4wLCJzZWwiOiJEaXNhYmxlZCJ9LCJ5YXdfc3dpdGNoIjp7ImFw",
    "X2NoYW5jZSI6MzAuMCwiYXBfa2luZCI6IlJhbmRvbSBNaXgiLCJhcF9vbiI6dHJ1ZSwiZGVsYXki",
    "OjEwLjAsImppdHRlciI6Mi4wLCJsZWZ0IjozLjAsIm1pY3JvIjowLjAsIm1vZGUiOiJMJlIgWWF3",
    "IiwicmlnaHQiOi0zLjB9fSwiYWFfc2V0dGluZ3MiOnsiZnJlZXN0YW5kaW5nIjpmYWxzZSwibWFu",
    "dWFsX2FhIjp0cnVlLCJtYW51YWxfZndkIjowLjAsIm1hbnVhbF9sZWZ0Ijo5MC4wLCJtYW51YWxf",
    "cmlnaHQiOi05MC4wfSwiZ2xvYmFsIjp7ImFiZiI6ZmFsc2UsImRlZmVuc2l2ZSI6ZmFsc2UsImRl",
    "c3luYyI6eyJsZWZ0Ijo2MC4wLCJvcHRzIjpbXSwicmlnaHQiOjYwLjB9LCJ5YXdfbW9kIjp7Im9m",
    "ZnNldCI6MC4wLCJyYW5kb21pemUiOjAuMCwic2VsIjoiRGlzYWJsZWQifSwieWF3X3N3aXRjaCI6",
    "eyJhcF9jaGFuY2UiOjMwLjAsImFwX2tpbmQiOiJMb25nIEhvbGQiLCJhcF9vbiI6dHJ1ZSwiZGVs",
    "YXkiOjguMCwiaml0dGVyIjozLjAsImxlZnQiOi0zMC4wLCJtaWNybyI6Mi4wLCJtb2RlIjoiRGVs",
    "YXllZCBTd2l0Y2giLCJyaWdodCI6MzQuMH19LCJtaXNjIjp7ImFyX3JhdGlvIjoiNDozIiwiYXJf",
    "c3ciOnRydWUsImNsYW50YWdfc3ciOnRydWUsImZhc3RsYWRkZXIiOnRydWUsImtpbGxzYXkiOnRy",
    "dWUsImtpbGxzYXlfZGVsYXkiOjIuMCwia2lsbHNheV9tb2RlIjoiQWxsIENoYXQiLCJ2bV9mb3Yi",
    "OjU0LjAsInZtX2xoIjpmYWxzZSwidm1fc3ciOnRydWUsInZtX3giOjAuMCwidm1feSI6LTIwLjAs",
    "InZtX3oiOi0xMC4wfSwicmFnZWJvdCI6eyJjdXJzZV9zdyI6ZmFsc2V9LCJ2aXN1YWxzIjp7ImFp",
    "bWxvZyI6dHJ1ZSwiY2lfZ2xvdyI6dHJ1ZSwiY2lfZ2xvd19jb2xvciI6IkM4RTdGNzYwIiwiY2lf",
    "Z2xvd19pbnQiOjMuMCwiY2lfc2NvcGVfc2hpZnQiOnRydWUsImNpX3Njb3BlX3giOjE2LjAsImNp",
    "X3Njb3BlX3kiOjguMCwiY2lfc2hvd19kdCI6dHJ1ZSwiY2lfc2hvd19vc2FhIjp0cnVlLCJjcm9z",
    "c2hhaXJfY29sb3IiOiJBN0NBRkZDOCIsImNyb3NzaGFpcl9pbmQiOnRydWUsIm1pbmRtZ19jb2xv",
    "ciI6IkZGRkZGRkZGIiwibWluZG1nX2luZCI6dHJ1ZSwibWluZG1nX3ZhbCI6MS4wLCJzY29wZV9n",
    "YXAiOjE1LjAsInNjb3BlX2xlbmd0aCI6MTM1LjAsInNjb3BlX3N3IjpmYWxzZX19"
})
local function inject_default_preset()
    local list=read_preset_list(); if list_contains(list,DEFAULT_PRESET_NAME) then return end
    local ok1,str=pcall(base64.decode,DEFAULT_PRESET_B64); if not ok1 then return end
    local ok2,data=pcall(json.parse,str); if not ok2 or type(data)~="table" then return end
    db[DB_PREFIX..safe_key(DEFAULT_PRESET_NAME)]=DEFAULT_PRESET_B64
    table.insert(list,1,DEFAULT_PRESET_NAME); write_preset_list(list)
    print_raw("\a22FF22FF[Builder]\aFFFFFFFF Default preset injected.")
end
inject_default_preset()

local function refresh_list()
    local list=read_preset_list(); if #list==0 then list={"<no presets>"} end
    pcall(function() preset_list:update(list) end)
end
local function get_target_name()
    local typed=preset_name:get(); if typed and typed~="" then return typed end
    local list=read_preset_list(); if #list==0 then return nil end
    return list[list_idx(preset_list)]
end
local function get_existing_name()
    local list=read_preset_list(); if #list==0 then return nil end
    return list[list_idx(preset_list)]
end

btns.load:set_callback(function()
    local name=get_existing_name(); if not name then notify("Select a preset first."); return end
    local ok,err=load_preset(name); notify(ok and ("Loaded '"..name.."'") or ("Load failed: "..(err or "?")))
end)
btns.save:set_callback(function()
    local name=get_target_name(); if not name or name=="" then notify("Enter a name first."); return end
    local ok,err=save_preset(name)
    if ok then refresh_list(); notify("Saved '"..name.."'") else notify("Save failed: "..(err or "?")) end
end)
btns.delete:set_callback(function()
    local name=get_existing_name(); if not name then notify("Select a preset first."); return end
    delete_preset(name); refresh_list(); notify("Deleted '"..name.."'")
end)
btns.export:set_callback(function()
    local name=get_existing_name(); if not name then notify("Select a preset first."); return end
    local s,err=export_preset(name); if not s then notify("Export failed: "..(err or "?")); return end
    if clipboard and clipboard.set(s) then notify("Copied '"..name.."' to clipboard.")
    else print_raw("\a22FF22FF[Builder]\aFFFFFFFF Export:\n\a888888FF"..s); notify("Clipboard failed — printed to console.") end
end)
btns.import:set_callback(function()
    local name=get_target_name(); if not name or name=="" then notify("Type a name first."); return end
    if not clipboard then notify("Clipboard unavailable."); return end
    local s=clipboard.get(); if not s or s=="" then notify("Clipboard is empty."); return end
    s=s:gsub("%s+","")
    local ok,err=import_preset(name,s)
    if ok then refresh_list(); notify("Imported '"..name.."' from clipboard.")
    else notify("Import failed: "..(err or "?")) end
end)
refresh_list()
if db[DB_LAST] then pcall(load_preset,db[DB_LAST]) end

-- ════════════════════════════════════════════════════════════════
--  RENDER
-- ════════════════════════════════════════════════════════════════
-- crosshair indicator animation state (persists across frames)
local _ci_state = nil

events.render:set(function()
    local lp=entity.get_local_player()
    if #wl_spoofed > 0 then restore_wl_teams() end
    local now = globals.realtime
    if now - wl_last_time >= WL_INTERVAL then wl_last_time = now; rebuild_wl() end
    ui.sidebar(make_sidebar_text(-globals.realtime*0.8),"bug-slash")
    if clantag_sw:get() then apply_ctag(get_ctag_frame()) else apply_ctag(" ") end
    if ar_sw:get() then pcall(function() cvar.r_aspectratio:float(ar_slider:get()*0.01) end)
    else pcall(function() cvar.r_aspectratio:float(0) end) end
    if vm_sw:get() then
        pcall(function()
            cvar.viewmodel_fov:int(vm_ui.fov:get())
            cvar.viewmodel_offset_x:float(vm_ui.x:get()*0.1)
            cvar.viewmodel_offset_y:float(vm_ui.y:get()*0.1)
            cvar.viewmodel_offset_z:float(vm_ui.z:get()*0.1)
            cvar.cl_righthand:int(vm_ui.lh:get() and 0 or 1)
        end)
    else
        pcall(function()
            cvar.viewmodel_fov:int(68); cvar.viewmodel_offset_x:float(0)
            cvar.viewmodel_offset_y:float(0); cvar.viewmodel_offset_z:float(0); cvar.cl_righthand:int(1)
        end)
    end
    local ss=render.screen_size(); local cx=ss.x*0.5; local cy=ss.y*0.5
    if wm_sw:get() then
    local wm_text=wm_ui.name:get()
    if wm_text and wm_text~="" then
        local wm_col=wm_ui.col:get() or color(255,255,255,220)
        local wm_clk=globals.realtime*1.25
        local wm_c0=color(71,71,71,wm_col.a)
        local wm_wavetxt=(function()
            local c1=wm_col; local c0=wm_c0; local s=wm_text
            local buf={}; local len=0
            for _ in s:gmatch(".") do len=len+1 end
            local div=len>1 and 1/(len-1) or 1; local clk=wm_clk
            for ch in s:gmatch(".") do
                local t=clk%2; if t>1 then t=2-t end
                local r=math.max(0,math.min(255,math.floor(c1.r+(c0.r-c1.r)*t)))
                local g=math.max(0,math.min(255,math.floor(c1.g+(c0.g-c1.g)*t)))
                local b=math.max(0,math.min(255,math.floor(c1.b+(c0.b-c1.b)*t)))
                local a=math.max(0,math.min(255,math.floor(c1.a+(c0.a-c1.a)*t)))
                buf[#buf+1]=string.format("\a%02x%02x%02x%02x%s",r,g,b,a,ch)
                clk=clk+div
            end
            return table.concat(buf)
        end)()
        local wm_tsz=render.measure_text(4,"s",wm_text) or vector(60,12)
        local wm_pad=6; local wm_pos=wm_ui.pos:get() or "Top Right"; local wx,wy
        if wm_pos=="Top Right" then wx=ss.x-wm_tsz.x-wm_pad; wy=wm_pad
        elseif wm_pos=="Bottom Center" then wx=ss.x*0.5-wm_tsz.x*0.5; wy=ss.y-wm_tsz.y-wm_pad
        elseif wm_pos=="Left Center" then wx=wm_pad; wy=ss.y*0.5-wm_tsz.y*0.5
        elseif wm_pos=="Right Center" then wx=ss.x-wm_tsz.x-wm_pad; wy=ss.y*0.5-wm_tsz.y*0.5
        else wx=ss.x-wm_tsz.x-wm_pad; wy=wm_pad end
        render.text(4,vector(wx+1,wy+1),color(0,0,0,160),"s",wm_wavetxt)
        render.text(4,vector(wx,wy),wm_col,"s",wm_wavetxt)
        end
    end
    if mindmg_ind:get() then
        local show_val=nil; local binds=ui.get_binds()
        for _,b in ipairs(binds or {}) do
            if b.active and type(b.name)=="string" and b.name:lower():find("damage") then
                local ok,bv=pcall(function() return b.value end)
                if ok and bv~=nil then show_val=math.floor(bv+0.5) end; break
            end
        end
        if show_val~=nil then
            local col=mindmg_cp:get() or color(80,220,80,255)
            render.text(1,vector(cx+15,cy-19),color(0,0,0,200),nil,tostring(show_val))
            render.text(1,vector(cx+14,cy-18),col,nil,tostring(show_val))
        end
    end
    if scope_sw:get() and lp and lp:is_alive() then
        local is_scoped=lp.m_bIsScoped or false
        local target_gap=is_scoped and scope_ui.gap:get() or 0
        local target_length=is_scoped and scope_ui.len:get() or 0
        local function scope_lerp(t,a,b) return a*(1-t)+b*t end
        st.sc_gap=scope_lerp(0.2,st.sc_gap,target_gap)
        st.sc_len=scope_lerp(0.2,st.sc_len,target_length)
        if st.sc_len>0.5 then
            local col=scope_ui.col:get() or color(255,255,255,255)
            local col_a=color(col.r,col.g,col.b,col.a); local col_b=color(col.r,col.g,col.b,0)
            local g=st.sc_gap; local l=st.sc_len
            render.gradient(vector(cx-g,cy),vector(cx-g-l,cy+1),col_a,col_b,col_a,col_b)
            render.gradient(vector(cx+g,cy),vector(cx+g+l,cy+1),col_a,col_b,col_a,col_b)
            render.gradient(vector(cx,cy+g),vector(cx+1,cy+g+l),col_a,col_a,col_b,col_b)
            render.gradient(vector(cx,cy-g),vector(cx+1,cy-g-l),col_a,col_a,col_b,col_b)
        end
    else st.sc_gap=0; st.sc_len=0 end
    if notif_sw:get() and #notif_queue>0 then
        local rt=globals.realtime; local spd_raw=n_ui.speed:get(); local pos_raw=n_ui.pos_spd:get()
        local round=n_ui.rounding:get(); local bg_c=n_ui.cp_bg:get() or color(18,20,26,220)
        local txt_c=n_ui.cp_text:get() or color(220,220,220,255)
        local fade_dur=math.max(0.05,(101-spd_raw)*0.018); local notif_life=n_ui.duration:get()*0.1
        local pos_lf=math.min(0.98,pos_raw*0.012); local MAX_DROP=90
        local base_y=math.floor(ss.y*0.72)
        for i=#notif_queue,1,-1 do
            local slot=#notif_queue-i; local ty=base_y-slot*(NOTIF_H+NOTIF_GAP)
            notif_queue[i].target_y=ty
            if not notif_queue[i].ready then notif_queue[i].cur_y=ty; notif_queue[i].ready=true end
        end
        local dead={}
        for i,n in ipairs(notif_queue) do
            local age=rt-n.spawn_t
            if age<fade_dur then n.alpha=age/fade_dur; n.drop_y=0
            elseif age<notif_life then n.alpha=1.0; n.drop_y=0
            else local t=math.min(1.0,(age-notif_life)/fade_dur); n.alpha=1.0-t; n.drop_y=t*MAX_DROP end
            n.cur_y=n.cur_y+(n.target_y-n.cur_y)*pos_lf
            if age>notif_life+fade_dur then table.insert(dead,i)
            else
                local tsz=render.measure_text(1,nil,n.text); local text_w=tsz and tsz.x or 180; local text_h=tsz and tsz.y or 10
                local icon_sz=NOTIF_H-10; local dyn_w=math.max(180,icon_sz+16+text_w+14)
                local a=math.max(0,math.min(255,math.floor(n.alpha*255+0.5)))
                local bx=math.floor(ss.x*0.5-dyn_w*0.5+0.5); local by=math.floor(n.cur_y+n.drop_y+0.5)
                local bx2=bx+dyn_w; local by2=by+NOTIF_H; local acc=n.accent or color(80,220,100,255)
                local function sc(c,a255) return color(c.r,c.g,c.b,math.max(0,math.min(255,math.floor(a255*c.a/255+0.5)))) end
                local function aa(a255,frac) return math.max(0,math.min(255,math.floor(a255*frac+0.5))) end
                if n_ui.glow_sw:get() then
                    local gc=n_ui.glow_cp:get() or color(100,180,255,200); local gi=n_ui.glow_int:get()
                    for r=gi,1,-1 do
                        local ring_a=math.max(0,math.min(255,math.floor(a*(gc.a/255)*(1-(r-1)/gi)*0.85+0.5)))
                        render.rect_outline(vector(bx-r,by-r),vector(bx2+r,by2+r),color(gc.r,gc.g,gc.b,ring_a),1,round+r)
                    end
                end
                render.rect(vector(bx,by),vector(bx2,by2),sc(bg_c,a),round)
                local icon_x=bx+9; local icon_y=by+5
                local zsz=render.measure_text(notif_icon_font,nil,"Z")
                local ztx=icon_x+math.floor((icon_sz-(zsz and zsz.x or 8))*0.5)
                local zty=icon_y+math.floor((icon_sz-(zsz and zsz.y or 11))*0.5)
                for r=3,1,-1 do
                    local ga=aa(a,(acc.a/255)*(0.025*(4-r))); local gc=color(acc.r,acc.g,acc.b,ga)
                    for _,off in ipairs({{r,0},{-r,0},{0,r},{0,-r},{r,r},{-r,r},{r,-r},{-r,-r}}) do
                        render.text(notif_icon_font,vector(ztx+off[1],zty+off[2]),gc,nil,"Z")
                    end
                end
                render.text(notif_icon_font,vector(ztx+1,zty+1),color(0,0,0,aa(a,0.45)),nil,"Z")
                render.text(notif_icon_font,vector(ztx,zty),color(acc.r,acc.g,acc.b,aa(a,acc.a/255)),nil,"Z")
                local tx=icon_x+icon_sz+7; local ty2=by+math.floor((NOTIF_H-text_h)*0.5)
                render.text(1,vector(tx+1,ty2+1),color(0,0,0,aa(a,0.55)),nil,n.text)
                render.text(1,vector(tx,ty2),sc(txt_c,a),nil,n.text)
            end
        end
        for i=#dead,1,-1 do table.remove(notif_queue,dead[i]) end
    end
    -- ── SENKOTECH CROSSHAIR INDICATORS (ported from gz v1.0) ──────────────────
    if crosshair_ind:get() and lp and lp:is_alive() then
        if not _ci_state then
            _ci_state = {
                alpha=0, align=0,
                st_alpha=0, st_value=0,
                dmg_alpha=0, dmg_value=0,
                dt_alpha=0,  dt_value=0,
                osaa_alpha=0,osaa_value=0,
                fs_alpha=0,  fs_value=0,
                last_state="STAND",
            }
        end
        local S = _ci_state

        -- NL font IDs: 4=Bold (title), 2=Small (labels)
        local FONT_TITLE = 4
        local FONT_LABEL = 2

        local function _lerp(a, b, spd)
            local dt = globals.frametime
            return a + (b - a) * math.min(1, spd * dt)
        end

        local function _wave(s, clock, c1, c0)
            local buf={}; local len=0
            for _ in s:gmatch(".") do len=len+1 end
            local div = len>1 and 1/(len-1) or 1
            for ch in s:gmatch(".") do
                local t=clock%2; if t>1 then t=2-t end
                local r=math.max(0,math.min(255,math.floor(c1.r+(c0.r-c1.r)*t)))
                local g=math.max(0,math.min(255,math.floor(c1.g+(c0.g-c1.g)*t)))
                local b=math.max(0,math.min(255,math.floor(c1.b+(c0.b-c1.b)*t)))
                local a=math.max(0,math.min(255,math.floor(c1.a+(c0.a-c1.a)*t)))
                buf[#buf+1]=string.format("\a%02x%02x%02x%02x%s",r,g,b,a,ch)
                clock=clock+div
            end
            return table.concat(buf)
        end

        local function _fade(s, pct, c1, c0)
            if pct<=0 then return string.format("\a%02x%02x%02x%02x",c0.r,c0.g,c0.b,c0.a)..s end
            if pct>=1 then return string.format("\a%02x%02x%02x%02x",c1.r,c1.g,c1.b,c1.a)..s end
            local buf={}; local len=0
            for _ in s:gmatch(".") do len=len+1 end
            local div=len>1 and 1/(len-1) or 1; local clock=0
            local HP=math.pi/2
            for ch in s:gmatch(".") do
                local t=math.sin(HP*(1-clock*pct)*(1-pct*pct))
                local r=math.max(0,math.min(255,math.floor(c1.r+(c0.r-c1.r)*t)))
                local g=math.max(0,math.min(255,math.floor(c1.g+(c0.g-c1.g)*t)))
                local b=math.max(0,math.min(255,math.floor(c1.b+(c0.b-c1.b)*t)))
                local a=math.max(0,math.min(255,math.floor(c1.a+(c0.a-c1.a)*t)))
                buf[#buf+1]=string.format("\a%02x%02x%02x%02x%s",r,g,b,a,ch)
                clock=clock+div
            end
            return table.concat(buf)
        end

        local vel=math.sqrt(lp.m_vecVelocity.x^2+lp.m_vecVelocity.y^2)
        local flags=lp.m_fFlags
        local on_ground=bit.band(flags,1)~=0
        local ducking=lp.m_flDuckAmount>0.5
        local cur_state
        if not on_ground then cur_state="AIRBORNE"
        elseif ducking    then cur_state="CROUCH"
        elseif vel>10     then cur_state="MOVING"
        else                   cur_state="STAND" end

        local is_scoped = lp.m_bIsScoped or false
        local is_dt  = false; pcall(function() is_dt  = refs.dt_main and (refs.dt_main:get_override() or refs.dt_main:get()) end)
        local is_os  = false; pcall(function() is_os  = refs.hs_main and (refs.hs_main:get_override() or refs.hs_main:get()) end)
        local is_dmg = false
        do local ok,ovr=pcall(ui.find,"Aimbot","Ragebot","Main","Minimum Damage Override")
            if ok and ovr then pcall(function() is_dmg=ovr:get_override() or ovr:get() end) end end
        local is_fs = false
        do local ok,fs=pcall(ui.find,"Aimbot","Anti Aim","Misc","Freestanding")
            if ok and fs then pcall(function() is_fs=fs:get_override() or fs:get() end) end end

        local charge = 1.0; pcall(function() charge=rage.exploit:get() end)
        local shifted = charge >= 1.0

        S.alpha      = _lerp(S.alpha,     is_scoped and 0.75 or 1.0, 20)
        S.align      = _lerp(S.align,     is_scoped and 1.0 or 0.0,  20)
        S.st_alpha   = _lerp(S.st_alpha,  1.0, 20)
        S.st_value   = _lerp(S.st_value,  cur_state==S.last_state and 1 or 0, 15)
        S.dmg_alpha  = _lerp(S.dmg_alpha, is_dmg and 1 or 0, 20)
        S.dmg_value  = _lerp(S.dmg_value, 1.0, 20)
        S.dt_alpha   = _lerp(S.dt_alpha,  is_dt  and 1 or 0, 20)
        S.dt_value   = _lerp(S.dt_value,  shifted and 1 or 0, 20)
        S.osaa_alpha = _lerp(S.osaa_alpha,is_os  and 1 or 0, 20)
        S.osaa_value = _lerp(S.osaa_value,(shifted or S.dt_alpha>0) and 1 or 0, 20)
        S.fs_alpha   = _lerp(S.fs_alpha,  is_fs  and 1 or 0, 20)
        S.fs_value   = _lerp(S.fs_value,  is_fs  and 1 or 0, 20)
        if S.st_value < 0.1 then S.last_state = cur_state end

        if S.alpha > 0.01 then
            local acc = crosshair_cp:get() or color(255,255,255,220)
            local c1  = color(acc.r, acc.g, acc.b, math.max(acc.a, 55))
            local c0  = color(71, 71, 71, c1.a)
            local clk = globals.realtime * 1.25
            local px  = math.floor(cx + math.floor(10 * S.align))
            local py  = math.floor(cy + 18)
            local sha = color(0, 0, 0, math.floor(c1.a * S.alpha * 0.85))

            -- zazahook wave (Bold font, DPI scaled = "s")
            do
                local tsz = render.measure_text(FONT_TITLE, "s", "zazahook") or vector(48, 15)
                local ox  = math.floor((tsz.x * 0.5) * (1 - S.align))
                local wtxt = _wave("zazahook", clk, c1, c0)
                render.text(FONT_TITLE, vector(px-ox+1, py+1), sha, "s", wtxt)
                render.text(FONT_TITLE, vector(px-ox,   py),   color(c1.r,c1.g,c1.b,math.floor(c1.a*S.alpha)), "s", wtxt)
                py = py + tsz.y
            end

            -- state label (Small font)
            if S.st_alpha > 0.01 then
                local ta  = S.alpha * S.st_alpha
                local tsz = render.measure_text(FONT_LABEL, "s", S.last_state) or vector(28, 10)
                local ox  = math.floor((tsz.x * 0.5) * (1 - S.align))
                local txt = _fade(S.last_state, S.st_value, c1, c0)
                render.text(FONT_LABEL, vector(px-ox+1, py+1), color(0,0,0,math.floor(sha.a*ta)), "s", txt)
                render.text(FONT_LABEL, vector(px-ox,   py),   color(c1.r,c1.g,c1.b,math.floor(c1.a*ta)), "s", txt)
                py = py + math.floor(tsz.y * S.st_alpha)
            end

            -- DMG (Small font)
            if S.dmg_alpha > 0.01 then
                local ta  = S.alpha * S.dmg_alpha
                local tsz = render.measure_text(FONT_LABEL, "s", "DMG") or vector(22, 10)
                local ox  = math.floor((tsz.x * 0.5) * (1 - S.align))
                local txt = _fade("DMG", S.dmg_value, c1, c0)
                render.text(FONT_LABEL, vector(px-ox+1, py+1), color(0,0,0,math.floor(sha.a*ta)), "s", txt)
                render.text(FONT_LABEL, vector(px-ox,   py),   color(c1.r,c1.g,c1.b,math.floor(c1.a*ta)), "s", txt)
                py = py + math.floor(tsz.y * S.dmg_alpha)
            end

            -- DT + charge circle (Small font)
            if S.dt_alpha > 0.01 then
                local ta   = S.alpha * S.dt_alpha
                local tsz  = render.measure_text(FONT_LABEL, "s", "DT") or vector(14, 10)
                local rad  = math.max(3, math.floor(tsz.y * 0.33))
                local thk  = math.max(1, math.floor(rad * 0.25))
                local gap  = 4
                local mg   = rad + gap
                local ox   = math.floor(((tsz.x + mg) * 0.5) * (1 - S.align))
                local tx   = px - ox
                local txt  = _fade("DT", S.dt_value, c1, c0)
                render.text(FONT_LABEL, vector(tx+1, py+1), color(0,0,0,math.floor(sha.a*ta)), "s", txt)
                render.text(FONT_LABEL, vector(tx,   py),   color(c1.r,c1.g,c1.b,math.floor(c1.a*ta)), "s", txt)
                local cp   = vector(tx + tsz.x + mg, py + math.floor(tsz.y * 0.5))
                render.circle_outline(cp, color(0,0,0,math.floor(200*ta)),              rad+1, 270, 1,           thk+1)
                render.circle_outline(cp, color(c1.r,c1.g,c1.b,math.floor(c1.a*ta)),   rad,   270, S.dt_value,  thk)
                py = py + math.floor(tsz.y * S.dt_alpha)
            end

            -- OSAA (Small font)
            if S.osaa_alpha > 0.01 then
                local ta  = S.alpha * S.osaa_alpha
                local tsz = render.measure_text(FONT_LABEL, "s", "OSAA") or vector(28, 10)
                local ox  = math.floor((tsz.x * 0.5) * (1 - S.align))
                local txt = _fade("OSAA", S.osaa_value, c1, c0)
                render.text(FONT_LABEL, vector(px-ox+1, py+1), color(0,0,0,math.floor(sha.a*ta)), "s", txt)
                render.text(FONT_LABEL, vector(px-ox,   py),   color(c1.r,c1.g,c1.b,math.floor(c1.a*ta)), "s", txt)
                py = py + math.floor(tsz.y * S.osaa_alpha)
            end

            -- FS (Small font)
            if S.fs_alpha > 0.01 then
                local ta  = S.alpha * S.fs_alpha
                local tsz = render.measure_text(FONT_LABEL, "s", "FS") or vector(14, 10)
                local ox  = math.floor((tsz.x * 0.5) * (1 - S.align))
                local txt = _fade("FS", S.fs_value, c1, c0)
                render.text(FONT_LABEL, vector(px-ox+1, py+1), color(0,0,0,math.floor(sha.a*ta)), "s", txt)
                render.text(FONT_LABEL, vector(px-ox,   py),   color(c1.r,c1.g,c1.b,math.floor(c1.a*ta)), "s", txt)
            end
        end
    end
    if si_sw:get() and lp and lp:is_alive() then
        local ct=globals.curtime; local chosen=si_ui.sel:get() or {}; local active={}
        for _,name in ipairs(chosen) do active[name]=true end
        local ind_c=si_ui.clr:get() or color(255,255,255,255); local entries={}
        local function rget(r)
            if not r then return false end
            local ok,v=pcall(function() return r:get_override() or r:get() end); return ok and v or false
        end
        if active["Aimbot Stats"] then
            local tot=si_st.hits+si_st.misses
            if tot>0 then table.insert(entries,{ind_c,string.format("%d%%",math.floor(si_st.hits/tot*100)),-1,nil}) end
        end
        if active["Double Tap"] and rget(refs.dt_main) then
            local charge=rage.exploit:get()
            table.insert(entries,{charge<1 and color(255,50,50,200) or ind_c,"DT",-1,nil})
        end
        if active["Hide Shots"] and rget(refs.hs_main) then table.insert(entries,{ind_c,"OSAA",-1,nil}) end
        do
            local ok,fd=pcall(ui.find,"Aimbot","Anti Aim","Misc","Fake Duck")
            if active["Fake Duck"] and ok and rget(fd) then
                if bit.band(lp.m_fFlags,bit.lshift(1,6))==0 then table.insert(entries,{ind_c,"DUCK",-1,nil}) end
            end
        end
        do
            local ok,sp=pcall(ui.find,"Aimbot","Ragebot","Safety","Safe Points")
            if active["Safe Point"] and ok and rget(sp)=="Force" then table.insert(entries,{ind_c,"SAFE",-1,nil}) end
        end
        do
            local ok1,ba=pcall(ui.find,"Aimbot","Ragebot","Safety","Body Aim")
            local ok2,bad=pcall(ui.find,"Aimbot","Ragebot","Safety","Body Aim","Disablers")
            if active["Body Aim"] and ok1 and rget(ba)=="Force" then
                local disablers=(ok2 and bad and bad:get()) or {}
                if #disablers==0 then table.insert(entries,{ind_c,"BODY",-1,nil}) end
            end
        end
        if active["Min Damage"] then
            for _,b in ipairs(ui.get_binds() or {}) do
                if b.active and type(b.name)=="string" and b.name:lower():find("damage") then table.insert(entries,{ind_c,"MD",-1,nil}); break end
            end
        end
        if active["Hit Chance"] then
            for _,b in ipairs(ui.get_binds() or {}) do
                if b.active and type(b.name)=="string" and b.name:lower():find("chance") then table.insert(entries,{ind_c,"HC",-1,nil}); break end
            end
        end

        if active["Freestanding"] and rget(refs.freestanding) then
            local has_tgt=false
            pcall(function() has_tgt=(rage.antiaim:get_target(true)~=nil) or (entity.get_threat(true)~=nil) end)
            table.insert(entries,{has_tgt and ind_c or color(255,50,50,200),"FS",-1,nil})
        end
        if active["Defusing"] then
            local bombs=entity.get_entities(129); local bomb=bombs and bombs[1]
            if bomb and bomb.m_hBombDefuser~=nil then
                local pct=1-(10-(bomb.m_flDefuseCountDown-ct))*0.1
                if pct>0 and pct<1 then
                    local dc=(bomb.m_flDefuseCountDown-ct)>(bomb.m_flC4Blow-ct) and color(255,50,50,220) or color(252,243,105,255)
                    table.insert(entries,{dc,"DEF",pct,nil})
                end
            end
        end
        if active["Bomb Info"] then
            if si_st.site~=nil and si_st.planter~=nil then
                local pct2=(ct-si_st.plant_t)/si_st.anim_dur
                if pct2>0 and pct2<1 then table.insert(entries,{color(252,243,105,255),si_st.site,pct2,si_st.bomb_tex}) end
            else
                local planted=entity.get_entities("CPlantedC4"); local pb=planted and planted[1]
                if pb and not pb.m_bBombDefused then
                    local rem=pb.m_flC4Blow-ct
                    if rem>=0 then
                        local sn=pb.m_nBombSite==0 and "A" or "B"
                        table.insert(entries,{color(255,255,255,200),string.format("%s %.1fs",sn,rem),-1,si_st.bomb_tex})
                        local dist=lp:get_eye_position():dist(pb:get_origin())
                        local raw_dmg=500*math.exp(-(dist*dist)/(500*3.5*500*3.5*(2/3)))
                        if (lp.m_ArmorValue or 0)>0 then raw_dmg=raw_dmg*0.5 end
                        raw_dmg=math.max(0,raw_dmg)
                        if raw_dmg>=1 then
                            if raw_dmg<(lp.m_iHealth or 100) then table.insert(entries,{color(252,243,105,255),string.format("-%d HP",math.floor(raw_dmg)),-1,nil})
                            else table.insert(entries,{color(255,50,50,220),"FATAL",-1,nil}) end
                        end
                    end
                end
            end
        end
        if active["Ping"] then
            local net=utils.net_channel(); local fl=si_st.ping_fl and (si_st.ping_fl:get_override() or si_st.ping_fl:get()) or 0
            if net~=nil and fl>0 then
                local lat_cur=net.latency[0]+net.latency[1]; local avg_out=net.avg_latency[0]; local avg_in=net.avg_latency[1]
                local denom=math.min(math.max(avg_in-fl*-0.001+avg_out,0.001),0.2)
                local ratio=math.max(0,math.min(1,lat_cur/denom)); local ping_col
                if ratio>=0.5 then ping_col=color(213,197,84,255):lerp(color(145,195,25,255),(ratio-0.5)*2)
                else ping_col=color(250,234,232,255):lerp(color(213,197,84,255),ratio*2) end
                table.insert(entries,{ping_col,"PING",-1,nil})
            end
        end
        if #entries>0 then
            local bg_c=color(7,11,20,45); local border_c=color(25,32,60,60)
            local bx0=30; local by0=ss.y-345; local off=0
            for _,ent2 in ipairs(entries) do
                local ec,etxt,epct,eico=ent2[1],ent2[2],ent2[3],ent2[4]
                local tsz=render.measure_text(si_st.font,nil,etxt) or vector(40,20)
                local iw=eico and 20 or 0; local pw=epct>=0 and 10 or 0; local pad=6
                local p1=vector(bx0-pad,by0+off-pad*0.75); local p2=vector(bx0+iw+tsz.x+pad+pw*2.5,by0+off+tsz.y+pad*0.75)
                render.rect(p1,p2,bg_c,8); render.rect_outline(p1,p2,border_c,0,8)
                if eico then render.texture(eico,vector(bx0,by0+off),vector(0,tsz.y),ec) end
                render.text(si_st.font,vector(bx0+iw,by0+off+1),ec,nil,etxt)
                if epct>=0 then
                    local rcx=bx0+iw+tsz.x+pw*1.65; local rcy=by0+off+tsz.y*0.5
                    render.circle_outline(vector(rcx,rcy),color(0,200),pw,0,1,5)
                    render.circle_outline(vector(rcx,rcy),ec:alpha_modulate(200/255),pw-1,0,epct,3)
                end
                off=off-(tsz.y+17)
            end
        end
    end
    if not lp or not lp:is_alive() then state_lbl:name("\a888888FFNot in game"); return end
    local t=get_team(); local s=get_state()
    local t_col=t==2 and "\a4FC4FFFF" or "\aFFAA44FF"; local t_name=t==2 and "CT" or "T"
    local ci=get_cond_idx(); local slot=aa_builder[ci]
    local using_g=not(slot and slot.override_global and slot.override_global:get())
    local src_tag=using_g and "\a888888FF [global]" or "\a7483c3FF [override]"
    local cs_ui=state_sel:get()
    if cs_ui=="Global" then state_lbl:name("\a888888FFEditing: \a4488FFFFGlobal state")
    else state_lbl:name(t_col..t_name.." \a888888FF|\aFFFFFFFF "..states[s]..src_tag) end
    gw_render_tick()
    if fl_sw:get() and _fl_ref then _fl_ref:override(fl_val:get())
    elseif _fl_ref then _fl_ref:override() end
end)

-- ════════════════════════════════════════════════════════════════
--  MOVEMENT HELPERS
-- ════════════════════════════════════════════════════════════════
do
local _ac_wasd=ui.find("Miscellaneous","Main","Movement","Air Strafe","WASD Strafe")
local _ac_ej=ui.find("Miscellaneous","Main","Movement","Edge Jump")
function avoid_coll_tick(cmd)
    if not avoid_coll_sw:get() then return end
    if _ac_ej:get_override() or _ac_ej:get() then return end
    local lp=entity.get_local_player(); if lp==nil or lp.m_MoveType~=2 then return end
    if bit.band(lp.m_fFlags,1)==1 then return end
    if cmd.in_duck or cmd.in_speed then return end
    local vel=lp.m_vecVelocity; local mins=lp.m_vecMins; local maxs=lp.m_vecMaxs
    local fwd=vector():angles(0,cmd.view_angles.y); local rgt=fwd:vectors(); local fm,sm=0,0
    if cmd.sidemove==0 then fm=450 end
    if _ac_wasd:get() then fm=(cmd.forwardmove==0 and cmd.sidemove==0) and 450 or cmd.forwardmove; sm=cmd.sidemove end
    local wish=vector(fwd.x*fm+rgt.x*sm,fwd.y*fm+rgt.y*sm); wish:normalize()
    local org=lp:get_origin(); local flat=vel:clone(); flat.z=0; local mx=maxs:clone(); mx.z=36; org.z=org.z+20
    local flat_n=flat:normalized(); if flat_n:dot(wish)<=0 then return end
    local tr=utils.trace_hull(org,org+wish*46,mins,mx,lp,33636363); local n=tr.plane.normal
    if tr:did_hit_world() and math.abs(n.z)<0.1 and bit.band(tr.contents,536870912)~=536870912 and not tr.entity:is_breakable() then
        if flat_n:dot(n)<-0.85 then flat_n=wish end
        local side=n:vectors(); if side:dot(flat_n)<0 then side=side*-1 end
        cmd.move_yaw=math.deg(math.atan2(side.y,side.x)); cmd.forwardmove=450; cmd.sidemove=0
    end
end
end

do
local _sv_grav=cvar.sv_gravity
local _nfd_mn=utils.get_vfunc(76,"float*(__thiscall*)(void*)")
local _nfd_mx=utils.get_vfunc(77,"float*(__thiscall*)(void*)")
local function nfd_trace(lp,origin,dist)
    local rn=_nfd_mn(lp[0]); local rx=_nfd_mx(lp[0])
    local mn=vector(rn[0],rn[1],rn[2]); local mx=vector(rx[0],rx[1],54)
    local tr=utils.trace_hull(origin,origin-vector(0,0,dist),mn,mx,lp,1)
    return tr.fraction<1 and not tr.start_solid and not tr.all_solid and tr.plane.normal.z>=0.7,tr
end
local function nfd_will_damage(height,vz)
    local ti=globals.tickinterval; local half=_sv_grav:float()*ti*0.5; local h,v=height,vz
    while h>11 do v=v-half; h=h+ti*v; v=v-half end
    return v<=-580 and h>=9
end
function no_fall_tick(cmd)
    if not no_fall_sw:get() then return end
    local lp=entity.get_local_player(); if lp==nil or lp.m_MoveType~=2 then return end
    if bit.band(lp.m_fFlags,1)==1 then return end
    local org=lp:get_origin(); if bit.band(lp.m_fFlags,2)==0 then org.z=org.z+9 end
    local hit,tr=nfd_trace(lp,org,1000); if not hit then return end
    local h=tr.fraction*1000; local vz=lp.m_vecVelocity.z
    if vz>=0 or h>=11 then if nfd_will_damage(h,vz) then cmd.in_duck=1; cmd.in_jump=0 end
    elseif vz<-580 and h>9 then cmd.in_jump=1; cmd.in_duck=0 end
end
end

do
local _eqs_ej=ui.find("Miscellaneous","Main","Movement","Edge Jump"); local _eqs_active=0
local function eqs_check(cmd,lp,anim)
    if _eqs_ej:get_override() or _eqs_ej:get() then return false end
    if bit.band(lp.m_fFlags,1)==0 or anim.landed_on_ground_this_frame then return false end
    local sy,sfm,ssm=cmd.view_angles.y,cmd.forwardmove,cmd.sidemove
    local sim=lp:simulate_movement(); sim:think()
    if cmd.in_jump and bit.band(sim.flags,1)==0 then return false end
    for _=0,3 do sim:think() end
    local vel_n=sim.velocity:clone(); if vel_n:normalize()==0 then return false end
    cmd.view_angles.y=vel_n:angles().y; cmd.forwardmove=-450; cmd.sidemove=0
    local spd2=sim.velocity:length2dsqr()
    while sim.velocity:length2dsqr()<spd2 do spd2=sim.velocity:length2dsqr(); sim:think() end
    local sim2=lp:simulate_movement(sim.origin,sim.velocity,sim.flags); sim2:think()
    local result=bit.band(sim2.flags,1)==0
    cmd.view_angles.y=sy; cmd.forwardmove=sfm; cmd.sidemove=ssm; return result
end
function edge_qs_tick(cmd)
    if not edge_qs_sw:get() then return end
    local lp=entity.get_local_player(); if lp==nil or lp.m_MoveType~=2 then return end
    local anim=lp:get_anim_state(); if anim==nil then return end
    if eqs_check(cmd,lp,anim) then _eqs_active=1 end
    if _eqs_active>0 then _eqs_active=_eqs_active-1; cmd.block_movement=2 end
end
end

-- ════════════════════════════════════════════════════════════════
--  GRENADE WARNING
-- ════════════════════════════════════════════════════════════════
local _gw={
    font  =render.load_font("Verdana Bold",vector(10,11.6),"a"),
    he    =render.load_image_from_file("materials/panorama/images/icons/equipment/hegrenade.svg"),
    mo    =render.load_image_from_file("materials/panorama/images/icons/equipment/inferno.svg"),
    red   =color("BE0000FF"),black=color("000000D2"),gray=color("323232BE"),white=color("FFFFFFC8"),
    mp_ff =cvar.mp_friendlyfire,preds={},fut=nil,
    vm_t  =ffi.typeof("struct { float m[4][4]; }"),
}
_gw.vm_get=utils.get_vfunc("engine.dll","VEngineClient014",37,"$& (__thiscall*)(void*)",_gw.vm_t)
local function gw_screen_pos(pos)
    local ss=render.screen_size(); local mg=50; local sp=pos:to_screen()
    if sp~=nil then return vector(math.max(mg,math.min(ss.x-mg,sp.x)),math.max(mg,math.min(ss.y-mg,sp.y))) end
    local ok,ca=pcall(render.camera_angles); if not ok then return vector(ss.x*0.5,ss.y*0.5) end
    local to_pos=pos-render.camera_position(); local yaw=math.deg(math.atan2(to_pos.y,to_pos.x))
    local diff=math.normalize_yaw(yaw-ca.y)
    if diff>=0 then return vector(ss.x-mg,ss.y*0.5) else return vector(mg,ss.y*0.5) end
end
local function gw_alpha(dist)
    local MIN_D=50; local MAX_D=700
    if dist<=MIN_D then return 1.0 end; if dist>=MAX_D then return 0.0 end
    return 1.0-(dist-MIN_D)/(MAX_D-MIN_D)
end
local function gw_draw(sp,inner,outer,arc_pct,alpha,icon,label)
    local r=30+alpha*20; local iw=icon and icon.width or 16; local ih=icon and icon.height or 16
    render.circle_gradient(sp,inner,inner:lerp(outer,1),r,0,1)
    render.circle_outline(sp,_gw.white,r-0.5,0,arc_pct,2)
    if icon then render.texture(icon,sp-vector(iw,ih)*0.5-vector(0,11),vector(iw,ih),_gw.white) end
    render.text(_gw.font,sp+vector(0,15),_gw.white,"cs",label)
end

events.bullet_impact:set(function(e)
    local lp = entity.get_local_player()
    if not lp or not lp:is_alive() then return end
    local dist = lp:get_origin():dist(vector(e.x, e.y, e.z))
    if dist < 150 then
        _evaded_shots = _evaded_shots + 1
        evaded_label:name(ui.get_icon("shield-halved").." \a888888FFEvaded Shots, \a4ff641FF"..tostring(_evaded_shots))
    end
end)

events.grenade_warning:set(function(e)
    if not gren_warn_sw:get() then return end
    _gw.preds[e.entity:get_index()]={tick=globals.tickcount,entity=e.entity,type=e.type,damage=e.damage,expire_time=e.expire_time,path=e.path}
    return false
end)
function gw_createmove_tick(cmd)
    if not gren_warn_sw:get() then return end
    local lp=entity.get_local_player(); if lp~=nil then _gw.fut=lp:get_origin() end
end
function gw_render_tick()
    if not gren_warn_sw:get() then return end
    local lp=entity.get_local_player(); if lp==nil then return end
    local tick=globals.tickcount; local ct=globals.curtime; local hp=lp.m_iHealth
    local cam=lp:is_alive() and lp:get_origin() or render.camera_position()
    if not lp:is_alive() then _gw.fut=cam end; local fut=_gw.fut or cam
    for idx,d in pairs(_gw.preds) do
        if math.abs(d.tick-tick)>1 then _gw.preds[idx]=nil
        else
            pcall(function()
                if not d.path or #d.path==0 then return end
                local last=d.path[#d.path]; if not last then return end
                local dist_f=fut:dist(last); local dist_c=cam:dist(last)
                local alpha=gw_alpha(dist_f); if alpha<=0 then return end
                local sp=gw_screen_pos(last); if not sp then return end
                if d.type=="Frag" then
                    local arc=math.max(0,((d.expire_time or (ct+1.5))-ct)/1.5); local dmg=d.damage or 0
                    local frac=math.max(0,math.min(1,dmg/math.min(50,hp)))
                    local outer=frac<0.01 and _gw.black or _gw.gray:lerp(_gw.red,math.max(0,math.min(1,frac*2)))
                    gw_draw(sp,_gw.black,outer,arc,alpha,_gw.he,tostring(dmg))
                elseif d.type=="Molly" then
                    local ft=dist_c/12; local col=ft<=12.5 and _gw.red or _gw.black
                    gw_draw(sp,_gw.black,col,1.0,alpha,_gw.mo,string.format("%d",math.floor(ft)))
                end
            end)
        end
    end
    entity.get_entities("CInferno",false,function(inf)
        pcall(function()
            local lp_local=entity.get_local_player()
            if inf.m_hOwnerEntity~=nil and inf.m_hOwnerEntity==lp_local then return end
            local ok_ff,is_team=pcall(function()
                return inf.m_hOwnerEntity~=nil and not inf.m_hOwnerEntity:is_enemy() and _gw.mp_ff:int()==0
            end)
            if ok_ff and is_team then return end
            local org=inf:get_origin(); local dist=cam:dist(org)
            local alpha=gw_alpha(dist); if alpha<=0 then return end
            local sp=org:to_screen(); if sp==nil then return end
            local mg=50; local ss=render.screen_size()
            sp=vector(math.max(mg,math.min(ss.x-mg,sp.x)),math.max(mg,math.min(ss.y-mg,sp.y)))
            local t0=(inf.m_nFireEffectTickBegin~=nil and (inf.m_nFireEffectTickBegin*globals.tickinterval)) or (ct-0.1)
            local life=math.max(0,(7-math.max(0,ct-t0))/7)
            local ft=dist/12; local col=ft<=12.5 and _gw.red or _gw.black
            gw_draw(sp,_gw.black,col,life,alpha,_gw.mo,string.format("%d",math.floor(ft)))
        end)
    end)
end

-- ════════════════════════════════════════════════════════════════
--  SHUTDOWN
-- ════════════════════════════════════════════════════════════════
events.shutdown:set(function()
    restore_wl_teams()
    pcall(function() cvar.r_aspectratio:float(0) end)
    pcall(function() cvar.viewmodel_fov:int(68); cvar.viewmodel_offset_x:float(0); cvar.viewmodel_offset_y:float(0); cvar.viewmodel_offset_z:float(0); cvar.cl_righthand:int(1) end)
    if refs.fakelag then pcall(function() refs.fakelag:override() end) end
    if refs.leg_movement then pcall(function() refs.leg_movement:override() end) end
    if refs.hitchance then pcall(function() refs.hitchance:override() end) end
    pcall(common.set_clan_tag," ")
    db.gz_evaded = _evaded_shots
end)

print_raw(
    "\a334466FF"..string.rep("─",60).."\n"..
    "\a7483c3FF[zazahook] \a7483c3FFdeveloper loaded  \a888888FFv2\n"..
    "\a6b69ffFF  ADD   \a888888FF│ \aFFFFFFFFwhitelist system so fuq nikkas dont leak\n"..
    "\a6b69ffFF  ADD   \a888888FF│ \aFFFFFFFFBreak LC â Tickbase: Sliders mode\n"..
    "\af2d307FF  FIX   \a888888FF│ \aFFFFFFFFapply_state new_abf restore placed correctly\n"..
    "\a334466FF"..string.rep("─",60))
