extends TextureRect


var upgrade = null
func _ready():
	if upgrade != null:
		$ItemTexture.texture = load(UpgradeDbSoldier.UPGRADES[upgrade]["icon"])
