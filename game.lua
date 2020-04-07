local storage = minetest.get_mod_storage()

tower_defense.games = {}
tower_defense.players = {}
tower_defense.high_score = {}

local latest_game = storage:get_int("last_game")
tower_defense.high_score.wave = storage:get_int("high_wave")
tower_defense.high_score.tanks_left = storage:get_int("high_tanks_left")

local function get_base_pos(id)
	local x = ((id/60)-(math.floor(id/60)))*60
	local z = math.floor(id/60)
	x = x*1000-30000
	z = z*1000-30000
	return {x=x,z=z,y=15000}
end

local function generate_game(game_id)
	local midp = tower_defense.games[game_id].base_pos
	local minp = vector.new(midp.x-100,midp.y-20,midp.z-100)
	local maxp = vector.new(midp.x+100,midp.y+60,midp.z+100)
	local vm = VoxelManip()
	local emin, emax = vm:read_from_map(minp,maxp)
	local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
	local data = vm:get_data()
	local c_stone = minetest.get_content_id("tower_defense:stone")
	local c_sand = minetest.get_content_id("tower_defense:sand")
	local c_barrier = minetest.get_content_id("tower_defense:barrier")
	local c_flag = minetest.get_content_id("tower_defense:flag")
	for z = minp.z,maxp.z do
		for y = minp.y,maxp.y do
			for x = minp.x,maxp.x do
				local vi = area:index(x,y,z)
				if y == midp.y then
					data[vi] = c_sand
				elseif y < midp.y then
					data[vi] = c_stone
				elseif y == maxp.y or x == minp.x or z == minp.z or x == maxp.x or z == maxp.z then
					data[vi] = c_barrier
				end
			end
		end
	end
	for _,flag in ipairs(tower_defense.games[game_id].flags) do
		local vi = area:indexp(vector.add(flag,midp))
		data[vi] = c_flag
	end
	for _,spawn in ipairs(tower_defense.games[game_id].spawns) do
		for z = midp.z+spawn.z-2,midp.z+spawn.z+2 do
			for x = midp.x+spawn.x-2,midp.x+spawn.x+2 do
				local vi = area:index(x,midp.y,z)
				data[vi] = c_stone
			end
		end
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
		game.spawns = {}
		for i = 1,math.random(2,5) do
			local axis = math.random(1,4)
			if axis == 1 then
				local x = math.random(-90,90)
				local z = math.random(-90,-50)
				game.spawns[i] = {x=x,y=1,z=z}
			elseif axis == 2 then
				local x = math.random(-90,-50)
				local z = math.random(-90,90)
				game.spawns[i] = {x=x,y=1,z=z}
			elseif axis == 3 then
				local x = math.random(-90,90)
				local z = math.random(50,90)
				game.spawns[i] = {x=x,y=1,z=z}
			else
				local x = math.random(50,90)
				local z = math.random(-90,90)
				game.spawns[i] = {x=x,y=1,z=z}
			end
		end
		game.flags = {}
		game.flags[1] = {x=math.random(-20,20),y=1,z=math.random(-20,20)}
	end
	game.cash = 10000
	game.state = "generating"
	game.timer = 0
	game.players = {}
	game.tanks = 0
	print(dump(game))
	tower_defense.games[id] = game
	minetest.emerge_area(
		vector.new(game.base_pos.x-100,game.base_pos.y-100,game.base_pos.z-100),
		vector.new(game.base_pos.x-100,game.base_pos.y-100,game.base_pos.z-100),
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

function tower_defense.end_game(id)
	local game = tower_defense.games[id]
	for name,_ in pairs(game.players) do
		tower_defense.leave_game(minetest.get_player_by_name(name))
	end
	local pos1 = vector.add(game.base_pos,{x=-100,y=-20,z=-100})
	local pos2 = vector.add(game.base_pos,{x=100,y=60,z=100})
	--minetest.delete_area(pos1, pos2)
	tower_defense.games[id] = nil
end

local function start_wave(game_id)
	local game = tower_defense.games[game_id]
	
	for _,spawn in ipairs(game.spawns) do
		for _ = 1,3 do
			local offset = {x=math.random(-2,2),z=math.random(-2,2)}
			local ent = minetest.add_entity(vector.new(game.base_pos.x+spawn.x+offset.x, game.base_pos.y+spawn.y, game.base_pos.z+spawn.z+offset.z),"tower_defense:tank_lvl_1", tostring(game_id))
		end
	end
	tower_defense.games[game_id].state = "wave"
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
		if game.state == "generating" then
			
		elseif game.state == "waiting_for_players" then
			
		elseif game.state == "waiting_for_wave" then
			local timer = game.timer
			game.timer = game.timer - dtime
			if game.timer < 0 then
				game.timer = 1
				start_wave(id)
			end
			if math.floor(timer) ~= math.floor(game.timer) then
				for name,_ in pairs(game.players) do
					local player = minetest.get_player_by_name(name)
					tower_defense.hud.update(player)
				end
			end
		elseif game.state == "wave" then
			game.timer = game.timer - dtime
			if game.timer < 0 then
				game.timer = 1
				game.tanks = tower_defense.get_tanks_in_game(id)
				if game.tanks == 0 then
					game.wave = game.wave + 1
					game.timer = 240
					game.state = "waiting_for_wave"
				end
				for name,_ in pairs(game.players) do
					local player = minetest.get_player_by_name(name)
					tower_defense.hud.update(player)
				end
			end
		elseif game.saate == "win" then
			
		elseif game.state == "lose" then
			
		else
			
		end
	end
end)

minetest.register_chatcommand("new_td_game",{
	privs = {interact = true},
	description = "Create a new tower defense game",
	func = function(name,param)
		local success, id = tower_defense.new_game("random")
		minetest.chat_send_player(name, "Game created id: " .. tostring(id))
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
	func = function(name,param)
		local player = minetest.get_player_by_name(name)
		return tower_defense.leave_game(player)
	end,
	
})
