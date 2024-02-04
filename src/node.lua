-- um_area_forsale/src/node.lua
-- The Sign Node
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

minetest.register_node("um_area_forsale:for_sale_sign", {
	tiles = {
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"realestate_sign_back.png",
		"realestate_sign.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
	description = S("For Sale Sign"),
	node_box = {
		type = "fixed",
		fixed = {
			{0.4375, -0.5, 0, 0.5, 0.4375, 0.0625}, -- NodeBox1
			{-0.5, 0.375, 0, 0.5, 0.4375, 0.0625}, -- NodeBox2
			{-0.465, -0.2, 0, 0.4, 0.3125, 0.0625}, -- NodeBox3
			{-0.375, 0.3125, 0, -0.3125, 0.375, 0.0625}, -- NodeBox4
			{0.25, 0.3125, 0, 0.3125, 0.4375, 0.0625}, -- NodeBox5
		}
	},
	on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:set_string("infotext", S("Unconfigured for sale sign"))
    end,
	paramtype2="facedir",
	groups = {snappy = 3},
	on_rightclick = function(pos, node, player, itemstack, pointed_thing)
        um_area_forsale.gui:show(player, {
            pos = pos
        })
	end,
    can_dig = function(pos, player)
        if not (player and player:is_player()) then
            return false
        end

        local name = player:get_player_name()
        if minetest.get_player_privs(name).protection_bypass then
            return true
        end

        local meta = minetest.get_meta(pos)
        local meta_owner = meta:get_string("owner")

        if meta_owner == "" or meta_owner == name then
            return true
        end

        minetest.chat_send_player(name, S("This For Sale Sign belongs to @1, you can't remove it.", name))
        return false
    end
})

minetest.register_craft({
	output = "um_area_forsale:for_sale_sign",
	recipe = {
		{"default:stick", "default:stick", "default:stick"},
		{"default:stick", "", "default:sign_wall_wood"},
		{"default:stick", "", ""}
	}
})

if not minetest.get_modpath("realestate") then
    minetest.register_alias("realestate:sign", "um_area_forsale:for_sale_sign")
end