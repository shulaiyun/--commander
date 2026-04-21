extends Control

const FACTION_DATA_PATH := "res://data/factions/factions.json"
const EVENT_DATA_PATH := "res://data/events/events.json"

var _root_panel: VBoxContainer
var _node_list: ItemList
var _detail_label: RichTextLabel
var _faction_filter: OptionButton
var _status_label: Label
var _current_faction_filter := "全部"
var _nodes: Array = [
	{
		"id": "shanghai",
		"name": "上海",
		"type": "城市",
		"owner": "republic",
		"industrial": 80,
		"supply": 70,
		"strategic": 90
	},
	{
		"id": "qingdao",
		"name": "青岛",
		"type": "港口",
		"owner": "foreign_concession",
		"industrial": 55,
		"supply": 60,
		"strategic": 75
	},
	{
		"id": "nanjing",
		"name": "南京",
		"type": "首都",
		"owner": "republic",
		"industrial": 65,
		"supply": 55,
		"strategic": 88
	},
	{
		"id": "wuhan_airfield",
		"name": "武汉机场",
		"type": "机场",
		"owner": "republic",
		"industrial": 40,
		"supply": 58,
		"strategic": 67
	},
	{
		"id": "dalian",
		"name": "大连",
		"type": "港口",
		"owner": "empire",
		"industrial": 62,
		"supply": 66,
		"strategic": 82
	},
	{
		"id": "taipei",
		"name": "台北",
		"type": "港口",
		"owner": "empire",
		"industrial": 50,
		"supply": 62,
		"strategic": 71
	},
	{
		"id": "harbin",
		"name": "哈尔滨",
		"type": "铁路枢纽",
		"owner": "warlord",
		"industrial": 48,
		"supply": 80,
		"strategic": 78
	},
	{
		"id": "hong_kong",
		"name": "香港",
		"type": "港口",
		"owner": "foreign_concession",
		"industrial": 73,
		"supply": 85,
		"strategic": 91
	}
]

var _factions: Dictionary = {}

func _ready() -> void:
	_load_faction_data()
	_build_ui()
	_refresh_faction_filter()
	_refresh_node_list()
	_status_label.text = "最小世界地图原型已加载。下一步：把 _nodes 数据迁入配置文件。"

func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	add_child(margin)

	_root_panel = VBoxContainer.new()
	_root_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_root_panel.add_theme_constant_override("separation", 12)
	margin.add_child(_root_panel)

	var title := Label.new()
	title.text = "裂变纪元 · 世界地图垂直切片"
	title.add_theme_font_size_override("font_size", 28)
	_root_panel.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "目标：节点展示 / 势力筛选 / 节点详情 / 数据驱动迁移前的最小占位原型"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root_panel.add_child(subtitle)

	var toolbar := HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 10)
	_root_panel.add_child(toolbar)

	var faction_label := Label.new()
	faction_label.text = "势力筛选："
	toolbar.add_child(faction_label)

	_faction_filter = OptionButton.new()
	_faction_filter.item_selected.connect(_on_faction_filter_changed)
	toolbar.add_child(_faction_filter)

	var layout := HSplitContainer.new()
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_root_panel.add_child(layout)

	_node_list = ItemList.new()
	_node_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_node_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_node_list.item_selected.connect(_on_node_selected)
	layout.add_child(_node_list)

	_detail_label = RichTextLabel.new()
	_detail_label.fit_content = true
	_detail_label.scroll_active = true
	_detail_label.bbcode_enabled = true
	layout.add_child(_detail_label)

	_status_label = Label.new()
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root_panel.add_child(_status_label)

func _load_faction_data() -> void:
	var file := FileAccess.open(FACTION_DATA_PATH, FileAccess.READ)
	if file == null:
		push_warning("无法读取势力数据：%s" % FACTION_DATA_PATH)
		return

	var content := file.get_as_text()
	var parsed = JSON.parse_string(content)
	if typeof(parsed) == TYPE_DICTIONARY and parsed.has("factions"):
		for faction in parsed["factions"]:
			_factions[faction["id"]] = faction

func _refresh_faction_filter() -> void:
	_faction_filter.clear()
	_faction_filter.add_item("全部", 0)

	var ids := _factions.keys()
	ids.sort()
	for faction_id in ids:
		var faction := _factions[faction_id]
		_faction_filter.add_item(faction.get("name", faction_id))

func _refresh_node_list() -> void:
	_node_list.clear()
	var selected_faction_name := _current_faction_filter

	for node in _nodes:
		var faction := _factions.get(node["owner"], {})
		var owner_name := faction.get("name", node["owner"])

		if selected_faction_name != "全部" and owner_name != selected_faction_name:
			continue

		var label := "%s [%s] - %s" % [node["name"], node["type"], owner_name]
		_node_list.add_item(label)
		_node_list.set_item_metadata(_node_list.get_item_count() - 1, node)

	if _node_list.get_item_count() > 0:
		_node_list.select(0)
		_on_node_selected(0)
	else:
		_detail_label.text = "没有符合条件的节点。"

func _on_faction_filter_changed(index: int) -> void:
	_current_faction_filter = _faction_filter.get_item_text(index)
	_refresh_node_list()

func _on_node_selected(index: int) -> void:
	var node: Dictionary = _node_list.get_item_metadata(index)
	var faction := _factions.get(node["owner"], {})
	var owner_name := faction.get("name", node["owner"])
	var alignment := faction.get("alignment", "未知阵营")

	_detail_label.clear()
	_detail_label.append_text(
		"[b]%s[/b]\n类型：%s\n所属势力：%s\n阵营：%s\n工业：%s\n补给：%s\n战略值：%s\n" % [
			node["name"],
			node["type"],
			owner_name,
			alignment,
			node["industrial"],
			node["supply"],
			node["strategic"]
		]
	)
