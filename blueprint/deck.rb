require "squib"
require "../util"
include Squib

DECK_CONFIG = {
	layout: "layout.yml",
	height: "3.5in", width: "2.5in",
	cards: open_gsheet("../mastersheets/master_blueprintsheet.gsheet"),
	dpi: 600,
	config: "config.yml"
}

Deck.new(DECK_CONFIG) do
	data = csv file: "cache.csv"
	buffer = data.row_map do |row, new_row|
		new_row["header"] = "Blueprint, Rank #{row['rank']}"
		if_truthy(row["requirement1"]) do |req1|
			new_row["one"] = "1"
			new_row["req1"] = row["requirement1"].gsub ", ", "\n"
		end
		if_truthy(row["requirement2"]) do |req2|
			new_row["two"] = "2"
			new_row["req2"] = row["requirement2"].gsub ", ", "\n"
		end
		if_truthy(row["requirement3"]) do |req3|
			new_row["three"] = "3"
			new_row["req3"] = row["requirement3"].gsub ", ", "\n"
		end
		if_truthy(row["requirement4"]) do |req4|
			new_row["four"] = "4"
			new_row["req4"] = row["requirement4"].gsub ", ", "\n"
		end
		if_truthy(row["requirement5"]) do |req5|
			new_row["five"] = "5"
			new_row["req5"] = row["requirement5"].gsub ", ", "\n"
		end

		new_row
	end

	background color: "white"

	rect width: "2.5in", height: "3.5in", stroke_color: :black, stroke_width: 25
	text str: buffer["header"], y: "0.2in", layout: "header"

	text str: buffer["one"], y: "0.5in", layout: "number"
	ext1 = text str: buffer["req1"], y: "0.55in", layout: "list"

	ext = ext1.map { |text| "#{text[:height]/600.0 + 0.65}in" }

	text str: buffer["two"], y: ext, layout: "number"
	ext2 = text str: buffer["req2"], y: ext, layout: "list"

	ext = ext2.map.with_index { |text, i| "#{text[:height]/600.0 + ext[i]/600.0 + 0.1}in" }

	text str: buffer["three"], y: ext, layout: "number"
	ext3 = text str: buffer["req3"], y: ext, layout: "list"

	ext = ext3.map.with_index { |text, i| "#{text[:height]/600.0 + ext[i]/600.0 + 0.1}in" }

	text str: buffer["four"], y: ext, layout: "number"
	ext4 = text str: buffer["req4"], y: ext, layout: "list"

	ext = ext4.map.with_index { |text, i| "#{text[:height]/600.0 + ext[i]/600.0 + 0.1}in" }

	text str: buffer["five"], y: ext, layout: "number"
	text str: buffer["req5"], y: ext, layout: "list"

	save_png prefix: "bprint_"
end
