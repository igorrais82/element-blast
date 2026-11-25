class_name EventDefs
extends RefCounted
## Data-driven game events. Every run is played under one event.

static var EVENTS := [
	{
		"id": "flood",
		"name": "НАВОДНЕНИЕ",
		"tagline": "холод · вода ×2 · лава → камень",
		"description": "Температура всё время холодная. С неба падает только вода, причём вдвое больше. Вся лава сразу превращается в камень, а в лотке много воды.",
		"rule": "flood",
		"temp_degrees": -5,
		"bg": "#071f3a",
		"bg_light": "#d8edff",
		"accent": "#48b7ff",
		"surge_element": "water",
		"surge_label": "ПРИЛИВ ×2",
		"surge_multiplier": 2.0,
		"event_elements": ["seaweed", "sponge"],
		"start_elements": ["water", "water", "seaweed"],
		"weights": {
			"water": 9.0, "stone": 1.2, "ice": 0.8,
			"seaweed": 1.0, "sponge": 0.8, "sand": 0.5,
		},
	},
	{
		"id": "firestorm",
		"name": "ОГНЕННЫЙ ШТОРМ",
		"tagline": "пекло · лава ×2 · вода кипит",
		"description": "Температура всё время в пекле. С неба льётся лава, вода быстро выкипает, а растения и нефть вспыхивают сами. В лотке много огня.",
		"rule": "inferno",
		"temp_degrees": 82,
		"bg": "#3a0d12",
		"bg_light": "#ffe1d2",
		"accent": "#ff7a3d",
		"surge_element": "lava",
		"surge_label": "ЛАВА ×2",
		"surge_multiplier": 2.0,
		"event_elements": ["coal", "ash"],
		"start_elements": ["fire", "lava", "coal"],
		"weights": {
			"fire": 4.5, "lava": 4.0, "coal": 2.2, "ash": 1.6,
			"stone": 2.0, "oil": 2.0, "gunpowder": 0.8, "sand": 0.8,
		},
	},
	{
		"id": "ice_age",
		"name": "ЛЕДНИКОВЫЙ ПЕРИОД",
		"tagline": "лютый холод · снег ×2 · всё замерзает",
		"description": "Температура всё время лютая. С неба валит снег, вода быстро становится льдом, лава застывает. В лотке много льда и снега.",
		"rule": "deep_freeze",
		"temp_degrees": -33,
		"bg": "#08243f",
		"bg_light": "#ddf2ff",
		"accent": "#8fe6ff",
		"surge_element": "snow",
		"surge_label": "СНЕГ ×2",
		"surge_multiplier": 2.0,
		"event_elements": ["snow", "crystal"],
		"start_elements": ["ice", "snow", "water"],
		"weights": {
			"ice": 6.0, "snow": 3.5, "crystal": 1.6,
			"water": 3.0, "stone": 1.8, "plant": 0.4,
		},
	},
	{
		"id": "bloom",
		"name": "ЦВЕТЕНИЕ",
		"tagline": "рост · споры ×2 · вода питает",
		"description": "Стихии растут как безумные. С неба падают ростки, вода превращается в заросли, а споры разносятся по полю. В лотке много растений.",
		"rule": "bloom",
		"temp_degrees": 22,
		"bg": "#0b2a1d",
		"bg_light": "#daf6d4",
		"accent": "#7fe06a",
		"surge_element": "plant",
		"surge_label": "РОСТКИ ×2",
		"surge_multiplier": 2.0,
		"event_elements": ["spore", "flower"],
		"start_elements": ["plant", "water", "spore"],
		"weights": {
			"plant": 5.0, "spore": 2.8, "flower": 1.8,
			"water": 4.0, "stone": 1.5, "sand": 1.8, "acid": 0.4,
		},
	},
]

static var ELEMENT_NAMES := {
	"seaweed": "Водоросли",
	"sponge": "Губка",
	"coal": "Уголь",
	"ash": "Пепел",
	"snow": "Снег",
	"crystal": "Кристалл",
	"spore": "Споры",
	"flower": "Цветок",
}

static var ELEMENT_COLORS := {
	"seaweed": "#4fd39a",
	"sponge": "#ffd36e",
	"coal": "#8d8899",
	"ash": "#cfc8d4",
	"snow": "#eaf8ff",
	"crystal": "#9fb4ff",
	"spore": "#e2ff7a",
	"flower": "#ff9ed0",
}


static func all() -> Array:
	return EVENTS


static func get_event(id: String) -> Dictionary:
	for event in EVENTS:
		if str(event["id"]) == id:
			return event.duplicate(true)
	return {}


static func pick(rng: RandomNumberGenerator, exclude_id := "") -> Dictionary:
	var pool: Array = []
	for event in EVENTS:
		if str(event["id"]) != exclude_id:
			pool.append(event)
	if pool.is_empty():
		return {}
	return pool[rng.randi_range(0, pool.size() - 1)].duplicate(true)


static func next_event(current_id: String) -> Dictionary:
	if EVENTS.is_empty():
		return {}
	var index := 0
	for i in EVENTS.size():
		if str(EVENTS[i]["id"]) == current_id:
			index = i
			break
	return EVENTS[(index + 1) % EVENTS.size()].duplicate(true)


static func element_name(element: String) -> String:
	return str(ELEMENT_NAMES.get(element, element))


static func element_color(element: String) -> Color:
	return Color(str(ELEMENT_COLORS.get(element, "#ffffff")))
