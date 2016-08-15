require "../scripts/util"
require "squib"
include Squib

Y_POS = ["0.9in", "1.15in", "1.4in"]

DECK_CONFIG = {
	layout: "layout.yml",
	height: "3.5in", width: "2.5in",
	dpi: 600,
	config: "config.yml"
}

ADD_DECK_CONFIG = DECK_CONFIG.merge({
	cards: open_gsheet("../mastersheets/master_addon_sheet.gsheet", "addon_cache.csv")
})

WEP_DECK_CONFIG = DECK_CONFIG.merge({
	cards: open_gsheet("../mastersheets/master_weapon_sheet.gsheet", "weapon_cache.csv")
})

LMB_DECK_CONFIG = DECK_CONFIG.merge({
	cards: open_gsheet("../mastersheets/master_limb_sheet.gsheet", "limb_cache.csv")
})

Deck.new(ADD_DECK_CONFIG) do
	data = csv file: "addon_cache.csv"
	buffer = data.row_map do |row, new_row|

		new_row["name"] = "#{row["name"]}, (ADD)"

		new_row["meta"] = if_truthy(row["mobility"]) { row["mobility"] }

		new_row["id"] = "ADD-#{row["add_id"]}"

		new_row
	end

	background color: "white"

	rect width: "2.5in", height: "3.5in", stroke_color: :black, stroke_width: 25
	text str: buffer["name"],    y: "0.2in",   layout: "header"
	text str: buffer["meta"],  y: "0.45in",  layout: "meta"

	text str: data["text"], y: "0.75in",  layout: "paragraph"

	text str: buffer["id"],                layout: "bottom_right"

	save_png prefix: "add_"
end

Deck.new(WEP_DECK_CONFIG) do
	data = csv file: "weapon_cache.csv"
	buffer = data.row_map do |row, new_row|
		new_row["name"] = "#{row["name"]}, (WPN)"
		new_row["meta"] = if_truthy(row["mobility"]) { row["mobility"] }

		new_row["meta2"] = [
			if_truthy(row["damage"]){ "Damage: #{row["damage"]}" },
			if_truthy(row["damage_type"]){ "(#{row["damage_type"]})" },
		].compact.join " "

		new_row["meta3"] = [
			if_truthy(row["range"]){ "Range: #{row["range"]}" },
			if_truthy(row["spread"]){ "Spread: #{row["spread"]}" }
		].compact.join ", "

		new_row["id"] = "WEP-#{row["wep_id"]}"

		new_row
	end

	background color: "white"

	rect width: "2.5in", height: "3.5in", stroke_color: :black, stroke_width: 25
	text str: buffer["name"],          y: "0.2in",          layout: "header"
	text str: buffer["meta"],        y: "0.45in",           layout: "meta"
	text str: buffer["meta2"],       y: "0.63in",          layout: "meta"
	text str: buffer["meta3"], y: "1.05in",          layout: "meta"

	text str: data["text"],        y: "1.5in",           layout: "paragraph"


	text str: buffer["id"], layout: "bottom_right"

	save_png prefix: "wpn_"
end

Deck.new(LMB_DECK_CONFIG) do
	data = csv file: "limb_cache.csv"
	buffer = data.row_map do |row, new_row|
		new_row["name"] = "#{row["name"]}, (LMB)"
		new_row["meta"] = if_truthy(row["mobility"]) { row["mobility"] }

		new_row["armor"] = if_truthy(row["armor"]){ "Armor: #{row["armor"]}"}

		new_row["resilience"] = if_truthy(row["resilience"]){ "Resilience: #{row["resilience"]}"}

		new_row["weight"] = if_truthy(row["weight"]){ "Weight: #{row["weight"]}" }

		new_row["id"] = "LMB-#{row["lmb_id"]}"

		new_row
	end

	background color: "white"

	rect width: "2.5in", height: "3.5in", stroke_color: :black, stroke_width: 25
	text str: buffer["name"],          y: "0.2in",          layout: "header"
	text str: buffer["armor"],        y: "0.45in",           layout: "meta"
	text str: buffer["resilience"],   y: "0.63in",          layout: "meta"
	text str: buffer["weight"],       y: "0.81in",          layout: "meta"

	text str: data["text"],        y: "1.5in",           layout: "paragraph"


	text str: buffer["id"], layout: "bottom_right"

	save_png prefix: "lmb_"
end
