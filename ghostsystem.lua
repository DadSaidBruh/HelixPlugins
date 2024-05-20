local PLUGIN = PLUGIN

PLUGIN.name = "Ghost system"
PLUGIN.author = "DadSaidBruh"
PLUGIN.description = "The plugin temporarily turns the player into a ghost after death."

-- In general terms the plugin works, but there are some problems. 
-- For example, ghosts can push objects and use containers. 
-- I'll fix it soon.

-- Settings
PLUGIN.enabled = true -- Enable/Disable plugin.
PLUGIN.deathDelay = 6 -- Delay between death and the player turning into a ghost. It should be at least a second longer than the time it takes to respawn.
PLUGIN.respawnTime = 120 -- Time until player respawns.
PLUGIN.ghostMessage = "You will be resurrected in %d seconds."

if SERVER then
    util.AddNetworkString("ixSetBlackAndWhiteVision")
    util.AddNetworkString("ixResetVision")
    util.AddNetworkString("ixSetGhostTime")

    function PLUGIN:PlayerDeath(client)
        if not self.enabled then return end
        if IsValid(client) and client:IsPlayer() then
            local character = client:GetCharacter()
            if character then
                timer.Simple(self.deathDelay, function()
                    if IsValid(client) and client:GetCharacter() == character then
                        -- Makes player invisible
                        client:SetRenderMode(RENDERMODE_TRANSALPHA)
                        client:SetColor(Color(255, 255, 255, 0))
                        client:SetNoDraw(true)

                        -- Takes all SWEPs
                        client:StripWeapons()

                        -- Makes player invincible
                        client:GodEnable()

                        -- Makes inventory useless
                        character:SetData("isGhost", true)

                        -- B&W vision
                        net.Start("ixSetBlackAndWhiteVision")
                        net.Send(client)

                        net.Start("ixSetGhostTime")
                        net.WriteFloat(CurTime() + self.respawnTime)
                        net.WriteString(self.ghostMessage)
                        net.Send(client)

                        -- Respawn after some time
                        timer.Simple(self.respawnTime, function()
                            if IsValid(client) and client:GetCharacter() == character then
                                client:Spawn()
                                client:SetColor(Color(255, 255, 255, 255))
                                client:SetNoDraw(false)

                                -- Makes the player mortal
                                client:GodDisable()

                                -- Makes inventory useful again
                                character:SetData("isGhost", false)

                                -- Normal vision
                                net.Start("ixResetVision")
                                net.Send(client)
                            end
                        end)
                    end
                end)
            end
        end
    end

    -- Trying to prevent player from picking up a weapon
    function PLUGIN:PlayerCanPickupWeapon(client, weapon)
        if not self.enabled then return end
        if client:GetNoDraw() then
            return false
        end
    end

    -- Trying to prevent player from using his inventory
    function PLUGIN:CanPlayerInteractItem(client)
        if not self.enabled then return end
        if client:GetCharacter():GetData("isGhost", false) then
            return false
        end
    end
end

if CLIENT then
    local respawnTime = 0
    local ghostMessage = ""

    -- Makes vision black and white. Perhaps overkill, but it works.
    net.Receive("ixSetBlackAndWhiteVision", function()
        hook.Add("RenderScreenspaceEffects", "ixBlackAndWhiteVision", function()
            DrawColorModify({
                ["$pp_colour_addr"] = 0,
                ["$pp_colour_addg"] = 0,
                ["$pp_colour_addb"] = 0,
                ["$pp_colour_brightness"] = 0,
                ["$pp_colour_contrast"] = 1,
                ["$pp_colour_colour"] = 0,
                ["$pp_colour_mulr"] = 0,
                ["$pp_colour_mulg"] = 0,
                ["$pp_colour_mulb"] = 0
            })
        end)
    end)

    net.Receive("ixResetVision", function()
        hook.Remove("RenderScreenspaceEffects", "ixBlackAndWhiteVision")
        hook.Remove("HUDPaint", "ixGhostHUDPaint")
    end)

    net.Receive("ixSetGhostTime", function()
        respawnTime = net.ReadFloat()
        ghostMessage = net.ReadString()
        hook.Add("HUDPaint", "ixGhostHUDPaint", function()
            local timeLeft = math.max(0, respawnTime - CurTime())
            draw.SimpleText(
                string.format(ghostMessage, timeLeft),
                "Trebuchet24",
                ScrW() / 2,
                100,
                Color(255, 0, 0, 255),
                TEXT_ALIGN_CENTER,
                TEXT_ALIGN_TOP
            )
        end)
    end)
end