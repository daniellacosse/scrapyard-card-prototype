require "../scripts/util"
require "squib"
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
