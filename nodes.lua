---------------
--Unbreakable--
---------------

--Stone
minetest.register_node("tower_defense:red_stone", {
	tiles = {"tower_defense_red_stone.png"},
	description = "Unbreakable stone for TD games",
	groups = {not_in_creative_inventory = 1, unbreakable = 1},
})

--Sand
minetest.register_node("tower_defense:yellow_stone", {
	tiles = {"tower_defense_yellow_stone.png"},
	description = "Unbreakable sand for TD games",
	groups = {not_in_creative_inventory = 1, unbreakable = 1},
})

--Barrier
minetest.register_node("tower_defense:barrier", {
	drawtype = "airlike",
	paramtype = "light",
	sunlight_propagates = true,
	description = "Unbreakable barrier for TD games",
	groups = {not_in_creative_inventory = 1, unbreakable = 1},
})

--Flag
minetest.register_node("tower_defense:flag", {
	tiles = {
		"tower_defense_flag_top.png^[transform1",
		"tower_defense_flag_top.png^[transform1",
		"tower_defense_flag_front.png",
		"tower_defense_flag_back.png",
		"tower_defense_flag_side.png^[transform4",
		"tower_defense_flag_side.png",
	},
	drawtype = "nodebox",
	node_box = {
		type = "fixed",
		fixed = {
			{-5/16,-8/16,-1/16,-3/16,8/16,1/16},
			{-3/16,1/16,-1/16,6/16,7/16,1/16},
		}
	},
	description = "Flag",
	paramtype = "light",
	groups = {not_in_creative_inventory = 1, unbreakable = 1, health = 1000}
})



------------------
----Barricades----
------------------
minetest.register_node("tower_defense:wooden_barricade",{
	description = "Wooden Barricade",
	tiles = {"default_wood.png"},
	groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = 3, health = 50}
})

minetest.register_node("tower_defense:stone_barricade",{
	description = "Stone Barricade",
	tiles = {"default_stone.png"},
	groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = 3, health = 100}
})

minetest.register_node("tower_defense:steel_barricade",{
	description = "Steel Barricade",
	tiles = {"default_steel_block.png"},
	groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = 3, health = 250}
})

minetest.register_node("tower_defense:obsidian_barricade",{
	description = "Obsidian Barricade",
	tiles = {"default_obsidian.png"},
	groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = 3, health = 500}
})

