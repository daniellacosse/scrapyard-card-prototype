require "squib"
require "../util"
include Squib

Y_POS = ["0.9in", "1.15in", "1.4in"]

DECK_CONFIG = {
	layout: "layout.yml",
	height: "3.5in", width: "2.5in",
	cards: open_gsheet("../mastersheets/master_componentsheet.gsheet"),
	dpi: 600,
	config: "config.yml"
}

Deck.new(DECK_CONFIG) do
	data = csv file: "cache.csv"
	buffer = data.row_map do |row, new_row|
		new_row["meta"] = [
			row["type"],
			if_truthy(row["gives_flying"]) { "flys" },
			if_truthy(row["gives_digging"]) { "digs" }
		].compact.join ", "

		new_row["meta2"] = [
			if_truthy(row['armor']){ "#{row['armor']} Amr" },
			if_truthy(row['energy']){ "#{row['energy']} Enr" },
			if_truthy(row['speed']){ "#{row['speed']} Spd" }
		].compact.join ", "

		new_row["elec"] = if_truthy(row["elec_res"]) do |elec|
			"#{elec} Elec Resist"
		end

		new_row["incin"] = if_truthy(row["incin_res"]) do |incin|
			"#{incin} Incin Resist"
		end

		new_row["corro"] = if_truthy(row["corro_res"]) do |corro|
			"#{corro} Corro Resist"
		end

		new_row["incin_y"] = Y_POS[
			[new_row["elec"]].truthy_count
		]

		new_row["corro_y"] = Y_POS[
			[new_row["elec"], new_row["incin"]].truthy_count
		]

		new_row["weapon"] = if_truthy(row["has_weapon"]) do
			"#{row['weapon_type']} Weapon"
		end

		elem = if_truthy(row["weapon_elem"]) { |elem| " #{elem}" }

		new_row["weapon_meta"] = [
			if_truthy(row["weapon_dmg"]) { "Damage: #{row['weapon_dmg']}#{elem}" },
			if_truthy(row["weapon_acc"]) { "Acc: #{row['weapon_acc']}" }
		].compact.join ", "

		new_row
	end

	background color: "white"

	rect width: "2.5in", height: "3.5in", stroke_color: :black, stroke_width: 25
	text str: data["name"],          y: "0.2in",          layout: "header"
	text str: buffer["meta"],        y: "0.45in",           layout: "meta"
	text str: buffer["meta2"],       y: "0.63in",          layout: "meta"
	text str: buffer["elec"],        y: Y_POS[0],          layout: "blue"
	text str: buffer["incin"],       y: buffer["incin_y"], layout: "red"
	text str: buffer["corro"],       y: buffer["corro_y"], layout: "green"
	text str: data["effect"],        y: "1.7in",           layout: "paragraph"

	text str: buffer["weapon"],      y: "2.15in",             layout: "subheader"
	text str: buffer["weapon_meta"], y: "2.32in",          layout: "meta"
	text str: data["weapon_effect"], y: "2.6in",          layout: "paragraph"

	text str: data["id"], layout: "bottom_right"

	save_png prefix: "comp_"
end
