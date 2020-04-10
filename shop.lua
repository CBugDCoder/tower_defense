tower_defense.shop = {}

function tower_defense.shop.set_inventory_formspec(player)
	local name = player:get_player_name()
	tower_defense.players[name].inventory_form = player:get_inventory_formspec()
	local form = ""..
		"size[9,10.5]"..
		"formspec_version[2]"..
		"item_image_button[0.5,0.5;1,1;tower_defense:wooden_barricade;shop_wood_barricade; ]"..
		"label[0.5,1.5;Wood\n$100]"..
		"item_image_button[2.75,0.5;1,1;tower_defense:stone_barricade;shop_stone_barricade; ]"..
		"label[2.75,1.5;Stone\n$200]"..
		"item_image_button[5,0.5;1,1;tower_defense:steel_barricade;shop_steel_barricade; ]"..
		"label[5,1.5;Steel\n$350]"..
		"item_image_button[7.25,0.5;1,1;tower_defense:obsidian_barricade;shop_obsidian_barricade; ]"..
		"label[7.25,1.5;Obsidian\n$500]"..

		"item_image_button[0.5,2.5;1,1;tower_defense:rifle_turret;shop_rifle_turret; ]"..
		"label[0.5,3.5;Rifle \n$500]"..
		"item_image_button[2.75,2.5;1,1;tower_defense:machine_gun_turret;shop_machine_gun_turret; ]"..
		"label[2.75,3.5;Machine Gun \n$1500]"..
		"item_image_button[5,2.5;1,1;tower_defense:cannon_turret;shop_cannon_turret; ]"..
		"label[5,3.5;Cannon \n$4000]"..
		"item_image_button[7.25,2.5;1,1;tower_defense:land_mine;shop_land_mine; ]"..
		"label[7.25,3.5;Land Mine \n$1000]"..

		"item_image_button[0.5,4.5;1,1;tower_defense:lava_sword;shop_lava_sword; ]"..
		"label[0.5,5.5;Lava Sword \n$500]"..
		"item_image_button[2.75,4.5;1,1;tower_defense:bazooka;shop_bazooka; ]"..
		"label[2.75,5.5;Bazooka \n$5000]"..
		"image_button[5,4.5;1,1;heart.png;shop_heal_flags; ]"..
		"tooltip[shop_heal_flags;Heal Flags]"..
		"label[5,5.5;Heal Flags \n$10000]"..
		"button[7.25,4.5;2,1;shop_start_wave;Start Wave]"..
		"label[7.25,5.5;Start Wave \n$100]"..

		"list[current_player;main;0.5,6.5;8,4;]"
	player:set_inventory_formspec(form)
end

local item_prices = {
	wood_barricade = 100,
	stone_barricade = 200,
	steel_barricade = 350,
	obsidian_barricade = 500,
	rifle_turret = 500,
	machine_gun_turret = 1500,
	cannon_turret = 4000,
	land_mine = 1000,
	lava_sword = 500,
	bazooka = 5000,
	heal_flags = 10000,
	start_wave = 100,
}

local function purchase(player, item)
	local price = item_prices[item]
	local name = player:get_player_name()
	local game_id = tower_defense.players[name].game
	local game = tower_defense.games[game_id]
	if game.cash < price then return end
	local was_purchased = false
	if item == "heal_flags" then
		for _,flag in pairs(game.flags) do
			local flag_pos = vector.add(flag,game.base_pos)
			local meta = minetest.get_meta(flag_pos)
			meta:set_string("td_health","")
		end
		was_purchased = true
	elseif item == "start_wave" then
		if game.state == "waiting_for_wave" then
			tower_defense.games[game_id].timer = 0
			was_purchased = true
		end
	else
		local inv = player:get_inventory()
		local itemstack = ItemStack("tower_defense:"..item)
		if inv:room_for_item("main",itemstack) then
			inv:add_item("main",itemstack)
			was_purchased = true
		end
	end
	if was_purchased then
		tower_defense.games[game_id].cash = game.cash-price
	end
end

minetest.register_on_player_receive_fields(function(player,formname,fields)
	if formname ~= "" then return end

	local name = player:get_player_name()
	if tower_defense.players[name] and tower_defense.players[name].in_game then
		if fields.shop_wood_barricade then
			purchase(player,"wood_barricade")
		elseif fields.shop_stone_barricade then
			purchase(player,"stone_barricade")
		elseif fields.shop_steel_barricade then
			purchase(player,"steel_barricade")
		elseif fields.shop_obsidian_barricade then
			purchase(player,"obsidian_barricade")
		elseif fields.shop_rifle_turret then
			purchase(player,"rifle_turret")
		elseif fields.shop_machine_gun_turret then
			purchase(player,"machine_gun_turret")
		elseif fields.shop_cannon_turret then
			purchase(player,"cannon_turret")
		elseif fields.shop_land_mine then
			purchase(player,"land_mine")
		elseif fields.shop_lava_sword then
			purchase(player,"lava_sword")
		elseif fields.shop_bazooka then
			purchase(player,"bazooka")
		elseif fields.shop_heal_flags then
			purchase(player,"heal_flags")
		elseif fields.shop_start_wave then
			purchase(player,"start_wave")
		end
		return true
	else
		return
	end
end)

function tower_defense.shop.reset_inventory_formspec(player)
	player:set_inventory_formspec(tower_defense.players[player:get_player_name()].inventory_form)
end
