require "squib"
require "../util"
include Squib

Y_POS = ["0.55in", "0.8in", "1.05in"]

data = CSV.read "cache.csv"
keys = data.shift

mappings = CSV.read "../blueprint/results.csv"
rares = CSV.read "rare_assignments.csv"
reserve = CSV.read "reserve_assignments.csv"
reserve_count = 0

remapped_data = {}
keys.each { |key| remapped_data[key] = [] }

name_index = keys.index "name"

data.each_with_index do |data_row, i|
	map_selection = mappings.select { |mapp| mapp.first == data_row[name_index] }.first
	reserve_selection = reserve.select { |res| res.first == data_row[name_index] }.first
	rare_selection = rares.select { |rar| rar.first == data_row[name_index] }.first

	if map_selection
		number = map_selection.last.to_i

		# if it's a reserve thing, don't need as much in the real stack
		if reserve_selection && (number - reserve_selection.last.to_i > 2)
			number -= reserve_selection.last.to_i
			reserve_count += reserve_selection.last.to_i

			reserve_selection.last.to_i.times do
				keys.each_with_index do |key, j|
					if key == "rarity"
						remapped_data[key] << "r"
					else
						remapped_data[key] << data_row[j]
					end
				end
			end
		end

		number.times do
			keys.each_with_index { |key, j| remapped_data[key] << data_row[j] }
		end
	else
		number = rare_selection.last.to_i
		number.times do
			keys.each_with_index { |key, j| remapped_data[key] << data_row[j] }
		end
	end
end

until reserve_count <= 0
	# animal trophy is the one exception
	mappings.delete_if { |row| row.first == "Animal Trophy" }

	weakest_link = mappings.min { |a, b| a.last.to_i <=> b.last.to_i }

	data_row = data.select { |row| row[0] == weakest_link.first }.first
	keys.each_with_index { |key, j| remapped_data[key] << data_row[j] }

	mappings.map! do |row|
		(row.first == weakest_link.first) ? [row.first, (row.last.to_i + 1).to_s] : row
	end

	reserve_count -= 1
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
		new_row["plys"] = "Polymer" if row["potentcy"] =~ /POLY/
		new_row["cers"] = "Ceramic" if row["potentcy"] =~ /CER/
		new_row["alys"] = "Alloy" if row["potentcy"] =~ /ALLOY/
		new_row["slvs"] = if_truthy(row["salvageable"]) { "Salvageable!" }

		# determine y position of text strings based on the others' exsistence
		new_row["cers_y"] = Y_POS[[new_row["plys"]].truthy_count]
		new_row["alys_y"]	= Y_POS[[new_row["plys"], new_row["cers"]].truthy_count]

		new_row
	end

	background color: "white"
	rect width: "2in", height: "2in", stroke_color: :black, stroke_width: 20
	text str: remapped_data["name"],               layout: "title"
	text str: remapped_data["event_effect"], y: Y_POS[0],   layout: "paragraph"
	text str: buffer["plys"], y: Y_POS[0],         layout: "fullwidth"
	text str: buffer["cers"], y: buffer["cers_y"], layout: "fullwidth"
	text str: buffer["alys"], y: buffer["alys_y"], layout: "fullwidth"
	text str: buffer["slvs"],                      layout: "footer"

	save_png prefix: "scrap_"
end

puts "Printed Fronts. Now onto backs..."

Deck.new(DECK_CONFIG) do
	buffer = remapped_data.row_map do |row, new_row|
		case row["rarity"]
		when "*"
			new_row["rarity_color"] = "•"
		when "**"
			new_row["rarity_color"] = "♦"
		when "***"
			new_row["rarity_color"] = "★"
		when "e"
			new_row["rarity_color"] = "Δ"
		when "r"
			new_row["rarity_color"] = "®"
		end
		new_row
	end

	background color: "#fff"
	rect width: "1.9in", height: "1.9in", x: "0.05in", y: "0.05in", stroke_color: :black, stroke_width: 50

	text str: buffer["rarity_color"], layout: "black"
	text str: buffer["rarity_color"], layout: "black", x: "0.05in", y: "-0.5in"
	text str: buffer["rarity_color"], layout: "black", x: "0.05in", y: "1in"
	text str: buffer["rarity_color"], layout: "black", x: "1.6in", y: "-0.5in"
	text str: buffer["rarity_color"], layout: "black", x: "1.6in", y: "1in"

	save_png prefix: "scrap_back_"
end
