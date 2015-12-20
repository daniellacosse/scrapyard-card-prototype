require "squib"
require "../util"
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
		new_row["meta2"] = "engineering skill: #{row['eng_skill']}"
		new_row["meta3"] = "body: #{row['body']}, mind: #{row['mind']}"

		new_row["ability"] = row["build_passive"] || row["build_active"]

		new_row
	end

	background color: "white"

	rect width: "2.5in", height: "3.5in", stroke_color: :black, stroke_width: 25
	text str: buffer["name"], y: "0.2in", layout: "header"

	text str: buffer["meta"], y: "0.5in", layout: "list"
	text str: buffer["meta2"], y: "0.65in", layout: "list"
	text str: buffer["meta3"], y: "0.8in", layout: "list"

	text str: buffer["ability"], y: "1in", layout: "list"

	save_png prefix: "contestant_build"
end

# combat build
Deck.new(DECK_CONFIG) do
	data = csv file: "cache.csv"
	buffer = data.row_map do |row, new_row|
		new_row = row

		new_row["meta"] = "(combat mode)"
		new_row["meta2"] = "piloting skill: #{row['pilot_skill']}"
		new_row["meta3"] = "body: #{row['body']}, mind: #{row['mind']}"

		new_row["ability"] = row["combat_passive"] || row["combat_active"]

		new_row
	end

	background color: "white"

	rect width: "2.5in", height: "3.5in", stroke_color: :black, stroke_width: 25
	text str: buffer["name"], y: "0.2in", layout: "header"

	text str: buffer["meta"], y: "0.5in", layout: "list"
	text str: buffer["meta2"], y: "0.65in", layout: "list"
	text str: buffer["meta3"], y: "0.8in", layout: "list"

	text str: buffer["ability"], y: "1in", layout: "list"

	save_png prefix: "contestant_combat"
end
