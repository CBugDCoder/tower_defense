tower_defense.hud = {}

function tower_defense.hud.initalize(player)
	local name = player:get_player_name()
	if tower_defense.players[name] and tower_defense.players[name].in_game then
		local game_id = tower_defense.players[name].game
		local game = tower_defense.games[game_id]
		local scoreboard = player:hud_add({
			hud_elem_type = "image",
			scale = {x=1,y=1},
			text = "tower_defense_scoreboard.png",
			alignment = {x=-1,y=1},
			offset = {x=-3,y=3},
			position = {x=1,y=0},
		})
		local wave = player:hud_add({
			hud_elem_type = "text",
			scale = {x=100,y=100},
			text = "Wave " .. game.wave .. " Starts in " .. string.format("%.1d:%.2d", math.floor(game.timer/60), game.timer%60),
			alignment = {x=1,y=1},
			position = {x=1,y=0},
			offset = {x=-225,y=10}
		})
		local cash = player:hud_add({
			hud_elem_type = "text",
			scale = {x=100,y=100},
			text = "You have: $" .. game.cash,
			alignment = {x=1,y=1},
			position = {x=1,y=0},
			offset = {x=-225,y=40}
		})

		tower_defense.players[name].hud = {
			scoreboard = scoreboard,
			wave = wave,
			cash = cash,
		}
	end
end

function tower_defense.hud.update(player)
	local name = player:get_player_name()
	if tower_defense.players[name] and tower_defense.players[name].in_game and tower_defense.players[name].hud then
		local game_id = tower_defense.players[name].game
		local game = tower_defense.games[game_id]
		if game.state == "wave" then
			player:hud_change(tower_defense.players[name].hud.wave, "text",
				"Wave " .. game.wave .. ".   Tanks left: " .. game.tanks)
		else
			player:hud_change(tower_defense.players[name].hud.wave, "text",
				"Wave " .. game.wave .. " Starts in " .. string.format("%.1d:%.2d", math.floor(game.timer/60), game.timer%60))
		end
		player:hud_change(tower_defense.players[name].hud.cash, "text", "You have: $" .. game.cash)
	end
end

function tower_defense.hud.remove(player)
	local name = player:get_player_name()
	if tower_defense.players[name] and tower_defense.players[name].hud then
		player:hud_remove(tower_defense.players[name].hud.scoreboard)
		player:hud_remove(tower_defense.players[name].hud.wave)
		player:hud_remove(tower_defense.players[name].hud.cash)
		tower_defense.players[name].hud = nil
	end
end
