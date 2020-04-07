local textures = {
	"tower_defense_tank.png",
	"tower_defense_treads.png",
	"tower_defense_sm_wheel.png",
	"tower_defense_bg_wheel.png",
}

local function get_closest_flag(pos,flags)
	local min_dist = nil
	local idx = 0
	for i, p in ipairs(flags) do
		if min_dist == nil then
			min_dist = vector.distance(p,pos)
			idx = i
		else
			local dist = vector.distance(p,pos)
			if dist < min_dist then
				min_dist = dist
				idx = i
			end
		end
	end
	return flags[idx], min_dist
end

function tower_defense.get_tanks_in_game(game_id)
	local base_pos = tower_defense.games[game_id].base_pos
	local objects = minetest.get_objects_inside_radius(base_pos,150)
	local count = 0
	for _,object in ipairs(objects) do
		if object and object:get_luaentity() and object:get_luaentity()._is_tank then
			count = count + 1
		end
	end
	return count
end

local function get_target(pos,flag)
	if vector.distance(pos,flag) < 20 then
		local can_see, blocker = minetest.line_of_sight(pos,flag)
		if can_see then
			return flag
		else
			return blocker
		end
	else
		local turret = minetest.find_node_near(pos, 20, "group:turret")
		if turret then
			local can_see, blocker =  minetest.line_of_sight(pos,turret)
			if can_see then
				return turret
			else
				return blocker
			end
		else
			return nil
		end
	end
end

local function aim_and_fire(self,target)
	if target then
		local pos = self.object:get_pos()
		local yaw = math.atan2(target.x-pos.x,target.z-pos.z)
		local a,b = self.object:get_bone_position("Cannon")
		print(dump(a))
		print(dump(b))
		self.object:set_bone_position("Cannon", {x=0,y=6.5,z=0}, {x=0,y=0, z=yaw})
	else
		self.object:set_bone_position("Cannon", {x=0,z=0,y=6.5}, {z=0,x=0,y=0})
	end
end

local function tank_on_step(self, dtime)
	if self._game_id == nil then return nil end
	local pos = self.object:get_pos()
	local base_pos = tower_defense.games[self._game_id].base_pos
	local flags = table.copy(tower_defense.games[self._game_id].flags)
	for i,flag in ipairs(flags) do
		flags[i] = vector.add(flag,base_pos)
	end
	local flag, _ = get_closest_flag(pos, flags)
	local yaw = math.atan2((pos.x-flag.x),(flag.z-pos.z))
	self.object:set_rotation({x=0,y=yaw,z=0})
	self.object:set_velocity({
		x = -math.sin(yaw),
		y = 0,
		z = math.cos(yaw),
	})
	self._timer = self._timer+dtime
	if self._timer >= 1 then
		self._timer = self._timer-1
		local target = get_target(pos,flag)
		aim_and_fire(self,target)
	end
end

local function tank_on_activate(self, staticdata)
	self._game_id = tonumber(staticdata)
	self.object:set_acceleration({x=0,y=-9.8,z=0})
end

minetest.register_entity("tower_defense:tank_lvl_1", {
	visual = "mesh",
	mesh = "tank.b3d",
	textures = textures,
	visual_size = {x=1,y=1},
	on_step = tank_on_step,
	on_activate = tank_on_activate,
	static_save = false,
	physical = true,
	collisionbox = {-0.5, 0.0, -0.5, 0.5, 1.0, 0.5},

	-- Variables
	_game_id = nil,
	_level = 1,
	_timer = 0,
	_is_tank = true,
})
