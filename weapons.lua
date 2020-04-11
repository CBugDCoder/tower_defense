--------------------
---Lava Sword----
--------------------
minetest.register_tool("tower_defense:lava_sword", {
	description = "Lava Sword",
	inventory_image = "tower_defense_lava_sword.png",
	tool_capabilities = {
		damage_groups = {armored = 50},
		punch_attack_uses = 100,
		full_punch_interval = 1,
		range = 8,
	},
	groups = {not_in_creative_inventory = 1},
})

---------------
----Bazooka----
---------------
minetest.register_entity("tower_defense:bazooka_missile", {
	visual = "mesh",
	mesh = "td_missile.obj",
	textures = {"tower_defense_missile.png"},
	visual_size = {x=1,y=1,},
	static_save = false,
	pointable = false,
	on_step = function (self,_)
		if type(self._controller) ~= "string" then return end
		local player = minetest.get_player_by_name(self._controller)
		if not player then return end

		local player_pos = player:get_pos()
		player_pos.y = player_pos.y+player:get_properties().eye_height
		local pos = self.object:get_pos()
		local lookdir = player:get_look_dir()
		local dist = vector.distance(pos,player_pos)
		local aim_pos = vector.add(player_pos,vector.multiply(lookdir,dist+1))
		local aim = vector.direction(pos,aim_pos)
		local rot = {
			y = math.atan2(aim.x,-aim.z),
			x = -math.asin(aim.y),
			z = 0,
		}
		self.object:set_rotation(rot)
		self.object:set_velocity(vector.multiply(aim,7))
		if self._last_pos == nil then
			self._last_pos = pos
		else
			local ray = minetest.raycast(self._last_pos,vector.add(pos,aim))
			local next = ray:next()
			if next and not (next.type == "object" and next.ref:is_player()) then
				tower_defense.explode_tanks(pos,500)
				self.object:remove()
			else
				self._last_pos = pos
			end
		end
	end,

	--Variables
	_controller = nil,
	_last_pos = nil,
})

minetest.register_tool("tower_defense:bazooka", {
	description = "Bazooka",
	inventory_image = "tower_defense_bazooka.png",
	groups = {not_in_creative_inventory = 1},
	on_use = function(itemstack, user, _)
		local player_pos = user:get_pos()

		local pos = vector.new(player_pos.x,player_pos.y,player_pos.z)
		pos.y = pos.y+user:get_properties().eye_height

		local ent = minetest.add_entity(pos,"tower_defense:bazooka_missile")

		local name = user:get_player_name()

		local luaent = ent:get_luaentity()

		luaent._controller = name

		local dir = user:get_look_dir()
		local rot = {
			y = math.atan2(dir.x,-dir.z),
			x = -math.asin(dir.y),
			z = 0,
		}
		ent:set_rotation(rot)
		ent:set_velocity(vector.multiply(dir,7))

		minetest.sound_play("td_missile_launch", {pos = pos, gain = 1.0, max_hear_distance = 60,}, true)

		itemstack:add_wear(1000)
		return itemstack
	end
})
