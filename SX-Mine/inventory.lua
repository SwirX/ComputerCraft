local Inventory = {}

function Inventory.getFullness()
    local usedSlots = 0
    for i = 1, 16 do
        if turtle.getItemCount(i) > 0 then
            usedSlots = usedSlots + 1
        end
    end
    return usedSlots / 16
end

function Inventory.getInventoryData()
    local inv = {}
    for i = 1, 16 do
        local detail = turtle.getItemDetail(i)
        if detail then
            table.insert(inv, {
                slot = i,
                name = detail.name,
                count = detail.count
            })
        end
    end
    return inv
end

function Inventory.hasSparePickaxe()
    for i = 1, 16 do
        local detail = turtle.getItemDetail(i)
        if detail and string.find(detail.name, "pickaxe") then
            return i
        end
    end
    return nil
end

function Inventory.equipPickaxe()
    local slot = Inventory.hasSparePickaxe()
    if slot then
        turtle.select(slot)
        if turtle.equipRight() then
            return true
        end
        -- Sometimes it's left, sometimes right.
        if turtle.equipLeft() then
            return true
        end
    end
    return false
end

function Inventory.dropJunk()
    local junkList = { "cobblestone", "dirt", "gravel", "netherrack", "diorite", "granite", "andesite", "tuff",
        "deepslate" }
    for i = 1, 16 do
        local detail = turtle.getItemDetail(i)
        if detail then
            for _, junk in ipairs(junkList) do
                if string.find(detail.name, junk) then
                    turtle.select(i)
                    turtle.drop()
                    break
                end
            end
        end
    end
    turtle.select(1)
end

return Inventory
