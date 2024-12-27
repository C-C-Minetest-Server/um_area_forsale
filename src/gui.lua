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

local S = core.get_translator("um_area_forsale")
local C = core.colorize
local gui = flow.widgets

local teacher_exists = core.global_exists("teacher") and true or false

local function tab_frame(title, content)
    return gui.VBox {
        min_w = 8,
        gui.HBox {
            gui.Label {
                label = S("For Sale Sign: @1", title),
                expand = true, align_h = "left",
                w = 6,
            },
            teacher_exists and gui.ButtonExit {
                label = "?",
                w = 0.7, h = 0.7,
                on_event = function(e_player)
                    core.after(0, function(name)
                        if core.get_player_by_name(name) then
                            teacher.simple_show(e_player, "um_area_forsale:tutorial_sign")
                        end
                    end, e_player:get_player_name())
                end,
            } or gui.Nil{},
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
            label = description,
            w = 8,
        },
        gui.ButtonExit {
            label = S("Exit"),
            expand = true, align_h = "right",
            w = 4,
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

local function has_modify_rights(name, owner)
    if name == owner then return true end
    if core.check_player_privs(name, areas.adminPrivs) then return true end
    return false
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
        local node = core.get_node(ctx.pos)
        if node.name ~= "um_area_forsale:for_sale_sign" then
            return tab_error("Internal Code Error", "Invalid sign position.")
        end
    end

    local meta = core.get_meta(ctx.pos)
    if meta:get_string("price") == "" or meta:get_string("id") == "" then
        ctx.tab = "setup"
    else
        ctx.tab = ctx.tab or "main"
    end

    local errmsg = ctx.errmsg
    ctx.errmsg = nil

    if ctx.tab == "setup" then
        local owner = meta:get_string("owner")
        if owner ~= "" then
            if not has_modify_rights(name, owner) then
                return tab_error(S("Protection Violation"), S("You are not allowed to setup this sign!"))
            end
        elseif core.is_protected(ctx.pos, name) then
            core.record_protection_violation(ctx.pos, name)
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
            core.check_player_privs(name, areas.adminPrivs) and gui.Field {
                name = "setup_for",
                label = S("Set up for"),
                default = name,
            } or gui.Nil {},
            gui.HBox {
                gui.Field {
                    name = "setup_price",
                    label = S("Price"),
                    expand = true,
                },
                gui.Button {
                    name = "setup_confirm",
                    label = S("Confirm"),
                    on_event = function(e_player, e_ctx)
                        local e_name = e_player:get_player_name()
                        do
                            local node = core.get_node(e_ctx.pos)
                            if node.name ~= "um_area_forsale:for_sale_sign" then
                                e_ctx.tab = "error"
                                e_ctx.title = "Internal Code Error"
                                e_ctx.errmsg = "Invalid sign position."
                                return true
                            end
                        end

                        local e_meta = core.get_meta(e_ctx.pos)
                        local old_owner = e_meta:get_string("owner")
                        if old_owner ~= "" then
                            if not has_modify_rights(e_name, old_owner) then
                                e_ctx.tab = "error"
                                e_ctx.title = S("Protection Violation")
                                e_ctx.errmsg = S("You are not allowed to setup this sign!")
                                return true
                            end
                        elseif core.is_protected(e_ctx.pos, e_name) then
                            core.record_protection_violation(e_ctx.pos, e_name)

                            e_ctx.tab = "error"
                            e_ctx.title = S("Protection Violation")
                            e_ctx.errmsg = S("You are not allowed to setup this sign!")
                            return true
                        end

                        -- From here, name == set_for or name
                        if e_ctx.form.setup_for and e_ctx.form.setup_for ~= e_name then
                            if not core.check_player_privs(e_name, areas.adminPrivs) then
                                e_ctx.errmsg = S("You are not allowed to set up for others.")
                                return true
                            end
                            local set_for = e_ctx.form.setup_for
                            if not core.get_player_by_name(set_for) then
                                e_ctx.errmsg = S("Invalid player name.")
                                return true
                            end
                            e_name = set_for
                        end

                        do -- check price
                            e_ctx.errmsg = S("Invalid price.")

                            if not e_ctx.form.setup_price then
                                return true
                            end

                            local price = tonumber(e_ctx.form.setup_price)
                            if not (price and price >= 0 and price % 1 == 0) then
                                return true
                            end

                            e_ctx.errmsg = nil
                        end

                        -- check IDs
                        local list_areas
                        do
                            e_ctx.errmsg = S("Invalid Area IDs.")
                            if not (e_ctx.form.setup_ids and e_ctx.form.setup_ids ~= "") then
                                return true
                            end
                            local ok
                            ok, list_areas = comma_sep_int(e_ctx.form.setup_ids)
                            if not (ok and #list_areas ~= 0) then
                                return true
                            end
                            e_ctx.errmsg = nil
                        end

                        table.sort(list_areas)

                        do -- check area ownership
                            local ok, msg = um_area_forsale.check_areas_ownership(e_name, list_areas)
                            if not ok then
                                e_ctx.errmsg = S("The following areas are problematic:")
                                for id, issue in pairs(msg) do
                                    e_ctx.errmsg = e_ctx.errmsg .. "\n" ..
                                        id .. ": " .. um_area_forsale.err_translate[issue]
                                end
                                return true
                            end
                        end

                        e_meta:set_string("owner", e_name)
                        e_meta:set_string("id", table.concat(list_areas, ", "))
                        e_meta:set_string("price", e_ctx.form.setup_price)
                        e_meta:set_string("description", e_ctx.form.setup_desc or "")
                        um_area_forsale.set_infotext(e_meta, e_name)

                        e_ctx.tab = "main"
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

        local list_areas
        do
            local ok
            ok, list_areas = comma_sep_int(id)
            if not ok then
                -- This part of codes are unreachable without hacks
                return tab_error("Internal Code Error", "Invalid id field.")
            end
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
                has_modify_rights(name, owner) and gui.Button {
                    label = S("Edit"),
                    on_event = function(_, e_ctx)
                        local pos = e_ctx.pos
                        local e_meta = core.get_meta(pos)

                        e_ctx.form.setup_ids = e_meta:get_string("id")
                        e_ctx.form.setup_desc = e_meta:get_string("description")
                        e_ctx.form.setup_price = e_meta:get_string("price")
                        e_ctx.form.setup_for = e_meta:get_string("owner")

                        e_ctx.tab = "setup"

                        return true
                    end,
                } or gui.Nil {},
                (name ~= owner) and gui.Button {
                    label = S("Confirm"),
                    on_event = function(e_player, e_ctx)
                        local e_name = e_player:get_player_name()

                        e_ctx.tab = "error"
                        e_ctx.title = S("Area Transfer")

                        do
                            local node = core.get_node(e_ctx.pos)
                            if node.name ~= "um_area_forsale:for_sale_sign" then
                                e_ctx.errmsg = S("Sign destructed during the transaction.")
                                return true
                            end
                        end

                        local e_owner = meta:get_string("owner")
                        local e_id = meta:get_string("id")
                        local e_price = meta:get_string("price")

                        e_price = tonumber(e_price)
                        if not (e_price and e_price >= 0 and e_price % 1 == 0) then
                            -- This part of codes are unreachable without hacks
                            e_ctx.tab = "error"
                            e_ctx.title = "Internal Code Error"
                            e_ctx.errmsg = "Invalid price field."
                            return true
                        end

                        local ok, e_list_areas = comma_sep_int(e_id)
                        if not ok then
                            -- This part of codes are unreachable without hacks
                            e_ctx.tab = "error"
                            e_ctx.title = "Internal Code Error"
                            e_ctx.errmsg = "Invalid id field."
                            return true
                        end

                        local status, code, msg = um_area_forsale.do_area_tx(e_owner, e_price, e_list_areas, e_name)
                        if not status then
                            e_ctx.errmsg = um_area_forsale.err_translate[code]
                            if type(msg) == "string" then
                                e_ctx.errmsg = e_ctx.errmsg .. "\n" .. (um_area_forsale.err_translate[msg] or msg)
                            end
                        else
                            local e_description = meta:get_string("description")

                            if e_description == "" then
                                e_description = "N/A"
                            end

                            core.remove_node(e_ctx.pos)
                            core.check_for_falling(e_ctx.pos)
                            e_ctx.errmsg = S("These areas are transferred to you:") .. "\n" ..
                                um_area_forsale.area_ids_stringify(e_list_areas)

                            for _, func in ipairs(um_area_forsale.registered_on_area_tx) do
                                -- original_owner, new_owner, price, pos, list_areas, description
                                func(e_owner, e_name, e_price, e_ctx.pos, e_list_areas, e_description)
                            end
                        end

                        return true
                    end,
                } or gui.Nil {},
            }
        })
    end
end)
