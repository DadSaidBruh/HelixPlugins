local PLUGIN = PLUGIN

PLUGIN.name = "ChatPlus"
PLUGIN.author = "DadSaidBruh"
PLUGIN.desc = "A very simple plugin that adds global RP chat and adverts."

ix.chat.Register("grp", {
	CanSay = function(self, speaker, text)
	end,
	OnChatAdd = function(self, speaker, text)
		chat.AddText(Color(255, 165, 0), "[GRP] ", ix.config.Get("chatColor"), speaker:Name().." "..text)
	end,
	prefix = {"/GRP"}, -- The command that needs to be written to send a message to the global RP chat.
	description = "Globally RP chat",
	noSpaceAfter = true
})

ix.chat.Register("advert", {
	CanSay = function(self, speaker, text)
	end,
	OnChatAdd = function(self, speaker, text)
		chat.AddText(Color(255, 215, 0), "[Advert] ", ix.config.Get("chatColor"), speaker:Name()..": "..text)
	end,
	prefix = {"/advert"}, -- The command that needs to be written to send an advertisement.
	description = "Adverts chat",
	noSpaceAfter = true 
})