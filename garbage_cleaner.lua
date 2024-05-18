local PLUGIN = PLUGIN

PLUGIN.name = "Garbage cleaner"
PLUGIN.author = "DadSaidBruh"
PLUGIN.desc = "A plugin that removes from the ground items listed in the trash list.."

local junkItems = {
    "Scrap",
    "Empty box",
    "Seed"
	-- List of names of "trash" items that you want the command to remove.
} 

ix.command.Add("ClearJunk", {
    description = "Removes trash from the world.",
    adminOnly = true,
    OnRun = function(self, client)
        local count = 0

        for _, entity in ipairs(ents.GetAll()) do
            if entity:GetClass() == "ix_item" then
                local itemTable = entity:GetItemTable()
                if itemTable and table.HasValue(junkItems, itemTable.name) then
                    entity:Remove()
                    count = count + 1
                end
            end
        end

        if count > 0 then
            client:ChatPrint("Removed " .. count .. " junk item(s).")
        else
            client:ChatPrint("No junk items found.")
        end
    end
})
