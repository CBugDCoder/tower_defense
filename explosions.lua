local function explosion_effects(pos,strength)
	minetest.sound_play("td_explosion", {pos = pos, gain = strength/100, max_hear_distance = 60,}, true)
	minetest.add_particlespawner({
		amount = 20,
		time = 0.1,
		minpos = vector.add(pos,{x=-0.5,y=-0.5,z=-0.5}),
		maxpos = vector.add(pos,{x=0.5,y=0.5,z=0.5}),
		minvel = {x=-2,y=-2,z=-2},
		maxvel = {x=2,y=2,z=2},
		minacc = {x=0,y=0,z=0},
		maxacc = {x=0,y=0,z=0},
		minexptime = 0.5,
		maxexptime = 1,
		minsize = 5,
		maxsize = 10,
		collisiondetection = false,
		collision_removal = false,
		object_collision = false,
		texture = "tower_defense_explosion_smoke.png",
		animation = {
			type = "vertical_frames",
			aspect_w = 16,
			aspect_h = 16,
			length = 1,
		},
	})
end

function tower_defense.explode_nodes(base_pos,base_strength)
	local visited = {}

	local neighbors = {
		{x=-1,y=0,z=0},
		{x=1,y=0,z=0},
		{x=0,y=-1,z=0},
		{x=0,y=1,z=0},
		{x=0,y=0,z=-1},
		{x=0,y=0,z=1},
	}

	local function boom(pos,strength)
		visited[pos.x.." "..pos.y.." "..pos.z] = true
		local node = minetest.get_node(pos)
		if node.name == "air" then
			strength = strength - 5
		else
			local def = minetest.registered_nodes[node.name]
			if def and def.groups and def.groups.health then
				local meta = minetest.get_meta(pos)
				local health = meta:get_int("td_health")
				if health == 0 then health = def.groups.health end
				health = health - strength
				if health == 0 then
					strength = 0
					minetest.set_node(pos,{name="air"})
				elseif health > 0 then
					strength = 0
					meta:set_int("td_health", health)
				elseif health < 0 then
					strength = math.abs(health)
					minetest.set_node(pos,{name="air"})
				end
			else
				strength = 0
			end
		end
		if strength > 0 then
			for _,neighbor in pairs(neighbors) do
				local n_pos = vector.add(pos,neighbor)
				if not visited[n_pos.x.." "..n_pos.y.." "..n_pos.z] then
					boom(n_pos,strength)
				end
			end
		end
	end
	boom(base_pos,base_strength)
	explosion_effects(base_pos,base_strength)
end

function tower_defense.explode_tanks(pos,strength)
	local ents = minetest.get_objects_inside_radius(pos,strength/25)
	for _, ent in ipairs(ents) do
		if ent:get_luaentity() and ent:get_luaentity()._is_tank then
			local t_pos = ent:get_pos()
			local dist = vector.distance(pos,t_pos)
			local punch_strength = math.max(strength - dist*25,0)
			if punch_strength > 0 then
				ent:punch(ent, 1, {damage_groups = {armored = punch_strength},full_punch_interval = 0.5})
			end
		end
	end
	explosion_effects(pos,strength)
end
