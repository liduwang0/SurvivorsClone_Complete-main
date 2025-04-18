extends Node


const ICON_PATH = "res://Textures/Items/Upgrades/"
const WEAPON_PATH = "res://Textures/Items/Weapons/"
const UPGRADES = {
	"chef_small_knife1": {
		"icon": WEAPON_PATH + "chef_small_knife.png",
		"displayname": "Ice Spear",
		"details": "A spear of ice is thrown at a random enemy",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"chef_small_knife2": {
		"icon": WEAPON_PATH + "chef_small_knife.png",
		"displayname": "Ice Spear",
		"details": "An addition Ice Spear is thrown",
		"level": "Level: 2",
		"prerequisite": ["chef_small_knife1"],
		"type": "weapon"
	},
	"chef_small_knife3": {
		"icon": WEAPON_PATH + "chef_small_knife.png",
		"displayname": "Ice Spear",
		"details": "Ice Spears now pass through another enemy and do + 3 damage",
		"level": "Level: 3",
		"prerequisite": ["chef_small_knife2"],
		"type": "weapon"
	},
	"chef_small_knife4": {
		"icon": WEAPON_PATH + "chef_small_knife.png",
		"displayname": "Ice Spear",
		"details": "An additional 2 Ice Spears are thrown",
		"level": "Level: 4",
		"prerequisite": ["chef_small_knife3"],
		"type": "weapon"
	},
	"chef_scissor1": {
		"icon": WEAPON_PATH + "chef_scissor_3_new_attack.png",
		"displayname": "chef_scissor",
		"details": "A magical chef_scissor will follow you attacking enemies in a straight line",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"chef_scissor2": {
		"icon": WEAPON_PATH + "chef_scissor_3_new_attack.png",
		"displayname": "chef_scissor",
		"details": "The chef_scissor will now attack an additional enemy per attack",
		"level": "Level: 2",
		"prerequisite": ["chef_scissor1"],
		"type": "weapon"
	},
	"chef_scissor3": {
		"icon": WEAPON_PATH + "chef_scissor_3_new_attack.png",
		"displayname": "chef_scissor",
		"details": "The chef_scissor will attack another additional enemy per attack",
		"level": "Level: 3",
		"prerequisite": ["chef_scissor2"],
		"type": "weapon"
	},
	"chef_scissor4": {
		"icon": WEAPON_PATH + "chef_scissor_3_new_attack.png",
		"displayname": "chef_scissor",
		"details": "The chef_scissor now does + 5 damage per attack and causes 20% additional knockback",
		"level": "Level: 4",
		"prerequisite": ["chef_scissor3"],
		"type": "weapon"
	},
	"ninja_kunai1": {
		"icon": WEAPON_PATH + "ninja_kunai.png",
		"displayname": "chef_scissor",
		"details": "The chef_scissor now does + 5 damage per attack and causes 20% additional knockback",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"chef_rolling_pin1": {
		"icon": WEAPON_PATH + "chef_rolling_pin.png",
		"displayname": "chef_rolling_pin",
		"details": "A chef_rolling_pin is created and random heads somewhere in the players direction",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"chef_rolling_pin2": {
		"icon": WEAPON_PATH + "chef_rolling_pin.png",
		"displayname": "chef_rolling_pin",
		"details": "An additional chef_rolling_pin is created",
		"level": "Level: 2",
		"prerequisite": ["chef_rolling_pin1"],
		"type": "weapon"
	},
	"chef_rolling_pin3": {
		"icon": WEAPON_PATH + "chef_rolling_pin.png",
		"displayname": "chef_rolling_pin",
		"details": "The chef_rolling_pin cooldown is reduced by 0.5 seconds",
		"level": "Level: 3",
		"prerequisite": ["chef_rolling_pin2"],
		"type": "weapon"
	},
	"chef_rolling_pin4": {
		"icon": WEAPON_PATH + "chef_rolling_pin.png",
		"displayname": "chef_rolling_pin",
		"details": "An additional chef_rolling_pin is created and the knockback is increased by 25%",
		"level": "Level: 4",
		"prerequisite": ["chef_rolling_pin3"],
		"type": "weapon"
	},
	"chef_rolling_pin5": {
		"icon": WEAPON_PATH + "chef_rolling_pin.png",
		"displayname": "chef_rolling_pin",
		"details": "An additional chef_rolling_pin is created and the knockback is increased by 25%",
		"level": "Level: 5",
		"prerequisite": ["chef_rolling_pin4"],
		"type": "weapon"
	},
	"chef_big_knife1": {
		"icon": WEAPON_PATH + "chef_big_knife.png",
		"displayname": "Rotating Knife",
		"details": "Two knives rotate around you, damaging enemies they touch",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"chef_big_knife2": {
		"icon": WEAPON_PATH + "chef_big_knife.png",
		"displayname": "Rotating Knife",
		"details": "An additional knife rotates around you and damage is increased",
		"level": "Level: 2",
		"prerequisite": ["chef_big_knife1"],
		"type": "weapon"
	},
	"chef_big_knife3": {
		"icon": WEAPON_PATH + "chef_big_knife.png",
		"displayname": "Rotating Knife",
		"details": "An additional knife rotates around you and damage is further increased",
		"level": "Level: 3",
		"prerequisite": ["chef_big_knife2"],
		"type": "weapon"
	},
	"chef_big_knife4": {
		"icon": WEAPON_PATH + "chef_big_knife.png",
		"displayname": "Rotating Knife",
		"details": "An additional knife rotates around you and damage is maximized",
		"level": "Level: 4",
		"prerequisite": ["chef_big_knife3"],
		"type": "weapon"
	},
	"armor1": {
		"icon": ICON_PATH + "helmet_1.png",
		"displayname": "Armor",
		"details": "Reduces Damage By 1 point",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "upgrade"
	},
	"armor2": {
		"icon": ICON_PATH + "helmet_1.png",
		"displayname": "Armor",
		"details": "Reduces Damage By an additional 1 point",
		"level": "Level: 2",
		"prerequisite": ["armor1"],
		"type": "upgrade"
	},
	"armor3": {
		"icon": ICON_PATH + "helmet_1.png",
		"displayname": "Armor",
		"details": "Reduces Damage By an additional 1 point",
		"level": "Level: 3",
		"prerequisite": ["armor2"],
		"type": "upgrade"
	},
	"armor4": {
		"icon": ICON_PATH + "helmet_1.png",
		"displayname": "Armor",
		"details": "Reduces Damage By an additional 1 point",
		"level": "Level: 4",
		"prerequisite": ["armor3"],
		"type": "upgrade"
	},
	"speed1": {
		"icon": ICON_PATH + "boots_4_green.png",
		"displayname": "Speed",
		"details": "Movement Speed Increased by 50% of base speed",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "upgrade"
	},
	"speed2": {
		"icon": ICON_PATH + "boots_4_green.png",
		"displayname": "Speed",
		"details": "Movement Speed Increased by an additional 50% of base speed",
		"level": "Level: 2",
		"prerequisite": ["speed1"],
		"type": "upgrade"
	},
	"speed3": {
		"icon": ICON_PATH + "boots_4_green.png",
		"displayname": "Speed",
		"details": "Movement Speed Increased by an additional 50% of base speed",
		"level": "Level: 3",
		"prerequisite": ["speed2"],
		"type": "upgrade"
	},
	"speed4": {
		"icon": ICON_PATH + "boots_4_green.png",
		"displayname": "Speed",
		"details": "Movement Speed Increased an additional 50% of base speed",
		"level": "Level: 4",
		"prerequisite": ["speed3"],
		"type": "upgrade"
	},
	"tome1": {
		"icon": ICON_PATH + "thick_new.png",
		"displayname": "Tome",
		"details": "Increases the size of spells an additional 10% of their base size",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "upgrade"
	},
	"tome2": {
		"icon": ICON_PATH + "thick_new.png",
		"displayname": "Tome",
		"details": "Increases the size of spells an additional 10% of their base size",
		"level": "Level: 2",
		"prerequisite": ["tome1"],
		"type": "upgrade"
	},
	"tome3": {
		"icon": ICON_PATH + "thick_new.png",
		"displayname": "Tome",
		"details": "Increases the size of spells an additional 10% of their base size",
		"level": "Level: 3",
		"prerequisite": ["tome2"],
		"type": "upgrade"
	},
	"tome4": {
		"icon": ICON_PATH + "thick_new.png",
		"displayname": "Tome",
		"details": "Increases the size of spells an additional 10% of their base size",
		"level": "Level: 4",
		"prerequisite": ["tome3"],
		"type": "upgrade"
	},
	"scroll1": {
		"icon": ICON_PATH + "scroll_old.png",
		"displayname": "Scroll",
		"details": "Decreases of the cooldown of spells by an additional 5% of their base time",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "upgrade"
	},
	"scroll2": {
		"icon": ICON_PATH + "scroll_old.png",
		"displayname": "Scroll",
		"details": "Decreases of the cooldown of spells by an additional 5% of their base time",
		"level": "Level: 2",
		"prerequisite": ["scroll1"],
		"type": "upgrade"
	},
	"scroll3": {
		"icon": ICON_PATH + "scroll_old.png",
		"displayname": "Scroll",
		"details": "Decreases of the cooldown of spells by an additional 5% of their base time",
		"level": "Level: 3",
		"prerequisite": ["scroll2"],
		"type": "upgrade"
	},
	"scroll4": {
		"icon": ICON_PATH + "scroll_old.png",
		"displayname": "Scroll",
		"details": "Decreases of the cooldown of spells by an additional 5% of their base time",
		"level": "Level: 4",
		"prerequisite": ["scroll3"],
		"type": "upgrade"
	},
	"ring1": {
		"icon": ICON_PATH + "urand_mage.png",
		"displayname": "Ring",
		"details": "Your spells now spawn 1 more additional attack",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "upgrade"
	},
	"ring2": {
		"icon": ICON_PATH + "urand_mage.png",
		"displayname": "Ring",
		"details": "Your spells now spawn an additional attack",
		"level": "Level: 2",
		"prerequisite": ["ring1"],
		"type": "upgrade"
	},
	"food": {
		"icon": ICON_PATH + "chunk.png",
		"displayname": "Food",
		"details": "Heals you for 20 health",
		"level": "N/A",
		"prerequisite": [],
		"type": "item"
	},
	"chef_pan1": {
		"icon": WEAPON_PATH + "chef_pan.png",
		"displayname": "Chef's Pan I",
		"details": "A heavy pan that swats enemies",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"chef_pan2": {
		"icon": WEAPON_PATH + "chef_pan.png",
		"displayname": "Chef's Pan II",
		"details": "Gain one more pan",
		"level": "Level: 2",
		"prerequisite": ["chef_pan1"],
		"type": "weapon"
	},
	"chef_pan3": {
		"icon": WEAPON_PATH + "chef_pan.png",
		"displayname": "Chef's Pan III",
		"details": "Pans swing 20% faster",
		"level": "Level: 3",
		"prerequisite": ["chef_pan2"],
		"type": "weapon"
	},
	"chef_pan4": {
		"icon": WEAPON_PATH + "chef_pan.png",
		"displayname": "Chef's Pan IV",
		"details": "Gain one more pan",
		"level": "Level: 4",
		"prerequisite": ["chef_pan3"],
		"type": "weapon"
	}
}
