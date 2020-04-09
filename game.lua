local storage = minetest.get_mod_storage()

tower_defense.games = {}
tower_defense.players = {}
tower_defense.high_score = {}

local latest_game = storage:get_int("last_game")
tower_defense.high_score.wave = storage:get_int("high_wave")
tower_defense.high_score.tanks_left = storage:get_int("high_tanks_left")

local function update_high_score(wave, tanks_left)
	if not wave or not tanks_left then
		return false
	end
	if wave > tower_defense.high_score.wave then
		tower_defense.high_score.wave = wave
		storage:set_int("high_wave", wave)
		tower_defense.high_score.tanks_left = tanks_left
		storage:set_int("high_tanks_left", tanks_left)
		return true
	elseif wave == tower_defense.high_score.wave then
		if tower_defense.high_score.tanks_left > tanks_left then
			tower_defense.high_score.wave = wave
			storage:set_int("high_wave", wave)
			tower_defense.high_score.tanks_left = tanks_left
			storage:set_int("high_tanks_left", tanks_left)
			return true
		else
			return false
		end
	else
		return false
	end
end

local function get_base_pos(id)
	local x = ((id/60)-(math.floor(id/60)))*60
	local z = math.floor(id/60)
	x = x*1000-30000
	z = z*1000-30000
	return {x=x,z=z,y=15000}
end

local function generate_game(game_id)
	local midp = tower_defense.games[game_id].base_pos
	local minp = vector.new(midp.x-50,midp.y-10,midp.z-50)
	local maxp = vector.new(midp.x+50,midp.y+50,midp.z+50)
	local vm = VoxelManip()
	local emin, emax = vm:read_from_map(minp,maxp)
	local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
	local data = vm:get_data()
	local c_ystone = minetest.get_content_id("tower_defense:yellow_stone")
	local c_rstone = minetest.get_content_id("tower_defense:red_stone")
	local stones = {c_ystone,c_rstone}
	local c_barrier = minetest.get_content_id("tower_defense:barrier")
	local c_flag = minetest.get_content_id("tower_defense:flag")
	local c_air = minetest.get_content_id("air")
	for z = minp.z,maxp.z do
		for y = minp.y,maxp.y do
			for x = minp.x,maxp.x do
				local vi = area:index(x,y,z)
				if y == midp.y then
					if (x < midp.x+10 and x > midp.x-10) and (z < midp.z+10 and z > midp.z-10) then
						data[vi] = c_ystone
					else
						data[vi] = stones[math.random(1,2)]
					end
				elseif y < midp.y then
					data[vi] = c_ystone
				elseif y == maxp.y or x == minp.x or z == minp.z or x == maxp.x or z == maxp.z then
					data[vi] = c_barrier
				else
					data[vi] = c_air
				end
			end
		end
	end
	for _,flag in ipairs(tower_defense.games[game_id].flags) do
		local vi = area:indexp(vector.add(flag,midp))
		data[vi] = c_flag
	end
	vm:set_data(data)
	vm:write_to_map()
	tower_defense.games[game_id].state = "waiting_for_players"
end

local function game_emerge_generate(_,_,callbacks_remaining, game_id)
	if callbacks_remaining == 0 then
		generate_game(game_id)
	end
end

function tower_defense.new_game(map_type)
	local game = {}
	local id = latest_game+1
	latest_game = id
	game.base_pos = get_base_pos(id)
	storage:set_int("last_game", id)
	if map_type == "random" or map_type == nil then
		game.flags = {}
		game.flags[1] = {x=math.random(-10,10),y=1,z=math.random(-10,10)}
	end
	game.cash = 10000
	game.state = "generating"
	game.timer = 0
	game.players = {}
	game.tanks = 0
	print(dump(game))
	tower_defense.games[id] = game
	minetest.emerge_area(
		vector.new(game.base_pos.x-50,game.base_pos.y-50,game.base_pos.z-50),
		vector.new(game.base_pos.x-50,game.base_pos.y-50,game.base_pos.z-50),
		game_emerge_generate,
		id
	)
	return true, id
end

function tower_defense.join_game(player, game_id)
	local name = player:get_player_name()
	if tower_defense.players[name] and tower_defense.players[name].in_game == false then
		if tower_defense.games[game_id] == nil then
			return false, "invalid game id"
		end
		if tower_defense.games[game_id].state == "generating" then
			return false, "game still generating"
		end
		if tower_defense.games[game_id].state == "waiting_for_players" then
			tower_defense.games[game_id].state = "waiting_for_wave"
			tower_defense.games[game_id].timer = 10
			tower_defense.games[game_id].wave = 1
		end
		tower_defense.players[name].in_game = true
		tower_defense.players[name].game = game_id
		tower_defense.hud.initalize(player)
		tower_defense.games[game_id].players[name] = true
		local inv = player:get_inventory()
		inv:set_size("main_td_backup",8*4)
		inv:set_list("main_td_backup", inv:get_list("main"))
		for i = 1,8*4 do
			inv:set_stack("main",i,ItemStack())
		end
		local form = tower_defense.shop.get_inventory_formspec()
		player:set_inventory_formspec(form)
		player:set_pos(vector.add(tower_defense.games[game_id].base_pos,{x=0,z=0,y=1}))
	else
		return false, "already in game or player does not exist"
	end
end

function tower_defense.leave_game(player)
	local name = player:get_player_name()
	if tower_defense.players[name] and tower_defense.players[name].in_game == true then
		local game_id = tower_defense.players[name].game
		local inv = player:get_inventory()
		inv:set_list("main", inv:get_list("main_td_backup"))
		inv:set_size("main_td_backup", 0)
		tower_defense.hud.remove(player)
		tower_defense.games[game_id].players[name] = nil
		for _, callback in pairs(core.registered_on_respawnplayers) do
			if callback(player) then
				break
			end
		end
		--reset_inventory_formspec(player)
	else
		return false, "not in game"
	end
end

function tower_defense.end_game(id,reason)
	local game = tower_defense.games[id]
	if game == nil then
		return false, "Invalid game id"
	end
	local new_hs = update_high_score(game.wave,tower_defense.get_tanks_in_game(id))
	for name,_ in pairs(game.players) do
		tower_defense.leave_game(minetest.get_player_by_name(name))
		if new_hs then
			minetest.chat_send_player(name,"Congratulations! You have achieved a new High Score!")
		end
	end
	local objects = minetest.get_objects_inside_radius(game.base_pos,150)
	for _,object in ipairs(objects) do
		if object and object:get_luaentity() and (object:get_luaentity()._is_tank or object:get_luaentity().name == "tower_defense:missile") then
			object:remove()
		end
	end
	tower_defense.games[id] = nil
end

local function start_wave(game_id)
	local game = tower_defense.games[game_id]

	local l = {
		0,
		0,
		0,
		0,
		0,
		0,
		0,
		0,
	}

	for _ = 1,game.wave do
		l[1] = l[1] + 3
		if l[1] == 15 then
			l[1] = 6
			l[2] = l[2] + 3
			if l[2] == 15 then
				l[2] = 6
				l[3] = l[3] +3
				if l[3] == 15 then
					l[3] = 6
					l[4] = l[4] + 3
					if l[4] == 15 then
						l[4] = 6
						l[5] = l[5] + 3
						if l[5] == 15 then
							l[5] = 6
							l[6] = l[6] + 3
							if l[6] == 15 then
								l[6] = 6
								l[7] = l[7] + 3
								if l[7] == 15 then
									l[7] = 6
									l[8] = l[8] + 3
								end
							end
						end
					end
				end
			end
		end
	end

	for i = 1,8 do
		for _ = 1,l[i] do
			local axis = math.random(1,4)
			local pos
			if axis == 1 then
				local x = math.random(-45,45)
				local z = math.random(-45,-20)
				pos = {x=x,y=1,z=z}
			elseif axis == 2 then
				local x = math.random(-45,-20)
				local z = math.random(-45,45)
				pos = {x=x,y=1,z=z}
			elseif axis == 3 then
				local x = math.random(-45,45)
				local z = math.random(20,45)
				pos = {x=x,y=1,z=z}
			else
				local x = math.random(20,45)
				local z = math.random(-45,45)
				pos = {x=x,y=1,z=z}
			end
			minetest.add_entity(
				vector.new(game.base_pos.x+pos.x, game.base_pos.y+pos.y, game.base_pos.z+pos.z),
				"tower_defense:tank_lvl_"..tostring(i),
				tostring(game_id)
			)
		end
	end

	tower_defense.games[game_id].state = "wave"
end

function tower_defense.get_tanks_in_game(game_id)
	local base_pos = tower_defense.games[game_id].base_pos
	local objects = minetest.get_objects_inside_radius(base_pos,100)
	local count = 0
	for _,object in ipairs(objects) do
		if object and object:get_luaentity() and object:get_luaentity()._is_tank then
			count = count + 1
		end
	end
	return count
end

minetest.register_on_joinplayer(function(player)
	local name = player:get_player_name()
	tower_defense.players[name] = {in_game = false, game = nil}
end)

local function player_leave(player)
	local name = player:get_player_name()
	if tower_defense.players[name] and tower_defense.players[name].in_game then
		tower_defense.leave_game(player)
	end
	tower_defense.players[name] = nil
end

minetest.register_on_leaveplayer(player_leave)

minetest.register_on_shutdown(function()
	for id,_ in pairs(tower_defense.games) do
		tower_defense.end_game(id)
	end
end)

minetest.register_globalstep(function(dtime)
	for id,game in pairs(tower_defense.games) do
		if game.state == "waiting_for_wave" then
			local timer = game.timer
			game.timer = game.timer - dtime
			if game.timer < 0 then
				game.timer = 1
				start_wave(id)
			end
			if math.floor(timer) ~= math.floor(game.timer) then
				local num_players = 0
				for name,_ in pairs(game.players) do
					num_players = num_players + 1
					local player = minetest.get_player_by_name(name)
					tower_defense.hud.update(player)
				end
				if num_players == 0 then
					tower_defense.end_game(id,"no_players")
				end
			end
		elseif game.state == "wave" then
			game.timer = game.timer - dtime
			if game.timer < 0 then
				game.timer = 1
				game.tanks = tower_defense.get_tanks_in_game(id)
				local flags = 0
				local remove_flags = {}
				for i,flag in pairs(game.flags) do
					local node = minetest.get_node(vector.add(game.base_pos,flag))
					if node.name == "tower_defense:flag" then
						flags = flags+1
					else
						remove_flags[i] = true
					end
				end
				for i = #game.flags,1,-1 do
					if remove_flags[i] then
						table.remove(game.flags,i)
					end
				end
				if flags == 0 then
					tower_defense.end_game(id,"loss")
				end
				if game.tanks == 0 then
					game.wave = game.wave + 1
					game.timer = 20 --240
					game.state = "waiting_for_wave"
				end
				local num_players = 0
				for name,_ in pairs(game.players) do
					num_players = num_players + 1
					local player = minetest.get_player_by_name(name)
					tower_defense.hud.update(player)
				end
				if num_players == 0 then
					tower_defense.end_game(id,"no_players")
				end
			end
		end
	end
end)

minetest.register_chatcommand("new_td_game",{
	privs = {interact = true},
	description = "Create a new tower defense game",
	func = function(name,_)
		local success, id = tower_defense.new_game("random")
		if success then
			minetest.chat_send_player(name, "Game created.  ID: " .. tostring(id))
		end
	end,

})

minetest.register_chatcommand("join_td_game",{
	privs = {interact = true},
	params = "<game id>",
	description = "Join a tower defense game",
	func = function(name,param)
		local player = minetest.get_player_by_name(name)
		return tower_defense.join_game(player,tonumber(param))
	end,
})

minetest.register_chatcommand("leave_td_game",{
	privs = {interact = true},
	description = "Leave your current tower defense game",
	func = function(name,_)
		local player = minetest.get_player_by_name(name)
		return tower_defense.leave_game(player)
	end,
})

minetest.register_chatcommand("end_td_game",{
	privs = {interact = true},
	params = "<game id>",
	description = "End a tower defense game",
	func = function(_,param)
		return tower_defense.end_game(tonumber(param), "force")
	end,
})
