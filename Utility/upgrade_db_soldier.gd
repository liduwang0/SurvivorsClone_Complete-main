extends Node


const ICON_PATH = "res://Textures/Items/Upgrades/"
const WEAPON_PATH = "res://Textures/Items/Soldier_weaponse/"
const UPGRADES = {
	"soldier_bullet1": {
		"icon": WEAPON_PATH + "soldier_bullet.png",
		"displayname": "bullet",
		"details": "A bullet is thrown at a random enemy",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"soldier_bullet2": {
		"icon": WEAPON_PATH + "soldier_bullet.png",
		"displayname": "bullet",
		"details": "An additional bullet is thrown",
		"level": "Level: 2",
		"prerequisite": ["soldier_bullet1"],
		"type": "weapon"
	},
	"soldier_bullet3": {
		"icon": WEAPON_PATH + "soldier_bullet.png",
		"displayname": "bullet",
		"details": "bullets now pass through another enemy and do + 3 damage",
		"level": "Level: 3",
		"prerequisite": ["soldier_bullet2"],
		"type": "weapon"
	},
	"soldier_bullet4": {
		"icon": WEAPON_PATH + "soldier_bullet.png",
		"displayname": "bullet",
		"details": "An additional 2 bullets are thrown",
		"level": "Level: 4",
		"prerequisite": ["soldier_bullet3"],
		"type": "weapon"
	},
		"soldier_bullet5": {
		"icon": WEAPON_PATH + "soldier_bullet.png",
		"displayname": "bullet",
		"details": "An additional 2 bullets are thrown",
		"level": "Level: 5",
		"prerequisite": ["soldier_bullet4"],
		"type": "weapon"
	},
	
	"food": {
		"icon": ICON_PATH + "chunk.png",
		"displayname": "Food",
		"details": "Heals you for 20 health",
		"level": "N/A",
		"prerequisite": [],
		"type": "item"
	}
}
