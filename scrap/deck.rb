require "squib"
require "../util"
require "byebug"
include Squib

Y_POS = ["0.55in", "0.8in", "1.05in"]

data = CSV.read "cache.csv"
keys = data.shift

mappings = CSV.read "../blueprint/results.csv"

count_average = mappings.transpose.last.mean
count_stddev = mappings.transpose.last.standard_deviation
count_skews = mappings.transpose.last.map { |number| (number.to_i - count_average) / count_stddev }
count_skew_min, count_skew_max = count_skews.min.round, count_skews.max.round
weighted_count_skews = count_skews.map do |skew|
	raw_weight = (2 * (skew - count_skew_min) / (count_skew_max - count_skew_min)) - 1

	raw_weight = -1 if raw_weight < -1
	raw_weight = 1 if raw_weight > 1

	raw_weight
end

# puts weighted_count_skews.sort

remapped_data = {}
remapped_data["layer"] = []
keys.each { |key| remapped_data[key] = [] }

name_index = keys.index "name"

data.each_with_index do |data_row, i|
	map_selection = mappings.select { |mapp| mapp.first == data_row[name_index] }.first

	if map_selection
		number = map_selection.last.to_i
		weighted_skew = weighted_count_skews[i]
		puts data.map { |row| row[name_index] }.sort - mappings.map { |row| row.first }.sort unless weighted_count_skews[i]
		thresholds = [
			0.12 * 7.87 ** weighted_skew,
			0.37 * 2.69 ** weighted_skew,
			0.65 * 1.64 ** weighted_skew,
			1
		]

		# 			1  2   3   4
		# 1 => 62% 87% 100% --
		# 0 => 25% 50% 75% 100%
		# -1 => 0% 12% 37% 100%

		number.times do |pass|
			keys.each_with_index { |key, j| remapped_data[key] << data_row[j] }

			percent_complete = pass.to_f / number
			skewed_layer = 0
			p thresholds
			p percent_complete, thresholds[skewed_layer]
			until percent_complete <= thresholds[skewed_layer]
				skewed_layer += 1
			end

			remapped_data["layer"] << skewed_layer
		end
	end
end

puts remapped_data["layer"].each_with_object(Hash.new(0)) { |word,counts| counts[word] += 1 }

DECK_CONFIG = {
	layout: "layout.yml",
	height: "2in", width: "2in",
	cards: remapped_data.values.first.count,
	dpi: 600,
	config: "config.yml"
}

Deck.new(DECK_CONFIG) do
	# data = csv file: "cache.csv"
	buffer = remapped_data.row_map do |row, new_row|

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
		classes = [
			"Axel",
			"Blade",
			"Cable",
			"Ceramic",
			"Container",
			"Disc",
			"Electrical",
			"Fastener",
			"Fuel",
			"Mechanical",
			"Metal",
			"Optics",
			"Organic",
			"Polymer",
			"Textile",
			"Tubing"
		] - row["classes"].split(", ")

		classes.shuffle!

		class_hints = [
			row["classes"].split(", ").shuffle.shift,
			classes.first
		].shuffle!


		case row["layer"]
		when 0
			new_row["layer"] = :green
			class_hints << classes.last
			class_hints.shuffle!
		when 1
			new_row["layer"] = "#d4e737"
			if rand < 0.5
				class_hints << classes.last
				class_hints.shuffle!
			end
		when 2
			new_row["layer"] = "#FFA500"
			if rand < 0.15
				class_hints << classes.last
				class_hints.shuffle!
			end
		when 3
			new_row["layer"] = "#ff5a00"
		end

		new_row["class_hint_1"] = class_hints[0]
		new_row["class_hint_2"] = class_hints[1]
		new_row["class_hint_3"] = class_hints[2]

		new_row
	end

	background color: "#fff"
	rect(
		width: "1.9in",
		height: "1.9in",
		x: "0.05in",
		y: "0.05in",
		stroke_color: buffer["layer"],
		stroke_width: 50
	)

	text str: buffer["class_hint_1"], layout: "middle", color: buffer["layer"]
	text str: buffer["class_hint_2"], layout: "middle", color: buffer["layer"], y: "0.5in"
	text str: buffer["class_hint_3"], layout: "middle", color: buffer["layer"], y: "1in"

	save_png prefix: "scrap_back_"
end
