-- um_area_forsale/src/teacher.lua
-- Integrate with Teacher tutorial system
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

if not core.global_exists("teacher") then return end

local S = core.get_translator("um_area_forsale")

teacher.register_turorial("um_area_forsale:tutorial_sign", {
    title = S("For Sale Sign"),
    triggers = {
        {
            name = "approach_node",
            nodenames = "um_area_forsale:for_sale_sign",
        },
        {
            name = "obtain_item",
            itemname = "um_area_forsale:for_sale_sign",
        }
    },

    {
        texture = "um_area_forsale_tutorial_1.jpg",
        text = S(
            "For Sale Sign handles land transactions without the owner's presence. " ..
            "To buy land, right-click the corresponding For Sale Sign."),
    },
    {
        texture = "um_area_forsale_tutorial_2.jpg",
        text = S(
            "After right-clicking the sign, you can see the details of the land. " ..
            "Click on the Confirm button to do the transaction.")
    },
    {
        texture = "um_area_forsale_tutorial_3.jpg",
        text =
            S("To set up a For Sale Sign, place it down and right-click it. " ..
                "Fill in the fields with the corresponding information, then click Confirm.") ..
            "\n\n" ..
            S("If you set up a sign, you can modify an existing one " ..
                "using the Edit button in the right-click interface.")
    },
})
