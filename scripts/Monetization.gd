extends Node
## Store and ad flow. Test mode is enabled until real RuStore billing/ads IDs
## are configured in RUSTORE_APP_ID / TEST_MODE below.

signal purchase_completed(product_id: String)
signal purchase_failed(product_id: String, message: String)
signal ad_requested(reason: String)

const TEST_MODE := true
const RUSTORE_APP_ID := ""
const AD_INTERVAL := 180.0
const AD_COOLDOWN := 90.0

const PRODUCTS := [
	{
		"id": "remove_ads",
		"title": "УБРАТЬ РЕКЛАМУ",
		"desc": "Никакой рекламы после проигрыша и во время игры.",
		"price": "99 ₽",
	},
	{
		"id": "pack_metals",
		"title": "ПАК «МЕТАЛЛЫ»",
		"desc": "8 новых элементов: железо, медь, золото, серебро, свинец, олово, ртуть, титан.",
		"price": "149 ₽",
	},
	{
		"id": "pack_flora",
		"title": "ПАК «ФЛОРА»",
		"desc": "8 новых элементов: гриб, мох, лоза, пыльца, слизь, кость, ракушка, плесень.",
		"price": "149 ₽",
	},
]

var session_seconds := 0.0
var ad_cooldown := 0.0
var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func product(id: String) -> Dictionary:
	for entry in PRODUCTS:
		if str(entry["id"]) == id:
			return entry
	return {}


func is_owned(id: String) -> bool:
	if id == "remove_ads":
		return Profile.ads_removed
	return Profile.owns_pack(id)


func purchase(id: String) -> void:
	if _busy or is_owned(id):
		purchase_failed.emit(id, "Уже куплено")
		return
	var entry := product(id)
	if entry.is_empty():
		purchase_failed.emit(id, "Товар не найден")
		return
	_busy = true
	if TEST_MODE:
		# Local test purchase. Replace with RuStore Billing for real payments.
		await get_tree().create_timer(0.7).timeout
		_apply_purchase(id)
		_busy = false
		purchase_completed.emit(id)
		return
	purchase_failed.emit(id, "RuStore Billing не настроен")
	_busy = false


func _apply_purchase(id: String) -> void:
	if id == "remove_ads":
		Profile.set_ads_removed(true)
	elif id == "pack_metals" or id == "pack_flora":
		Profile.unlock_pack(id)


func tick(delta: float, playing: bool) -> void:
	ad_cooldown = maxf(0.0, ad_cooldown - delta)
	if Profile.ads_removed:
		return
	if playing:
		session_seconds += delta
		if session_seconds >= AD_INTERVAL:
			request_interstitial("time")


func request_interstitial(reason: String) -> bool:
	if Profile.ads_removed or ad_cooldown > 0.0:
		return false
	ad_cooldown = AD_COOLDOWN
	ad_requested.emit(reason)
	return true


func on_ad_closed() -> void:
	session_seconds = 0.0
	ad_cooldown = AD_COOLDOWN
