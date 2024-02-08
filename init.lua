-- um_area_forsale/init.lua
-- Area Exchange for Unified Money
--[[
    Copyright (C) 2018  Gabriel Pérez-Cerezo <gabriel@gpcf.eu>
    Copyright (C) 2024  1F616EMO

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
]]

um_area_forsale = {}
local MP = minetest.get_modpath("um_area_forsale")

for _, name in ipairs({
    "infotext",
    "area_tx",
    "mail",
    "gui",
    "node",
}) do
    dofile(MP .. "/src/" .. name .. ".lua")
end
