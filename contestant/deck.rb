require "../scripts/util"
require "squib"
include Squib

DECK_CONFIG = {
	layout: "layout.yml",
	height: "4in", width: "3in",
	cards: open_gsheet("../mastersheets/master_contestant_sheet.gsheet"),
	dpi: 600,
	config: "config.yml"
}

# build build
Deck.new(DECK_CONFIG) do
	data = csv file: "cache.csv"
	buffer = data.row_map do |row, new_row|
		new_row = row

		new_row["name"] = "\"#{row['name']}\""

		new_row["meta"] = "[BUILD MODE]"
		new_row["meta2"] = "engineering: lv. #{row['eng_lvl']}"
		new_row["meta3"] = "fitness: lv. #{row['body_lvl']}"

		new_row["ability"] = row["build_skill"]

		new_row["flavor"] = "#{row['_demo']}, #{row['_sex']}"
		new_row["flavor2"] = "Origin: #{row['_origin']}"
		new_row["flavor3"] = "#{row['_weight']}, #{row['_height']}"

		new_row
	end

	background color: "white"

	rect width: "3in", height: "4in", stroke_color: :black, stroke_width: 25
	text str: buffer["name"], y: "0.2in", layout: "header"

	text str: buffer["meta"], y: "0.5in", layout: "bold_green"
	text str: buffer["meta2"], y: "0.65in", layout: "fullwidth_list_center"
	text str: buffer["meta3"], y: "0.82in", layout: "fullwidth_list_center"

	text str: buffer["ability"], y: "1in", layout: "fullwidth_list"

	text str: buffer["flavor"], y: "1.75in", layout: "fullwidth_list_gray"
	text str: buffer["flavor2"], y: "1.9in", layout: "fullwidth_list_gray"
	text str: buffer["flavor3"], y: "2.05in", layout: "fullwidth_list_gray"

	text str: buffer["_summary"], y: "2.25in", layout: "fullwidth_list_gray"


	save_png prefix: "contestant_build_"
end

# combat build
Deck.new(DECK_CONFIG) do
	data = csv file: "cache.csv"
	buffer = data.row_map do |row, new_row|
		new_row = row

		new_row["name"] = "\"#{row['name']}\""

		new_row["meta"] = "[COMBAT MODE]"
		new_row["meta2"] = "pilot: lv. #{row['pilot_lvl']}"
		new_row["meta3"] = "chassis: lv. #{row['chassis_lvl']}"
		new_row["meta4"] = "fitness: lv. #{row['body_lvl']}"

		new_row["ability_1"] = row["pressure_1"]
		new_row["ability_1_number"] = "-1 LMB"
		new_row["ability_2"] = row["pressure_2"]
		new_row["ability_2_number"] = "-2 LMB"

		new_row
	end

	background color: "white"

	rect width: "3in", height: "4in", stroke_color: :black, stroke_width: 25
	text str: buffer["name"], y: "0.2in", layout: "header"

	text str: buffer["meta"], y: "0.5in", layout: "bold_red"
	text str: buffer["meta2"], y: "0.65in", layout: "fullwidth_list_center"
	text str: buffer["meta3"], y: "0.82in", layout: "fullwidth_list_center"
	text str: buffer["meta4"], y: "0.98in", layout: "fullwidth_list_center"

	text str: buffer["ability_1"], y: "1.2in", layout: "list"

	text str: buffer["ability_1_number"], y: "1.2in", layout: "lost_num"
	ability_1 = text str: buffer["ability_1"], y: "1.2in", layout: "list"

	ext = ability_1.map.with_index { |text, i| "#{text[:height]/600.0 + 1.45}in" }

	text str: buffer["ability_2_number"], y: ext, layout: "lost_num"
	ability_1 = text str: buffer["ability_2"], y: ext, layout: "list"

	save_png prefix: "contestant_combat_"
end
