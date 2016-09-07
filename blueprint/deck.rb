require "../scripts/util"
require "squib"
include Squib

DECK_CONFIG = {
	layout: "layout.yml",
	height: "3.5in", width: "2.5in",
	cards: CSV.read("cards.csv").length - 1,
	dpi: 600,
	config: "config.yml"
}

Deck.new(DECK_CONFIG) do
	data = csv file: "cards.csv"
	module_data = csv file: "../scrapper_module/cache.csv"
	buffer = data.row_map do |row, new_row|
		new_row["header"] = "Recipe, Rank #{row['rank']}"
		new_row["meta"] = "#{row['name']}, #{row['type']}"
		if_truthy(row["rq1"]) do |req1|
			new_row["rq1_buyout"] = "$#{row["rq1_buyout"]}"
			new_row["rq1"] = req1
		end
		if_truthy(row["rq2"]) do |req2|
			new_row["rq2_buyout"] = "$#{row["rq2_buyout"]}"
			new_row["rq2"] = req2
		end
		if_truthy(row["rq3"]) do |req3|
			new_row["rq3_buyout"] = "$#{row["rq3_buyout"]}"
			new_row["rq3"] = req3
		end
		if_truthy(row["rq4"]) do |req4|
			new_row["rq4_buyout"] = "$#{row["rq4_buyout"]}"
			new_row["rq4"] = req4
		end
		if_truthy(row["rq5"]) do |req5|
			new_row["rq5_buyout"] = "$#{row["rq5_buyout"]}"
			new_row["rq5"] = req5
		end

		new_row["id"] = "#{row['type']}-#{row['id']}"

		new_row
	end

	background color: "white"

	rect width: "2.5in", height: "3.5in", stroke_color: :black, stroke_width: 25
	text str: buffer["header"], y: "0.2in", layout: "header"
	text str: buffer["meta"], y: "0.5in", layout: "header"

	text str: buffer["rq1_buyout"], y: "0.8in", layout: "number"
	ext1 = text str: buffer["rq1"], y: "0.8in", layout: "list"

	ext = ext1.map { |text| "#{text[:height]/600.0 + 0.95}in" }

	text str: buffer["rq2_buyout"], y: ext, layout: "number"
	ext2 = text str: buffer["rq2"], y: ext, layout: "list"

	ext = ext2.map.with_index { |text, i| "#{text[:height]/600.0 + ext[i]/600.0 + 0.25}in" }

	text str: buffer["rq3_buyout"], y: ext, layout: "number"
	ext3 = text str: buffer["rq3"], y: ext, layout: "list"

	ext = ext3.map.with_index { |text, i| "#{text[:height]/600.0 + ext[i]/600.0 + 0.25}in" }

	text str: buffer["rq4_buyout"], y: ext, layout: "number"
	ext4 = text str: buffer["rq4"], y: ext, layout: "list"

	ext = ext4.map.with_index { |text, i| "#{text[:height]/600.0 + ext[i]/600.0 + 0.25}in" }

	text str: buffer["rq5_buyout"], y: ext, layout: "number"
	text str: buffer["rq5"], y: ext, layout: "list"

	text str: buffer["id"], layout: "bottom_right"

	save_png prefix: "bprint_"
end
