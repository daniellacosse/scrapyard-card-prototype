require "squib"
require "../util"
require "byebug"
include Squib

Y_POS = ["0.55in", "0.8in", "1.05in"]
SCRAP_CLASSES = [
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
]

scraps = CSV.read "cache.csv"
scrap_properties = scraps.shift

scrap_remappings = CSV.read "../blueprint/results.csv"

mapping_counts = scrap_remappings.transpose.last

# stats
count_average = mapping_counts.mean
count_stddev = mapping_counts.standard_deviation
count_skews = mapping_counts.map { |scrap_count| (scrap_count.to_i - count_average) / count_stddev }
count_skew_min, count_skew_max = count_skews.min.round, count_skews.max.round
weighted_count_skews = count_skews.map do |skew|
	raw_weight = (2 * (skew - count_skew_min) / (count_skew_max - count_skew_min)) - 1

	raw_weight = -1 if raw_weight < -1
	raw_weight = 1 if raw_weight > 1

	raw_weight
end

# building out the new deck
remapped_deck = {}
remapped_deck["layer"] = []
scrap_properties.each { |property| remapped_deck[property] = [] }

scraps.each_with_index do |this_scrap, i|
	scrap_selection = scrap_remappings.select do |scrap|
		scrap.first == this_scrap[scrap_properties.index "name"]
	end.first

	if !!scrap_selection
		scrap_count = scrap_selection.last.to_i
		weighted_skew = weighted_count_skews[i]
		skew_thresholds = [
			0.12 * 7.87 ** weighted_skew,
			0.37 * 2.69 ** weighted_skew,
			0.65 * 1.64 ** weighted_skew,
			1
		]

		# 			1  2   3   4
		# 1 => 62% 87% 100% --
		# 0 => 25% 50% 75% 100%
		# -1 => 0% 12% 37% 100%

		scrap_count.times do |pass|
			# push scrap into remapped_deck (prop by prop :/)
			scrap_properties.each_with_index { |key, j| remapped_deck[key] << scrap[j] }

			# count up to the correct layer for this copy of the card
			percent_complete = pass.to_f / scrap_count
			skewed_layer = 0
			until percent_complete <= skew_thresholds[skewed_layer]
				skewed_layer += 1
			end

			# shut up i don't care
			counts = Hash[
				remapped_deck["layer"]
					.each_with_object(Hash.new(0)) { |word, counts| counts[word] += 1 }
			]

			# finally, push the correct layer the scrap corresponds to into the card object
			if skewed_layer == 3
				remapped_deck["layer"] << skewed_layer
			elsif counts[skewed_layer + 1].to_i <= counts[skewed_layer].to_i
				remapped_deck["layer"] << skewed_layer + 1
			else
				remapped_deck["layer"] << skewed_layer
			end
		end
	end
end

DECK_CONFIG = {
	layout: "layout.yml",
	height: "2in", width: "2in",
	cards: remapped_deck.values.first.count,
	dpi: 600,
	config: "config.yml"
}

puts "Printing fronts...\n"

Deck.new(DECK_CONFIG) do
	background color: "white"
	rect width: "2in", height: "2in", stroke_color: :black, stroke_width: 20
	text str: buffer["name"],               layout: "title"
	text str: buffer["classes"], y: Y_POS[0],         layout: "fullwidth"
	text str: buffer["value"], y:Y_POS[1], layout: "fullwidth"
	text str: buffer["effects"], y: Y_POS[2],   layout: "paragraph"
	text str: buffer["id"], y: "1.9in", x: "1.95in", layout: "paragraph"

	save_png prefix: "scrap_"
end

puts "Printing backs...\n"

Deck.new(DECK_CONFIG) do
	buffer = remapped_deck.row_map do |row, new_row|
		classes = SCRAP_CLASSES - row["classes"].split ", "
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
