require "squib"
require "../util"
require "byebug"
include Squib

Y_POS = ["0.55in", "0.8in", "1.05in"]

data = CSV.read "cache.csv"
keys = data.shift

mappings = CSV.read "../blueprint/results.csv"


# just have to calculate distributions & class hints now




# OLD =>

# rares = CSV.read "rare_assignments.csv"
# reserve = CSV.read "reserve_assignments.csv"
# reserve_count = 0
#
# remapped_data = {}
# keys.each { |key| remapped_data[key] = [] }
#
# name_index = keys.index "name"
#
# data.each_with_index do |data_row, i|
# 	map_selection = mappings.select { |mapp| mapp.first == data_row[name_index] }.first
# 	reserve_selection = reserve.select { |res| res.first == data_row[name_index] }.first
# 	rare_selection = rares.select { |rar| rar.first == data_row[name_index] }.first
#
# 	if map_selection
# 		number = map_selection.last.to_i
#
# 		# if it's a reserve thing, don't need as much in the real stack
# 		if reserve_selection && (number - reserve_selection.last.to_i > 2)
# 			number -= reserve_selection.last.to_i
# 			reserve_count += reserve_selection.last.to_i
#
# 			reserve_selection.last.to_i.times do
# 				keys.each_with_index do |key, j|
# 					if key == "rarity"
# 						remapped_data[key] << "r"
# 					else
# 						remapped_data[key] << data_row[j]
# 					end
# 				end
# 			end
# 		end
#
# 		number.times do
# 			keys.each_with_index { |key, j| remapped_data[key] << data_row[j] }
# 		end
# 	else
# 		number = rare_selection.last.to_i
# 		number.times do
# 			keys.each_with_index { |key, j| remapped_data[key] << data_row[j] }
# 		end
# 	end
# end
#
# until reserve_count <= 0
# 	# animal trophy is the one exception
# 	mappings.delete_if { |row| row.first == "Animal Trophy" }
#
# 	weakest_link = mappings.min { |a, b| a.last.to_i <=> b.last.to_i }
# 	data_row = data.select { |row| row[0] == weakest_link.first }.first
# 	keys.each_with_index { |key, j| remapped_data[key] << data_row[j] }
#
# 	mappings.map! do |row|
# 		(row.first == weakest_link.first) ? [row.first, (row.last.to_i + 1).to_s] : row
# 	end
#
# 	reserve_count -= 1
# end

# <= OLD

DECK_CONFIG = {
	layout: "layout.yml",
	height: "2in", width: "2in",
	cards: data.count,
	dpi: 600,
	config: "config.yml"
}

Deck.new(DECK_CONFIG) do
	# data = csv file: "cache.csv"
	buffer = remapped_data.row_map do |row, new_row|
	# 	# create text strings based on row values
	# 	new_row["plys"] = "Polymer" if !!(/POLY/ =~ row["potentcy"])
	# 	new_row["cers"] = "Ceramic" if !!(/CER/ =~ row["potentcy"])
	# 	new_row["alys"] = "Alloy" if !!(/ALLOY/ =~ row["potentcy"])
	# 	new_row["slvs"] = if_truthy(row["salvageable"]) { "Salvageable!" }
	#
	# 	# determine y position of text strings based on the others' exsistence
	# 	new_row["cers_y"] = Y_POS[[new_row["plys"]].truthy_count]
	# 	new_row["alys_y"]	= Y_POS[[new_row["plys"], new_row["cers"]].truthy_count]
	#
	# 	new_row
		new_row
	end

	background color: "white"
	rect width: "2in", height: "2in", stroke_color: :black, stroke_width: 20
	text str: buffer["name"],               layout: "title"
	text str: buffer["classes"], y: Y_POS[0],         layout: "fullwidth"
	text str: buffer["value"], y:Y_POS[1], layout: "fullwidth"
	text str: buffer["effects"], y: Y_POS[2],   layout: "paragraph"

	save_png prefix: "scrap_"
end

puts "Printed Fronts. Now onto backs..."

Deck.new(DECK_CONFIG) do
	buffer = remapped_data.row_map do |row, new_row|
	# 	# create text strings based on row values
	# 	new_row["plys"] = "Polymer" if !!(/POLY/ =~ row["potentcy"])
	# 	new_row["cers"] = "Ceramic" if !!(/CER/ =~ row["potentcy"])
	# 	new_row["alys"] = "Alloy" if !!(/ALLOY/ =~ row["potentcy"])
	# 	new_row["slvs"] = if_truthy(row["salvageable"]) { "Salvageable!" }
	#
	# 	# determine y position of text strings based on the others' exsistence
	# 	new_row["cers_y"] = Y_POS[[new_row["plys"]].truthy_count]
	# 	new_row["alys_y"]	= Y_POS[[new_row["plys"], new_row["cers"]].truthy_count]
	#
	# 	new_row

		class_hints = []

		case row["layer"]
		when 0
			new_row["layer"] = "top_green"
		when 1
			new_row["layer"] = "yellow_green"
		when 2
			new_row["layer"] = "orange"
		when 3
			new_row["layer"] = "bottom_orange_red"
		end

		new_row["class_hint_1"] = class_hints.shuffle.pop
		new_row["class_hint_2"] = class_hints.shuffle.pop
		new_row["class_hint_3"] = class_hints.shuffle.pop

		new_row
	end

	background color: "#fff"
	rect(
		width: "1.9in",
		height: "1.9in",
		x: "0.05in",
		y: "0.05in",
		stroke_color: :black,
		stroke_width: 50
	)

	text str: buffer["class_hint_1"], layout: buffer["layer"]
	text str: buffer["class_hint_2"], layout: buffer["layer"], y: "0.5in"
	text str: buffer["class_hint_3"], layout: buffer["layer"], y: "1in"

	save_png prefix: "scrap_back_"
end
