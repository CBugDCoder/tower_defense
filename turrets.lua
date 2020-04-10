-------------
---Turrets---
-------------

--Rifle--
minetest.register_entity("tower_defense:rifle_turret",{
	visual = "mesh",
	mesh = "td_rifle_turret.obj",
	textures = {"tower_defense_rifle_turret.png"},
	pointable = false,
	static_save = false,
	on_step = function(self,dtime)
		self._timer = self._timer + dtime
		if self._timer > 1 then
			self._timer = 0
			local pos = self.object:get_pos()
			local ents = minetest.get_objects_inside_radius(pos,20)
			local closest
			local dist
			for i,ent in ipairs(ents) do
				if ent:get_luaentity() and ent:get_luaentity()._is_tank then
					local d = vector.distance(pos,ent:get_pos())
					if closest == nil then
						closest = i
						dist = d
					else
						if d < dist then
							closest = i
							dist = d
						end
					end
				end
			end
			if closest ~= nil then
				local ent = ents[closest]
				local e_pos = ent:get_pos()
				local dir = vector.direction(pos,e_pos)
				local yaw = math.atan2(dir.x,-dir.z)
				self.object:set_rotation({x=0,y=yaw,z=0})
				ent:punch(self.object, 1, {damage_groups = {armored = 10},full_punch_interval = 0.5})
				minetest.sound_play("td_gunshot", {pos = pos, gain = 1, max_hear_distance = 60,}, true)
			end
		end
	end,
	_timer = 0,
})

minetest.register_node("tower_defense:rifle_turret", {
	tiles = {"tower_defense_rifle_turret.png"},
	inventory_image = "tower_defense_rifle_turret_inv.png",
	description = "Rifle Turret",
	groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = 3, health = 40, turret = 1},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {-0.5,-0.5,-0.5,0.5,0,0.5},
	},
	paramtype = "light",
	on_construct = function(pos)
		minetest.add_entity(pos,"tower_defense:rifle_turret")
	end,
	on_destruct = function(pos)
		local ents = minetest.get_objects_inside_radius(pos,0.5)
		for _,ent in ipairs(ents) do
			if ent:get_luaentity() and ent:get_luaentity().name == "tower_defense:rifle_turret" then
				ent:remove()
			end
		end
	end
})

----Machine Gun----
minetest.register_entity("tower_defense:machine_gun_turret",{
	visual = "mesh",
	mesh = "td_rifle_turret.obj",
	textures = {"tower_defense_mg_turret.png"},
	pointable = false,
	static_save = false,
	on_step = function(self,dtime)
		self._timer = self._timer + dtime
		if self._timer > 0.25 then
			self._timer = 0
			local pos = self.object:get_pos()
			local ents = minetest.get_objects_inside_radius(pos,20)
			local closest
			local dist
			for i,ent in ipairs(ents) do
				if ent:get_luaentity() and ent:get_luaentity()._is_tank then
					local d = vector.distance(pos,ent:get_pos())
					if closest == nil then
						closest = i
						dist = d
					else
						if d < dist then
							closest = i
							dist = d
						end
					end
				end
			end
			if closest ~= nil then
				local ent = ents[closest]
				local e_pos = ent:get_pos()
				local dir = vector.direction(pos,e_pos)
				local yaw = math.atan2(dir.x,-dir.z)
				self.object:set_rotation({x=0,y=yaw,z=0})
				ent:punch(self.object, 1, {damage_groups = {armored = 5},full_punch_interval = 0.5})
				minetest.sound_play("td_gunshot", {pos = pos, gain = 1, max_hear_distance = 60,}, true)
			end
		end
	end,
	_timer = 0,
})

minetest.register_node("tower_defense:machine_gun_turret", {
	tiles = {"tower_defense_mg_turret.png"},
	inventory_image = "tower_defense_mg_turret_inv.png",
	description = "Rifle Turret",
	groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = 3, health = 60, turret = 1},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {-0.5,-0.5,-0.5,0.5,0,0.5},
	},
	paramtype = "light",
	on_construct = function(pos)
		minetest.add_entity(pos,"tower_defense:machine_gun_turret")
	end,
	on_destruct = function(pos)
		local ents = minetest.get_objects_inside_radius(pos,0.5)
		for _,ent in ipairs(ents) do
			if ent:get_luaentity() and ent:get_luaentity().name == "tower_defense:machine_gun_turret" then
				ent:remove()
			end
		end
	end
})



--Missile
minetest.register_entity("tower_defense:turret_missile",{
	visual = "mesh",
	mesh = "td_missile.obj",
	textures = {"tower_defense_missile.png"},
	visual_size = {x=1,y=1,},
	static_save = false,
	pointable = false,
	on_step = function (self,_)
		if type(self._target) ~= "table" or type(self._last_pos) ~= "table" then return end

		local target_dist = vector.distance(self._last_pos,self._target)-0.5
		--Subtract 0.5 here to get the edge rather then the center.
		local pos = self.object:get_pos()
		local dist_traveled = vector.distance(self._last_pos,pos)
		if target_dist > dist_traveled then
			self._last_pos = pos
		else
			tower_defense.explode_tanks(self._target,self._strength)
			self.object:remove()
		end
	end,

	--Variables
	_strength = 0,
	_target = nil,
	_last_pos = nil,
})

----Cannon----
minetest.register_entity("tower_defense:cannon_turret",{
	visual = "mesh",
	mesh = "td_cannon_turret.obj",
	textures = {"tower_defense_cannon_turret_object.png"},
	pointable = false,
	static_save = false,
	on_step = function(self,dtime)
		self._timer = self._timer + dtime
		if self._timer > 4 then
			self._timer = 0
			local pos = self.object:get_pos()
			local ents = minetest.get_objects_inside_radius(pos,40)
			local closest
			local dist
			for i,ent in ipairs(ents) do
				if ent:get_luaentity() and ent:get_luaentity()._is_tank then
					local d = vector.distance(pos,ent:get_pos())
					if closest == nil then
						closest = i
						dist = d
					else
						if d < dist then
							closest = i
							dist = d
						end
					end
				end
			end
			if closest ~= nil then
				local ent = ents[closest]
				local e_pos = ent:get_pos()
				local dir = vector.direction(pos,e_pos)
				local yaw = math.atan2(dir.x,-dir.z)
				self.object:set_rotation({x=0,y=yaw,z=0})
				local missile = minetest.add_entity(vector.add(pos,{x=0,y=3/8,z=0}),"tower_defense:turret_missile")
				local luaent = missile:get_luaentity()
				local rot = {
					y = yaw,
					x = math.asin(dir.y),
					z = 0,
				}
				missile:set_rotation(rot)
				missile:set_velocity(vector.multiply(dir,7))
				luaent._last_pos = vector.add(pos,{x=0,y=3/8,z=0})
				luaent._target = e_pos
				luaent._strength = 500
				minetest.sound_play("td_missile_launch", {pos = pos, gain = 1.0, max_hear_distance = 60,}, true)
			end
		end
	end,
	_timer = 0,
})

minetest.register_node("tower_defense:cannon_turret", {
	tiles = {"tower_defense_cannon_turret.png"},
	inventory_image = "tower_defense_cannon_turret_inv.png",
	description = "Cannon Turret",
	groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = 3, health = 120, turret = 1},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {-0.5,-0.5,-0.5,0.5,0,0.5},
	},
	paramtype = "light",
	on_construct = function(pos)
		minetest.add_entity(pos,"tower_defense:cannon_turret")
	end,
	on_destruct = function(pos)
		local ents = minetest.get_objects_inside_radius(pos,0.5)
		for _,ent in ipairs(ents) do
			if ent:get_luaentity() and ent:get_luaentity().name == "tower_defense:cannon_turret" then
				ent:remove()
			end
		end
	end
})

--Land Mine
minetest.register_node("tower_defense:land_mine", {
	tiles = {"tower_defense_land_mine.png"},
	inventory_image = "tower_defense_land_mine.png",
	description = "Land Mine",
	groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = 3, health = 250, turret = 1},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {-0.5,-0.5,-0.5,0.5,-7/16,0.5},
	},
	walkable = false,
	paramtype = "light",
	on_timer = function(pos)
		local ents = minetest.get_objects_inside_radius(pos,0.75)
		local tripped = false
		for _,ent in pairs(ents) do
			if ent:get_luaentity() and ent:get_luaentity()._is_tank then
				tripped = true
				break
			end
		end
		if tripped then
			tower_defense.explode_tanks(pos,800)
			minetest.set_node(pos,{name="air"})
		else
			return true
		end
	end,
	on_construct = function(pos)
		minetest.get_node_timer(pos):start(0.5)
	end
})
