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

local function fire(self,target)
	if type(target) ~= "table" then
		return
	end
	local pos = self.object:get_pos()
	pos.y = pos.y+self._cannon_offset+0.1
	local ent = minetest.add_entity(pos, "tower_defense:missile")
	local offset = vector.direction(pos,target)
	local rot = {
		y = math.atan2(offset.x,-offset.z),
		x = math.asin(offset.y),
		z = 0,
	}
	ent:set_rotation(rot)
	ent:set_velocity(vector.multiply(offset,7))
	local luaent = ent:get_luaentity()
	luaent._last_pos = pos
	luaent._target = target
	luaent._strength = self._attack_strength
	minetest.sound_play("td_missile_launch", {pos = pos, gain = 1.0, max_hear_distance = 60,}, true)
end

local function aim(self)
	if self._target then
		local pos = self.object:get_pos()
		local rot = self.object:get_rotation()
		local yaw = (rot.y-math.atan2(self._target.x-pos.x,pos.z-self._target.z))*180/math.pi+180
		self.object:set_bone_position("Cannon", {x=0,y=6.5,z=0}, {x=0,y=yaw, z=0})
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
		x = -math.sin(yaw)*self._movement_speed,
		y = 0,
		z = math.cos(yaw)*self._movement_speed,
	})
	self._timer = self._timer+dtime
	if self._timer >= self._attack_speed then
		self._timer = 0
		local target = get_target(pos,flag)
		self._target = target
		fire(self,target)
	end
	aim(self)
end

local function tank_on_death(self,_)
	if self._game_id == nil then return nil end
	tower_defense.games[self._game_id].cash = tower_defense.games[self._game_id].cash + self._health*5
end

local function tank_on_activate(self, staticdata)
	self._game_id = tonumber(staticdata)
	self.object:set_hp(self._health)
	self.object:set_acceleration({x=0,y=-9.8,z=0})
	self.object:set_animation({x=1,y=40})
	self.object:set_armor_groups({armored = 100})
end

local function missile_on_step(self,_)
	if type(self._target) ~= "table" or type(self._last_pos) ~= "table" then return end

	local target_dist = vector.distance(self._last_pos,self._target)-0.5
	--Subtract 0.5 here to get the edge of the node rather then the center.
	local pos = self.object:get_pos()
	local dist_traveled = vector.distance(self._last_pos,pos)
	if target_dist > dist_traveled then
		self._last_pos = pos
	else
		tower_defense.explode_nodes(self._target,self._strength)
		self.object:remove()
	end
end

minetest.register_entity("tower_defense:missile", {
	visual = "mesh",
	mesh = "td_missile.obj",
	textures = {"tower_defense_missile.png"},
	visual_size = {x=1,y=1,},
	static_save = false,
	pointable = false,
	on_step = missile_on_step,

	--Variables
	_strength = 0,
	_target = nil,
	_last_pos = nil,
})

local function register_tank(level)
	minetest.register_entity("tower_defense:tank_lvl_" .. tostring(level), {
		visual = "mesh",
		mesh = "td_tank.b3d",
		textures = {"tower_defense_tank.png"},
		visual_size = {x=1+(level-1)/4,y=1+(level-1)/4},
		on_step = tank_on_step,
		on_activate = tank_on_activate,
		on_death = tank_on_death,
		static_save = false,
		physical = true,
		collisionbox = {-0.5, 0.0, -0.5, 0.5, 1.0, 0.5},

		-- Variables
		_game_id = nil,
		_level = level,
		_timer = 0,
		_is_tank = true,
		_target = nil,
		_attack_strength = 20*level,
		_attack_speed = 1*level,
		_health = 100*level*level,
		_movement_speed = 4/level,
		_cannon_offset = 0.65*(1+(level-1)/4),
		_frame = 1,
	})
end

for level=1,8 do
	register_tank(level)
end
