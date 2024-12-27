-- um_area_forsale/src/area_tx.lua
-- Handle Area Transactions
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

um_area_forsale.err_translate = {
    -- um_area_forsale.check_areas_ownership
    AREA_NOT_FOUND        = S("Area not found."),
    AREA_OWNER_MISMATCH   = S("You are not the owner."),

    -- um_area_forsale.do_area_tx
    -- um_area_forsale.do_area_tranfer
    FROM_PLAYER_NOT_EXIST = S("Owner does not exist."),
    DEST_PLAYER_NOT_EXIST = S("Receiver does not exist."),
    AREA_OWNERSHIP_ERROR  = S("Area ownership check failed."),
    MONEY_TX_FAILED       = S("Failed to transfer money."),
    AREA_TX_FAILED        = S("Failed to transfer area ownership."),

    -- unified_money.transaction
    -- FROM_TO_EQ (inaccessible),
    -- AMOUNT_NEG (inaccessible),
    ACCOUNT_NF            = S("Account not found."),
    FROM_NO_MONEY         = S("Insufficant balance."),
}

function um_area_forsale.check_areas_ownership(name, list_areas)
    -- We check for owner name, not the ability to manage that area.
    -- This is to avoid moderators accidentally selling other's area.

    local failed = false
    local msgs = {}

    for _, area_id in ipairs(list_areas) do
        local area_data = areas.areas[area_id]

        if not area_data then
            failed = true
            msgs[area_id] = "AREA_NOT_FOUND"
        else
            if area_data.owner ~= name then
                failed = true
                msgs[area_id] = "AREA_OWNER_MISMATCH"
            end
        end
    end

    if failed then
        return false, msgs
    end

    return true
end

function um_area_forsale.do_area_tranfer(list_areas, dest)
    if not areas:player_exists(dest) then
        return false, "DEST_PLAYER_NOT_EXIST"
    end

    for _, area_id in ipairs(list_areas) do
        local entry = areas.areas[area_id]
        if entry then
            entry.owner = dest -- luacheck: ignore
        end
    end
    areas:save()

    return true
end

function um_area_forsale.do_area_tx(from, amount, list_areas, dest)
    if not areas:player_exists(from) then
        return false, "FROM_PLAYER_NOT_EXIST"
    end

    if not areas:player_exists(dest) then
        return false, "DEST_PLAYER_NOT_EXIST"
    end

    do
        local status, msg_table = um_area_forsale.check_areas_ownership(from, list_areas)
        if not status then
            return false, "AREA_OWNERSHIP_ERROR", msg_table
        end
    end

    do
        local status, msg = unified_money.transaction(dest, from, amount)
        if not status then
            return false, "MONEY_TX_FAILED", msg
        end
    end

    do
        local status, msg = um_area_forsale.do_area_tranfer(list_areas, dest)
        if not status then
            -- At least attempt to return money
            unified_money.transaction(from, dest, amount)

            return false, "AREA_TX_FAILED", msg
        end
    end

    return true
end

function um_area_forsale.area_ids_stringify(list_areas)
    local rtn = {}

    for _, id in ipairs(list_areas) do
        local data = areas.areas[id]
        rtn[#rtn+1] = id .. ": " .. (data and data.name or "!!NOT FOUND!!")
    end

    return table.concat(rtn, "\n")
end