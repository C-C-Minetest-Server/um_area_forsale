-- um_area_forsale/src/infotext.lua
-- Get Infotexts
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

local S = minetest.get_translator("um_area_forsale")

um_area_forsale.INFOTEXT_VER = 1

function um_area_forsale.set_infotext(meta, name)
    if not name then
        name = meta:get_string("owner")
    end
    local infotext = S("Area for sale by @1", name) .. "\n" .. S("Right-click for more details")
    meta:set_int("infotext_ver", um_area_forsale.INFOTEXT_VER)
    meta:set_string("infotext", infotext)
end

minetest.register_lbm({
    label = "[um_area_forsale] Upgrade old infotext",
    name = "um_area_forsale:update_infotext",
    nodenames = {
        "um_area_forsale:for_sale_sign",
    },
    action = function(pos, node)
        local meta = minetest.get_meta(pos)
        if meta:get_int("infotext_ver") ~= um_area_forsale.INFOTEXT_VER then
            um_area_forsale.set_infotext(meta)
        end
    end
})