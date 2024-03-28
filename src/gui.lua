-- um_area_forsale/src/gui.lua
-- GUI of For Sale Signs
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
local C = minetest.colorize
local gui = flow.widgets

local function tab_frame(title, content)
    return gui.VBox {
        gui.HBox {
            gui.Label {
                label = S("For Sale Sign: @1", title),
                expand = true, align_h = "left",
            },
            gui.ButtonExit {
                label = "x",
                w = 0.7, h = 0.7,
            }
        },
        gui.Box { w = 0.05, h = 0.05, color = "grey", padding = 0 },
        content
    }
end

local function tab_error(title, description)
    return tab_frame(title, gui.VBox {
        gui.Label {
            label = description
        },
        gui.ButtonExit {
            label = S("Exit"),
            expand = true, align_h = "right",
        }
    })
end

local function comma_sep_int(str)
    str = string.gsub(str, "%s+", "")
    local rtn = {}
    for word in string.gmatch(str, '([^,]+)') do
        local int = tonumber(word)
        if not (int and int % 1 == 0) then
            return false, "NOT_INT"
        end

        rtn[#rtn + 1] = int
    end
    return true, rtn
end

um_area_forsale.registered_on_area_tx = {}
function um_area_forsale.register_on_area_tx(func)
    -- original_owner, new_owner, price, pos, list_areas, description
    um_area_forsale.registered_on_area_tx[#um_area_forsale.registered_on_area_tx+1] = func
end

um_area_forsale.register_on_area_tx(um_area_forsale.mail_to_owner)

um_area_forsale.gui = flow.make_gui(function(player, ctx)
    if ctx.tab == "error" then
        return tab_error(ctx.title, ctx.errmsg)
    end

    if not ctx.pos then
        -- Do not waste time on translating stuffs not to be shown in normal usage
        return tab_error("Internal Code Error", "Position not given.")
    end

    local name = player:get_player_name()
    do
        local node = minetest.get_node(ctx.pos)
        if node.name ~= "um_area_forsale:for_sale_sign" then
            return tab_error("Internal Code Error", "Invalid sign position.")
        end
    end

    local meta = minetest.get_meta(ctx.pos)
    if meta:get_string("price") == "" or meta:get_string("id") == "" then
        ctx.tab = "setup"
    else
        ctx.tab = ctx.tab or "main"
    end

    local errmsg = ctx.errmsg
    ctx.errmsg = ""

    if ctx.tab == "setup" then
        if minetest.is_protected(ctx.pos, name) then
            minetest.record_protection_violation(ctx.pos, name)
            return tab_error(S("Protection Violation"), S("You are not allowed to setup this sign!"))
        end

        return tab_frame(S("Sign Setup"), gui.VBox {
            min_w = 8,
            errmsg and gui.Label {
                label = C("red", errmsg)
            } or gui.Nil {},
            gui.Field {
                name = "setup_ids",
                label = S("Area IDs, comma-seperated"),
            },
            gui.Field {
                name = "setup_desc",
                label = S("Description"),
            },
            gui.HBox {
                gui.Field {
                    name = "setup_price",
                    label = S("Price"),
                    expand = true,
                },
                gui.Button {
                    name = "setup_confirm",
                    label = S("Confirm"),
                    on_event = function(player, ctx)
                        local name = player:get_player_name()
                        do
                            local node = minetest.get_node(ctx.pos)
                            if node.name ~= "um_area_forsale:for_sale_sign" then
                                ctx.tab = "error"
                                ctx.title = "Internal Code Error"
                                ctx.errmsg = "Invalid sign position."
                                return true
                            end
                        end

                        if minetest.is_protected(ctx.pos, name) then
                            minetest.record_protection_violation(ctx.pos, name)

                            ctx.tab = "error"
                            ctx.title = S("Protection Violation")
                            ctx.errmsg = S("You are not allowed to setup this sign!")
                            return true
                        end

                        do -- check price
                            ctx.errmsg = S("Invalid price.")

                            if not ctx.form.setup_price then
                                return true
                            end

                            local price = tonumber(ctx.form.setup_price)
                            if not (price and price >= 0 and price % 1 == 0) then
                                return true
                            end

                            ctx.errmsg = nil
                        end

                        -- check IDs
                        ctx.errmsg = S("Invalid Area IDs.")
                        if not (ctx.form.setup_ids and ctx.form.setup_ids ~= "") then
                            return true
                        end
                        local ok, list_areas = comma_sep_int(ctx.form.setup_ids)
                        if not (ok and #list_areas ~= 0) then
                            return true
                        end
                        ctx.errmsg = nil

                        table.sort(list_areas)

                        do -- check area ownership
                            local ok, msg = um_area_forsale.check_areas_ownership(name, list_areas)
                            if not ok then
                                ctx.errmsg = S("The following areas are problematic:")
                                for id, issue in pairs(msg) do
                                    ctx.errmsg = ctx.errmsg .. "\n" ..
                                        id .. ": " .. um_area_forsale.err_translate[issue]
                                end
                                return true
                            end
                        end

                        do
                            local meta = minetest.get_meta(ctx.pos)
                            meta:set_string("owner", name)
                            meta:set_string("id", table.concat(list_areas, ", "))
                            meta:set_string("price", ctx.form.setup_price)
                            meta:set_string("description", ctx.form.setup_desc or "")
                            um_area_forsale.set_infotext(meta, name)
                        end

                        ctx.tab = "main"
                        return true
                    end,
                }
            }
        })
    elseif ctx.tab == "main" then
        local owner = meta:get_string("owner")
        local id = meta:get_string("id")
        local price = meta:get_string("price")
        local description = meta:get_string("description")

        if description == "" then
            description = "N/A"
        end

        local ok, list_areas = comma_sep_int(id)
        if not ok then
            -- This part of codes are unreachable without hacks
            return tab_error("Internal Code Error", "Invalid id field.")
        end

        local balance = unified_money.get_balance_safe(name)

        return tab_frame(S("Area Information"), gui.VBox {
            gui.Label {
                label = S("Description: @1", description)
            },
            gui.Label {
                label = S("Area owner: @1", owner)
            },
            gui.Label {
                label = S("Area(s) to be sold:")
            },
            gui.HBox {
                gui.Box { w = 0.05, h = 0.05, color = "grey", visible = false },
                gui.Label {
                    label = um_area_forsale.area_ids_stringify(list_areas),
                }
            },
            gui.Label {
                label = S("Area Price: $@1", price)
            },
            gui.Box { w = 0.05, h = 0.05, color = "grey", padding = 0 },
            gui.HBox {
                gui.Label {
                    label = um_translate_common.balance_show(balance),
                    expand = true, align_h = "left",
                },
                (name ~= owner) and gui.Button {
                    label = S("Confirm"),
                    on_event = function(player, ctx)
                        local name = player:get_player_name()

                        ctx.tab = "error"
                        ctx.title = S("Area Transfer")

                        do
                            local node = minetest.get_node(ctx.pos)
                            if node.name ~= "um_area_forsale:for_sale_sign" then
                                ctx.errmsg = S("Sign destructed during the transaction.")
                                return true
                            end
                        end

                        local owner = meta:get_string("owner")
                        local id = meta:get_string("id")
                        local price = meta:get_string("price")

                        local balance = unified_money.get_balance_safe(name)

                        price = tonumber(price)
                        if not (price and price >= 0 and price % 1 == 0) then
                            -- This part of codes are unreachable without hacks
                            ctx.tab = "error"
                            ctx.title = "Internal Code Error"
                            ctx.errmsg = "Invalid price field."
                            return true
                        end

                        local ok, list_areas = comma_sep_int(id)
                        if not ok then
                            -- This part of codes are unreachable without hacks
                            ctx.tab = "error"
                            ctx.title = "Internal Code Error"
                            ctx.errmsg = "Invalid id field."
                            return true
                        end

                        local status, code, msg = um_area_forsale.do_area_tx(owner, price, list_areas, name)
                        if not status then
                            ctx.errmsg = um_area_forsale.err_translate[code]
                            if type(msg) == "string" then
                                ctx.errmsg = ctx.errmsg .. "\n" .. (um_area_forsale.err_translate[msg] or msg)
                            end
                        else
                            local description = meta:get_string("description")

                            if description == "" then
                                description = "N/A"
                            end

                            minetest.remove_node(ctx.pos)
                            minetest.check_for_falling(ctx.pos)
                            ctx.errmsg = S("These areas are transferred to you:") .. "\n" ..
                                um_area_forsale.area_ids_stringify(list_areas)

                            for _, func in ipairs(um_area_forsale.registered_on_area_tx) do
                                -- original_owner, new_owner, price, pos, list_areas, description
                                func(owner, name, price, ctx.pos, list_areas, description)
                            end
                        end

                        return true
                    end,
                } or gui.Button {
                    label = S("Edit"),
                    on_event = function(player, ctx)
                        local pos = ctx.pos
                        local meta = minetest.get_meta(pos)

                        ctx.form.setup_ids = meta:get_string("id")
                        ctx.form.setup_desc = meta:get_string("description")
                        ctx.form.setup_price = meta:get_string("price")

                        ctx.tab = "setup"

                        return true
                    end,
                }
            }
        })
    end
end)
