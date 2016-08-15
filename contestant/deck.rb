require "../scripts/util"
require "squib"
include Squib

DECK_CONFIG = {
	layout: "layout.yml",
	height: "3.5in", width: "2.5in",
	cards: open_gsheet("../mastersheets/master_contestant_sheet.gsheet"),
	dpi: 600,
	config: "config.yml"
}

# build build
Deck.new(DECK_CONFIG) do
	data = csv file: "cache.csv"
	buffer = data.row_map do |row, new_row|
		new_row = row

		new_row["meta"] = "(build mode)"
		new_row["meta2"] = "engineering lvl: tier #{row['eng_tier']}"
		new_row["meta3"] = "health: #{row['health']}"

		new_row["ability"] = row["build_skill"]

		new_row
	end

	background color: "white"

	rect width: "2.5in", height: "3.5in", stroke_color: :black, stroke_width: 25
	text str: buffer["name"], y: "0.2in", layout: "header"

	text str: buffer["meta"], y: "0.5in", layout: "bold"
	text str: buffer["meta2"], y: "0.65in", layout: "list"
	text str: buffer["meta3"], y: "0.8in", layout: "list"

	text str: buffer["ability"], y: "1in", layout: "list"

	save_png prefix: "contestant_build_"
end

# combat build
Deck.new(DECK_CONFIG) do
	data = csv file: "cache.csv"
	buffer = data.row_map do |row, new_row|
		new_row = row

		new_row["meta"] = "(combat mode)"
		new_row["meta2"] = "pilot lvl: tier #{row['pilot_tier']}, horsepower: #{row['chassis_power']}"
		new_row["meta3"] = "health: #{row['health']}"

		new_row["ability_1"] = row["pressure_1"]
		new_row["ability_1_number"] = "(-1)"
		new_row["ability_3"] = row["pressure_3"]
		new_row["ability_3_number"] = "(-3)"

		new_row
	end

	background color: "white"

	rect width: "2.5in", height: "3.5in", stroke_color: :black, stroke_width: 25
	text str: buffer["name"], y: "0.2in", layout: "header"

	text str: buffer["meta"], y: "0.5in", layout: "bold"
	text str: buffer["meta2"], y: "0.65in", layout: "list"
	text str: buffer["meta3"], y: "0.8in", layout: "list"

	text str: buffer["ability_1"], y: "1in", layout: "list"

	text str: buffer["ability_1_number"], y: "1in", layout: "lost_num"
	ability_1 = text str: buffer["ability_1"], y: "1in", layout: "list"

	ext = ability_1.map.with_index { |text, i| "#{text[:height]/600.0 + 1.25}in" }

	text str: buffer["ability_3_number"], y: ext, layout: "lost_num"
	ability_1 = text str: buffer["ability_3"], y: ext, layout: "list"

	save_png prefix: "contestant_combat_"
end
