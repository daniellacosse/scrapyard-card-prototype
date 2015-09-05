require "squib"
require "../util"
include Squib

Y_POS = ["0.55in", "0.8in", "1.05in"]

open_gsheet("../mastersheets/master_scrapsheet.gsheet")

data = CSV.read "cache.csv"
keys = data.shift

mappings = CSV.read "blueprint_edited_results.csv"
mappings.shift

remapped_data = {}
keys.each { |key| remapped_data[key] = [] }

name_index = keys.index "name"

data.each_with_index do |row, i|
	selection = mappings.select { |e| e.first == row[name_index] }.first
	if selection
		number = selection.last.to_i
		number.times do
			keys.each_with_index { |key, j| remapped_data[key] << row[j] }
		end
	else
		keys.each_with_index { |key, j| remapped_data[key] << row[j] }
	end
end

DECK_CONFIG = {
	layout: "layout.yml",
	height: "2in", width: "2in",
	cards: remapped_data.values.first.count,
	dpi: 600,
	config: "config.yml"
}

Deck.new(DECK_CONFIG) do
	buffer = remapped_data.row_map do |row, new_row|
		# create text strings based on row values
		new_row["plys"] = if_truthy(row["polymers"]) { |ply| "#{ply} Polymers" }
		new_row["cers"] = if_truthy(row["ceramics"]) { |cer| "#{cer} Ceramics" }
		new_row["alys"] = if_truthy(row["alloys"]) { |aly| "#{aly} Alloys" }
		new_row["slvs"] = if_truthy(row["is_salvageable"]) { "Salvageable!" }

		# determine y position of text strings based on the others' exsistence
		new_row["cers_y"] = Y_POS[[new_row["plys"]].truthy_count]
		new_row["alys_y"]	= Y_POS[[new_row["plys"], new_row["cers"]].truthy_count]

		new_row
	end

	background color: "white"
	rect width: "2in", height: "2in", stroke_color: :black, stroke_width: 10
	text str: remapped_data["name"],               layout: "title"
	text str: buffer["plys"], y: Y_POS[0],         layout: "fullwidth"
	text str: buffer["cers"], y: buffer["cers_y"], layout: "fullwidth"
	text str: buffer["alys"], y: buffer["alys_y"], layout: "fullwidth"
	text str: buffer["slvs"],                      layout: "footer"
	# text str: data["rarity"],                      layout: "bottomright"

	save_png prefix: "scrap_"
end

puts "Printed Fronts. Now onto backs..."

Deck.new(DECK_CONFIG) do
	buffer = remapped_data.row_map do |row, new_row|
		case row["rarity"]
		when "*"
			new_row["rarity_color"] = "brass"
		when "**"
			new_row["rarity_color"] = "silver"
		when "***"
			new_row["rarity_color"] = "gold"
		end
		new_row
	end

	background color: "white"
	rect width: "2in", height: "2in", stroke_color: :black, stroke_width: 30

	text str: "+", layout: buffer["rarity_color"]

	save_png prefix: "scrap_back_"
end
