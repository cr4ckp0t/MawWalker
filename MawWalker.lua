-------------------------------------------------------------------------------
-- Maw Walker By Crackpot (US, Illidan)
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
---------------------------------------------------------------------------]] --

local MW = LibStub("AceAddon-3.0"):NewAddon("MawWalker", "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("MawWalker", false)

-- local api cache
local C_Map_GetBestMapForUnit = C_Map.GetBestMapForUnit
local floor = math.floor
local GetAddOnMetadata = _G["GetAddOnMetadata"]
local GetFriendshipReputation = _G["GetFriendshipReputation"]
local gsub = string.gsub
local insert = table.insert
local ipairs = ipairs
local pairs = pairs
local lower = string.lower

MW.title = GetAddOnMetadata("MawWalker", "Title")
MW.version = GetAddOnMetadata("MawWalker", "Version")

-- ve'nari is a bit different
local venariId = 2432
local repStandings = {
    [L["dubious"]] = 1,
    [L["apprehensive"]] = 2,
    [L["tentative"]] = 3,
    [L["ambivalent"]] = 4,
    [L["cordial"]] = 5,
    [L["appreciative"]] = 6
}

-- db defaults
local defaults = {
    profile = {
        autoRoute = true,
        coordType = "all",
        debug = false,
        rares = {
            ["adjutant_dekaris"] = true,
            ["apholeias_herald_of_loss"] = true,
            ["borr_geth"] = true,
            ["conjured_death"] = true,
            ["darklord_taraxis"] = true,
            ["dolos"] = true,
            ["eketra"] = true,
            ["ekphoras_herald_of_grief"] = true,
            ["eternas_the_tormentor"] = true,
            ["ikras_the_devourer"] = true,
            ["morguliax"] = true,
            ["nascent_devourer"] = true,
            ["orophea"] = true,
            ["shadeweaver_zeris"] = true,
            ["soulforger_rhovus"] = true,
            ["talaporas_herald_of_pain"] = true,
            ["thanassos"] = true,
            ["yero_the_skittish"] = true
        },
        events = {
            ["agonix"] = true,
            ["cyrixia"] = true,
            ["dath_rezara"] = true,
            ["dartanos"] = true,
            ["drifting_sorrow"] = true,
            ["houndmaster_vasanok"] = true,
            ["malevolent_stygia"] = true,
            ["krala"] = true,
            ["odalrik"] = true,
            ["orrholyn"] = true,
            ["razkazzar"] = true,
            ["sanngror_the_torturer"] = true,
            ["skittering_broodmother"] = true,
            ["sorath_the_sated"] = true,
            ["soulsmith_yol_mattar"] = true,
            ["stygian_incinerator"] = true,
            ["valis_the_cruel"] = true
        }
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
            width = "full"
        },
        space = {
            type = "description",
            order = 2,
            name = "",
            width = "full"
        },
        general = {
            type = "group",
            order = 3,
            name = L["General Options"],
            guiInline = true,
            args = {
                debug = {
                    type = "toggle",
                    order = 1,
                    name = L["Debugging"],
                    desc = L["Enable this for verbose debugging output. This should generally remain off."],
                    get = function(info)
                        return MW.db.profile.debug
                    end,
                    set = function(info, value)
                        MW.db.profile.debug = value
                    end
                },
                autoRoute = {
                    type = "toggle",
                    order = 2,
                    name = L["Automatic Routing"],
                    desc = L[
                        "Automatically add the waypoints to TomTom when you enter The Maw.\n\n|cffff0000You can use the chat command to load the waypoints manually.|r"
                    ],
                    get = function(info)
                        return MW.db.profile.autoRoute
                    end,
                    set = function(info, value)
                        MW.db.profile.autoRoute = value
                        MW:UpdateWaypoints()
                    end
                },
                coordType = {
                    type = "select",
                    order = 3,
                    name = L["Load Coordinate Type"],
                    desc = L["Choose the type of coordinates to load (i.e. All, Events, or Rares)."],
                    values = {
                        ["all"] = L["All Coordinates"],
                        ["events"] = L["Events Only"],
                        ["rares"] = L["Rares Only"],
                        ["relics"] = L["Relics Only"]
                    },
                    disabled = function()
                        return not MW.db.profile.autoRoute
                    end,
                    get = function(info)
                        return MW.db.profile.coordType
                    end,
                    set = function(info, value)
                        MW.db.profile.coordType = value
                        MW:UpdateWaypoints()
                    end
                }
            }
        },
        waypoints = {
            type = "group",
            order = 4,
            name = L["Waypoints"],
            guiInline = true,
            args = {
                rares = {
                    type = "multiselect",
                    order = 1,
                    name = L["Rares"],
                    desc = L["Choose which waypoints for rares will be added to TomTom."],
                    values = function()
                        local rares = MW:LoadRares()
                        local valuesList = {}
                        if not rares or #rares == 0 then
                            return {}
                        else
                            for _, rare in pairs(rares) do
                                valuesList[lower(rare.name:gsub(" ", "_"):gsub(",", ""):gsub("-", "_"))] = rare.name
                            end
                            return valuesList
                        end
                    end,
                    get = function(_, key)
                        return MW.db.profile.rares[key]
                    end,
                    set = function(_, key, value)
                        MW.db.profile.rares[key] = value
                        MW:UpdateWaypoints()
                    end
                },
                events = {
                    type = "multiselect",
                    order = 2,
                    name = L["Events"],
                    desc = L["Choose which waypoints for events will be added to TomTom."],
                    values = function()
                        local events = MW:LoadEvents()
                        local valuesList = {}
                        if not events or #events == 0 then
                            return {}
                        else
                            for _, event in pairs(events) do
                                valuesList[lower(event.name:gsub(" ", "_"):gsub(",", ""):gsub("-", "_"))] = event.name
                            end
                            return valuesList
                        end
                    end,
                    get = function(_, key)
                        return MW.db.profile.events[key]
                    end,
                    set = function(_, key, value)
                        MW.db.profile.events[key] = value
                        MW:UpdateWaypoints()
                    end
                },
                relics = {
                    type = "multiselect",
                    order = 3,
                    name = L["Relics"],
                    desc = L["Choose which waypoints for relics will be added to TomTom."],
                    values = function()
                        local relics = MW:LoadRelics()
                        local valuesList = {}
                        if not relics or #relics == 0 then
                            return {}
                        else
                            for _, relic in pairs(relics) do
                                valuesList[lower(event.name:gsub(" ", "_"):gsub(",", ""):gsub("-", "_"))] = relic.name
                            end
                        end
                    end
                }
            }
        }
    }
}

-- we need tomtom
if not TomTom then
    return
end

local function GetWaypointKey(key)
    return lower(key:gsub(" ", "_"):gsub(",", ""):gsub("-", ""))
end

local function GetConfigStatus(configVar)
    return configVar == true and ("|cff00ff00%s|r"):format(L["ENABLED"]) or ("|cffff0000%s|r"):format(L["DISABLED"])
end

local function ConcatTables(t1, t2)
    for _, v in ipairs(t2) do
        insert(t1, v)
    end
    return t1
end

function MW:ClearWaypoints()
    if self.waypoints == nil or #self.waypoints == 0 then
        return
    end
    for _, point in pairs(self.waypoints) do
        TomTom:RemoveWaypoint(point)
    end
    self.waypoints = {}
    TomTom:ReloadWaypoints()
end

function MW:UpdateWaypoints(coordType)
    local mapId = C_Map_GetBestMapForUnit("player")
    local coordType = (coordType == "" or coordType == nil) and self.db.profile.coordType or coordType

    if not self.db.profile.autoRoute then
        self:ClearWaypoints()
    end

    -- the maw is 1543
    if mapId == 1543 then
        if coordType == "all" then
            local coords = ConcatTables(self.events, self.rares)
            if #coords ~= 0 then
                for _, coord in pairs(coords) do
                    local keyName = GetWaypointKey(coord.name)
                    if self.db.profile.rares[keyName] or self.db.profile.events[keyName] then
                        self.waypoints[#self.waypoints + 1] =
                            TomTom:AddWaypoint(
                            mapId,
                            coord.x / 100,
                            coord.y / 100,
                            {
                                title = coord.name,
                                persistent = false,
                                minimap = true,
                                world = true
                            }
                        )
                    end
                end
            end
        elseif (coordType == "events" or coordType == "rares") then
            local coords = coordType == "events" and self.events or self.rares
            if #coords ~= 0 then
                for _, coord in pairs(coords) do
                    local keyName = GetWaypointKey(coord.name)
                    if self.db.profile.rares[keyName] or self.db.profile.events[keyName] then
                        self.waypoints[#self.waypoints + 1] =
                            TomTom:AddWaypoint(
                            mapId,
                            coord.x / 100,
                            coord.y / 100,
                            {
                                title = coord.name,
                                persistent = false,
                                minimap = true,
                                world = true
                            }
                        )
                    end
                end
            end
        else
            return
        end
    else
        self:ClearWaypoints()
    end
end

function MW:ZoneChanged(event, ...)
    if self.db.profile.autoRoute then
        self:UpdateWaypoints()
    end
end

function MW:HandleChatCommand(args)
    local key, subKey = self:GetArgs(args, 2)
    if key == "auto" then
        self.db.profile.autoRoute = not self.db.profile.autoRoute
        self:UpdateWaypoints()
        self:Print((L["Auto routing has been %s!"]):format(GetConfigStatus(self.db.profile.autoRoute)))
    elseif key == "clear" then
        self:ClearWaypoints()
        self:Print(L["Cleared all waypoints."])
    elseif key == "config" then
        LibStub("AceConfigDialog-3.0"):Open("Maw Walker")
        self:Print(L["Displaying configuration options."])
    elseif key == "count" then
        self:Print((L["You have |cffffff00%d|r active waypoints."]):format(#self.waypoints))
    elseif key == "debug" then
        self.db.profile.debug = not self.db.profile.debug
        self:Print((L["Debugging has been %s!"]):format(GetConfigStatus(self.db.profile.debug)))
    elseif key == "help" or key == "?" or key == nil or key == "" then
        local helpString = "|cffffff00/maw %s|r - %s"
        self:Print((L["%s v%s by |cff9382c9Crackpotx|r"]):format(MW.title, MW.version))
        self:Print(L["|cffffff00/maw|r or |cffffff00/mw|r"])
        self:Print(helpString:format("auto", L["Toggle Automatic Routing"]))
        self:Print(helpString:format("clear", L["Clear All Waypoints"]))
        self:Print(helpString:format("config", L["Open Configuration Page"]))
        self:Print(helpString:format("count", L["Print Number of Waypoints"]))
        self:Print(helpString:format("debug", L["Toggle Addon Debugging"]))
        self:Print(
            (L["|cffffff00/maw load %s|r - %s"]):format(
                L["<rares|events%|relics|keys|all>"],
                L["Manually Load Waypoints"]
            )
        )
        self:Print(helpString:format("reload", L["Reload Automatic Waypoints"]))
        self:Print(helpString:format("rep", L["Print Ve'nari Friendship Status"]))
        self:Print(helpString:format("status", L["Print Current Addon Status"]))
    elseif key == "load" then
        -- if no waypoint type, load them all
        if subKey == nil or subKey == "" then
            subKey = "all"
        end
        if subKey == "all" or subKey == "events" or subKey == "rares" or subKey == "relics" or subKey == "keys" then
            self:ClearWaypoints()
            self:UpdateWaypoints(subKey)
            self:Print((L["Loaded waypoints for %s."]):format(subKey))
        else
            self:Print((L['Unknown waypoint type "%s".']):format(subKey))
        end
    elseif key == "reload" then
        self:ClearWaypoints()
        self:UpdateWaypoints()
        self:Print(L["Reloaded automatic waypoints."])
    elseif key == "rep" or key == "venari" or key == "status" then
        local _, rep, maxRep, name, text, texture, reaction, threshold, nextThreshold =
            GetFriendshipReputation(venariId)
        local hexColor =
            ("%02x%02x%02x"):format(
            FACTION_BAR_COLORS[repStandings[lower(reaction)]].r * 255,
            FACTION_BAR_COLORS[repStandings[lower(reaction)]].g * 255,
            FACTION_BAR_COLORS[repStandings[lower(reaction)]].b * 255
        )

        -- normalize values
        local realValue = rep - threshold
        local realMax = nextThreshold - threshold
        local realPercent = floor((realValue / realMax) * 100)
        self:Print(
            (L["You are |cff%s%d/%d %s (%d%%)|r with |cff1784d1Ve'nari|r."]):format(
                hexColor,
                realValue,
                realMax,
                reaction,
                realPercent
            )
        )
        if key == "status" then
            self:Print((L["Automatic routing is currently %s!"]):format(GetConfigStatus(self.db.profile.autoRoute)))
            self:Print((L["Debugging is currently %s!"]):format(GetConfigStatus(self.db.profile.debug)))
            self:Print((L["There are %d waypoints loaded."]):format(#self.waypoints))
        end
    end
end

function MW:PLAYER_ENTERING_WORLD(event, ...)
    self.waypoints = {}
    if self.db.profile.autoRoute then
        self:ClearWaypoints()
        self:UpdateWaypoints()
    end
end

function MW:OnEnable()
    self:RegisterChatCommand("maw", "HandleChatCommand")
    self:RegisterChatCommand("mw", "HandleChatCommand")

    self:RegisterEvent("ZONE_CHANGED", "ZoneChanged")
    self:RegisterEvent("ZONE_CHANGED_INDOORS", "ZoneChanged")
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "ZoneChanged")
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function MW:OnDisable()
    self:UnregisterChatCommand("maw")
    self:UnregisterChatCommand("mw")

    self:UnregisterEvent("ZONE_CHANGED")
    self:UnregisterEvent("ZONE_CHANGED_INDOORS")
    self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function MW:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("MawWalkerDB", defaults)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("Maw Walker", options)
    self.optionsUi = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Maw Walker", "Maw Walker")

    -- load the events and rares
    self.events = self:LoadEvents()
    self.rares = self:LoadRares()
end

function MW:GenerateOptionsList(listType)
    local optionsList = listType == "rares" and MW:LoadRares() or MW:LoadEvents()
    local defaultsList = {}
    for _, val in pairs(optionsList) do
        defaultsList[val.name.lower().replace(" ", "_").replace(",", "")] = true
    end
    return defaultsList
end

function MW:LoadEvents()
    return {
        {name = "Agonix", x = 21.3, y = 38.8},
        {name = "Cyrixia", x = 28.2, y = 24.8},
        {name = "Dath Rezara", x = 19.2, y = 57.4},
        {name = "Dartanos", x = 26.0, y = 15.0},
        {name = "Drifting Sorrow", x = 33.2, y = 21.2},
        {name = "Houndmaster Vasanok", x = 60.1, y = 64.9},
        {name = "Malevolent Stygia", x = 27.2, y = 18.6},
        {name = "Krala", x = 30.7, y = 68.9},
        {name = "Odalrik", x = 38.4, y = 28.7},
        {name = "Orrholyn", x = 25.6, y = 48.0},
        {name = "Razkazzar", x = 26.8, y = 37.2},
        {name = "Sanngror the Torturer", x = 55.9, y = 67.3},
        {name = "Skittering Broodmother", x = 59.3, y = 80.0},
        {name = "Sorath the Sated", x = 21.8, y = 30.6},
        {name = "Soulsmith Yol-Mattar", x = 36.6, y = 37.2},
        {name = "Stygian Incinerator", x = 36.6, y = 44.4},
        {name = "Valis the Cruel", x = 40.6, y = 59.6}
    }
end

function MW:LoadRares()
    return {
        {name = "Adjutant Dekaris", x = 25.8, y = 31.2},
        {name = "Apholeias, Herald of Loss", x = 19.8, y = 41.6},
        {name = "Borr-Geth", x = 39.6, y = 41.0},
        {name = "Conjured Death", x = 28.6, y = 13.6},
        {name = "Darklord Taraxis", x = 48.6, y = 81.4},
        {name = "Dolos", x = 32.9, y = 65.2},
        {name = "Eketra", x = 23.2, y = 53.0},
        {name = "Ekphoras, Herald of Grief", x = 42.4, y = 21.2},
        {name = "Eternas the Tormentor", x = 27.4, y = 49.4},
        {name = "Ikras the Devourer", x = 32.5, y = 51.8},
        {name = "Morguliax", x = 16.6, y = 50.6},
        {name = "Nascent Devourer", x = 46.2, y = 74.4},
        {name = "Orophea", x = 23.6, y = 21.8},
        {name = "Shadeweaver Zeris", x = 31.0, y = 60.3},
        {name = "Soulforger Rhovus", x = 35.0, y = 42.0},
        {name = "Talaporas, Herald of Pain", x = 28.6, y = 11.6},
        {name = "Thanassos", x = 27.4, y = 71.3},
        {name = "Yero the Skittish", x = 37.6, y = 65.6}
    }
end

function MW:LoadRelics()
    return {
        {name = "Invasive Mawshroom", x = 39.7, y = 30.8},
        {name = "Invasive Mawshroom", x = 39.7, y = 34.9},
        {name = "Invasive Mawshroom", x = 35.6, y = 34.5},
        {name = "Invasive Mawshroom", x = 45.6, y = 34.3},
        {name = "Invasive Mawshroom", x = 53.7, y = 37.9},
        {name = "Invasive Mawshroom", x = 54.2, y = 41.2},
        {name = "Mawsworn Cache", x = 61.2, y = 58.0},
        {name = "Mawsworn Cache", x = 56.4, y = 69.5},
        {name = "Nest of Unusual Materials", x = 63.7, y = 31.5},
        {name = "Nest of Unusual Materials", x = 61.9, y = 43.9},
        {name = "Nest of Unusual Materials", x = 41.0, y = 39.7},
        {name = "Nest of Unusual Materials", x = 42.5, y = 54.8},
        {name = "Nest of Unusual Materials", x = 52.4, y = 72.7},
        {name = "Pile of Bones", x = 37.1, y = 53.7},
        {name = "Pile of Bones", x = 38.28, y = 51.63},
        {name = "Pile of Bones", x = 31.26, y = 60.01},
        {name = "Relic Cache", x = 57.3, y = 34.9},
        {name = "Relic Cache", x = 55.8, y = 37.3},
        {name = "Relic Cache", x = 54.9, y = 50.2},
        {name = "Relic Cache", x = 53.9, y = 76.1}
    }
end
