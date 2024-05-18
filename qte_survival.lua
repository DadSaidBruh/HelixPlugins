if SERVER then
    util.AddNetworkString("QTESurvivalStart")
    util.AddNetworkString("QTESurvivalEnd")

    local PLUGIN = PLUGIN or {}
    PLUGIN.name = "QTE Survival"
    PLUGIN.author = "DadSaidBruh"
    PLUGIN.description = "When a player's health drops to 0, they can quickly press the button to save them from death once."

    PLUGIN.qtePlayers = {}
    PLUGIN.qteSequence = { IN_RELOAD } -- The button that the player must press. Default - R
    PLUGIN.qteDuration = 5 -- How many seconds does a player have to press a button. Default - 5
    PLUGIN.allowedFaction = "Гражданские" -- The name of the faction for which this system works. Default - Metropolice Force 

    function PLUGIN:StartQTE(player)
        if ix.faction.Get(player:Team()).name ~= self.allowedFaction then return end

        self.qtePlayers[player] = {
            startTime = CurTime(),
            sequenceIndex = 1
        }

        net.Start("QTESurvivalStart")
        net.Send(player)
    end

    function PLUGIN:CheckQTE(player, key)
        local qteData = self.qtePlayers[player]

        if qteData then
            local timeLeft = self.qteDuration - (CurTime() - qteData.startTime)

            if timeLeft <= 0 then
                self:EndQTE(player, false)
            else
                if key == self.qteSequence[qteData.sequenceIndex] then
                    self:EndQTE(player, true)
                end
            end
        end
    end

    function PLUGIN:EndQTE(player, success)
        if success then
            player:SetHealth(10)
            player:ChatPrint("You refused to die!")
            player.hasSurvivedQTE = true  -- Метка о прохождении QTE
        else
			if player:Alive() then
				player:Kill()
				player:ChatPrint("You have accepted death...")
			end
        end

        self.qtePlayers[player] = nil

        net.Start("QTESurvivalEnd")
        net.Send(player)
    end

    function PLUGIN:PlayerHurt(player, attacker, healthRemaining, damageTaken)
        if healthRemaining - damageTaken <= 0 and ix.faction.Get(player:Team()).name == self.allowedFaction and not self.qtePlayers[player] then
            if player.hasSurvivedQTE then
                player:ChatPrint("You had to accept death...")
                player.hasSurvivedQTE = false
            else
                self:StartQTE(player)
                player:SetHealth(1)
            end
            return true
        end
    end

    function PLUGIN:KeyPress(player, key)
        if self.qtePlayers[player] then
            self:CheckQTE(player, key)
        end
    end

    hook.Add("Think", "QTESurvivalThink", function()
        for player, qteData in pairs(PLUGIN.qtePlayers) do
            if CurTime() - qteData.startTime > PLUGIN.qteDuration then
                PLUGIN:EndQTE(player, false)
            end
        end
    end)

else
    surface.CreateFont("QTEBigFont", {
        font = "Trebuchet MS",
        size = 90,
        weight = 700,
        antialias = true,
        shadow = true
    })

    surface.CreateFont("QTESmallFont", {
        font = "Trebuchet MS",
        size = 30,
        weight = 700,
        antialias = true,
        shadow = true
    })

    local PLUGIN = PLUGIN or {}

    net.Receive("QTESurvivalStart", function()
        hook.Add("HUDPaint", "QTEHUDPaint", function()
            local x = ScrW() / 2 + math.sin(CurTime() * 10) * 10
            local y = ScrH() / 2 + math.cos(CurTime() * 10) * 10
            draw.SimpleText("You are dying!", "QTEBigFont", x, y, Color(255, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            draw.SimpleText("Press R to refuse!", "QTESmallFont", x, y + 100, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            surface.SetDrawColor(0, 0, 0, 150)
            surface.DrawRect(0, 0, ScrW(), ScrH())
        end)
    end)

    net.Receive("QTESurvivalEnd", function()
        hook.Remove("HUDPaint", "QTEHUDPaint")
    end)
end