require "squib"
require "../util"
include Squib

DECK_CONFIG = {
	layout: "layout.yml",
	height: "3.5in", width: "2.5in",
	cards: open_gsheet("../mastersheets/master_blueprint_sheet.gsheet"),
	dpi: 600,
	config: "config.yml"
}

Deck.new(DECK_CONFIG) do
	data = csv file: "cache.csv"
	buffer = data.row_map do |row, new_row|
		new_row["header"] = "Blueprint, Rank #{row['rank']}"
		if_truthy(row["rq1"]) do |req1|
			new_row["rq1_val"] = row["rq1_val"]
			new_row["rq1"] = req1
		end
		if_truthy(row["rq2"]) do |req2|
			new_row["rq2_val"] = row["rq2_val"]
			new_row["rq2"] = req2
		end
		if_truthy(row["rq3"]) do |req3|
			new_row["rq3_val"] = row["rq3_val"]
			new_row["rq3"] = req3
		end
		if_truthy(row["rq4"]) do |req4|
			new_row["rq4_val"] = row["rq4_val"]
			new_row["rq4"] = req4
		end
		if_truthy(row["rq5"]) do |req5|
			new_row["rq5_val"] = row["rq5_val"]
			new_row["rq5"] = req5
		end

		new_row
	end

	background color: "white"

	rect width: "2.5in", height: "3.5in", stroke_color: :black, stroke_width: 25
	text str: buffer["header"], y: "0.2in", layout: "header"

	text str: buffer["rq1_val"], y: "0.5in", layout: "number"
	ext1 = text str: buffer["rq1"], y: "0.55in", layout: "list"

	ext = ext1.map { |text| "#{text[:height]/600.0 + 0.65}in" }

	text str: buffer["rq2_val"], y: ext, layout: "number"
	ext2 = text str: buffer["rq2"], y: ext, layout: "list"

	ext = ext2.map.with_index { |text, i| "#{text[:height]/600.0 + ext[i]/600.0 + 0.1}in" }

	text str: buffer["rq3_val"], y: ext, layout: "number"
	ext3 = text str: buffer["rq3"], y: ext, layout: "list"

	ext = ext3.map.with_index { |text, i| "#{text[:height]/600.0 + ext[i]/600.0 + 0.1}in" }

	text str: buffer["rq4_val"], y: ext, layout: "number"
	ext4 = text str: buffer["rq4"], y: ext, layout: "list"

	ext = ext4.map.with_index { |text, i| "#{text[:height]/600.0 + ext[i]/600.0 + 0.1}in" }

	text str: buffer["rq5_val"], y: ext, layout: "number"
	text str: buffer["rq5"], y: ext, layout: "list"

	text str: data["id"], layout: "bottom_right"

	save_png prefix: "bprint_"
end
