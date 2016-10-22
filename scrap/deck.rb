require "../scripts/util"
require "squib"
include Squib

Y_POS = ["0.55in", "0.8in", "1.05in"]
SCRAP_CLASSES = [
	"mechanical",
	"electrical",
	"metal",
	"polymer",
	"ceramic"
]

DECK_CONFIG = {
	layout: "layout.yml",
	height: "2in", width: "2in",
	cards: CSV.read("cards.csv").length - 1,
	dpi: 600,
	config: "config.yml"
}

puts "Printing fronts...\n"

Deck.new(DECK_CONFIG) do
	data = csv file: "cards.csv"
	buffer = data.row_map do |row, new_row|
		new_row["id"] = "#{row["id"]}-#{row["value"]}"
		new_row["type"] = (row["classes"] || "").split(/,\s?/).map { |c| "[#{c}]"}.join(", ")

		new_row["value"] = "$#{row["value"]}"

		new_row
	end

	background color: "white"
	rect width: "2in", height: "2in", stroke_color: :black, stroke_width: 20
	text str: data["name"],               layout: "title"
	text str: data["classes"], y: Y_POS[0],         layout: "fullwidth"
	text str: buffer["value"], y:Y_POS[1], layout: "fullwidth_green"
	text str: buffer["id"], layout: "footer"

	save_png prefix: "scrap_"
end

puts "Printing backs...\n"

Deck.new(DECK_CONFIG) do
	data = csv file: "cards.csv"
	buffer = data.row_map do |row, new_row|
		classes = SCRAP_CLASSES - row["classes"].comma_split
		classes.shuffle!

		class_hints = [ row["classes"].comma_split.shuffle.shift ]

		case row["layer"]
		when 0
			new_row["layer"] = :blue
			new_row["layer_radius"] = "0.875in"
			class_hints << classes.pop
			class_hints << classes.pop
		when 1
			new_row["layer"] = :green
			new_row["layer_radius"] = "0.75in"
			class_hints << classes.pop
			if rand < 0.5
				class_hints << classes.pop
			end
		when 2
			new_row["layer"] = :red
			new_row["layer_radius"] = "0.625in"
			if rand < 0.5
				class_hints << classes.pop
			end
		when 3
			new_row["layer"] = :black
			new_row["layer_radius"] = "0.5in"
			if rand < 0.5
				class_hints = [ row["name"] ]
			end
		end

		class_hints.shuffle!

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

	circle(
		radius: buffer["layer_radius"],
		fill_color: buffer["layer"],
		x: "1in",
		y: "1in",
		stroke_width: 0
	)

	text str: buffer["class_hint_1"], layout: "middle_center", color: "#fff", y: "0.9in"
	text str: buffer["class_hint_2"], layout: "middle_center", color: "#fff", y: "0.75in"
	text str: buffer["class_hint_3"], layout: "middle_center", color: "#fff", y: "1.05in"

	save_png prefix: "scrap_back_"
end
