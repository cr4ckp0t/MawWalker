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

MawWalker = LibStub("AceAddon-3.0"):NewAddon("MawWalker", "AceConsole-3.0")
MawWalker.L = LibStub("AceLocale-3.0"):GetLocale("MawWalker", false)

-- local api cache
local GetAddOnMetadata = _G["GetAddOnMetadata"]

MawWalker.title = GetAddOnMetadata("MawWalker", "Title")
MawWalker.version = GetAddOnMetadata("MawWalker", "Version")

-- we need tomtom
if not TomTom then return end

function MawWalker:HandleChatCommand(args)

end

function MawWalker:OnEnable()
    self:RegisterChatCommand("maw", "HandleChatCommand")
end

function MawWalker:OnDisable()
    self:UnregisterChatCommand("maw")
end

function MawWalker:OnInitialize()
    -- setup tomtom's arrow
    TomTom.profile.arrow.arrival = 5
    TomTom.profile.arrow.enable = true
    TomTom.profile.arrow.setclosest = true
end