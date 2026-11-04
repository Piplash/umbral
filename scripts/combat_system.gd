class_name CombatSystem
extends RefCounted

static func damage(attacker: TacticalUnit, target: TacticalUnit, heavy: bool = false) -> int:
	var power: int = floori(attacker.attack * 1.5) if heavy else attacker.attack
	var amount: int = maxi(1, power - target.defense)
	return ceili(amount * 0.5) if target.defending else amount

static func hit(attacker: TacticalUnit, target: TacticalUnit, heavy: bool = false) -> int:
	var amount: int = mini(target.hp, damage(attacker, target, heavy))
	target.hp -= amount
	return amount
