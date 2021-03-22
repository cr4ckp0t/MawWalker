-------------------------------------------------------------------------------
-- Maw Walker By Crackpot (US, Arthas)
-------------------------------------------------------------------------------

--[[---------------------------------------------------------------------------
    MIT License

Copyright (c) 2021 Adam Koch

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
---------------------------------------------------------------------------]]--

local MW = LibStub("AceAddon-3.0"):NewAddon("MawWalker", "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("MawWalker", false)

-- local api cache
local GetAddOnMetadata = _G["GetAddOnMetadata"]

MW.title = GetAddOnMetadata("MawWalker", "Title")
MW.version = GetAddOnMetadata("MawWalker", "Version")

-- db defaults
local defaults = {
    profile = {
        autoRoute = true,
        debug = false,
    }
}

-- options table
local options = {
    name = MW.title,
    handler = MawWalker,
    type = "group",
    args = {
        header = {
            type = "header",
            order = 1,
			name = (L["|cffff7d0a%s:|r %s"]):format(L["Version"], MW.version),
			width = "full",
        },
        space = {
			type = "description",
			order = 2,
			name = "",
			width = "full",
		},
        general = {
            type = "group",
            order = 3,
            name = L["General Options"],
            guiInline = true,
            args = {
                autoRoute = {
                    type = "toggle",
                    order = 1,
                    name = L["Automatic Routing"],
                    desc = L["Automatically add the waypoints to TomTom when you enter The Maw."],
                    get = function(info) return MW.db.profile.autoRoute end,
                    set = function(info, value) MW.db.profile.autoRoute = value end,
                },
                debug = {
                    type = "toggle",
                    order = 2,
                    name = L["Debugging"],
                    desc = L["Enable this for verbose debugging output. This should generally remain off."],
                    get = function(info) return MW.db.profile.debug end,
                    set = function(info, value) MW.db.profile.debug = value end,
                },
            },
        },
    }
}

-- we need tomtom
if not TomTom then return end

function MW:Print(text)
    print(("|cffffff00MawWalker|r |cffffffff%s|r"):format(text))
end

function MW:HandleChatCommand(args)
    local key = self:GetArgs(args, 1)

    if key == "config" then
        LibStub("AceConfigDialog-3.0"):Open("Maw Walker")
        self:Print(L["Displaying configuration options."])
    end
end

function MW:OnEnable()
    self:RegisterChatCommand("maw", "HandleChatCommand")
    self:RegisterChatCommand("mw", "HandleChatCommand")
end

function MW:OnDisable()
    self:UnregisterChatCommand("maw")
    self:UnregisterChatCommand("mw")
end

function MW:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("MawWalkerDB", defaults)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("Maw Walker", options)
    self.optionsUi = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Maw Walker", "Maw Walker")

    -- setup tomtom's arrow
    TomTom.profile.arrow.arrival = 5
    TomTom.profile.arrow.enable = true
    TomTom.profile.arrow.setclosest = true
end