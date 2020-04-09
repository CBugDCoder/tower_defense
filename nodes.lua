--tower_defense/nodes.lua 

---------------
--Unbreakable--
---------------

--Stone
minetest.register_node("tower_defense:stone", {
	tiles = {"default_stone.png"},
	description = "Unbreakable stone for TD games",
	groups = {not_in_creative_inventory = 1, unbreakable = 1},
})

--Sand
minetest.register_node("tower_defense:sand", {
	tiles = {"default_sand.png"},
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
	tiles = {"default_dirt.png"},
	description = "Flag",
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



-------------
---Turrets---
-------------
minetest.register_node("tower_defense:rifle_turret", {
	tiles = {"default_grass.png"},
	description = "Rifle Turret",
	groups = {not_in_creative_inventory = 1, oddly_breakable_by_hand = 3, health = 40, turret = 1}
})
