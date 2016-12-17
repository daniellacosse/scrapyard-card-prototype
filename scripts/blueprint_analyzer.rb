require "csv"
require "colorize"
require "./util"
require "byebug"

OUTLIER_TOLERANCE = 1.85
EFFECT_WEIGHT = 1.33

NAME_COLUMN = 1

# (refresh blueprints)
open_gsheet("../mastersheets/master_weapon_sheet.gsheet", "../gut/weapon_cache.csv")
open_gsheet("../mastersheets/master_limb_sheet.gsheet", "../gut/limb_cache.csv")

system %{ruby pre_processing.rb}

# === METHODS
def componentize_table(filepath)
	table = CSV.read filepath
	keys = table.shift
	table
		.select do |table_row|
			row_complete = false

			# TODO: not good to just assume the column, but I'll live for now
			if_truthy(table_row[NAME_COLUMN]) { row_complete = true }

			row_complete
		end
		.map do |table_row|
			cell = {}

			keys.each_with_index do |key, i|
				cell[key] = table_row[i]
			end

			cell
		end
end

def analyze_collection(collection, keys = [])
	analysis = {}

	keys.each do |key|
		collection_values = collection.map { |c| c[key].to_f }

		analysis[key] = {
			mean: collection_values.mean,
			standard_deviation: collection_values.standard_deviation
		}
	end

	analysis
end

def is_outlier(value, value_stats, tolerance = OUTLIER_TOLERANCE)
	result = 0
	if value >= (value_stats[:mean] + tolerance * value_stats[:standard_deviation])
		result = 1
	elsif value <= (value_stats[:mean] - tolerance * value_stats[:standard_deviation])
		debugger
		result = -1
	end

	result
end

def log_stats(analysis, whitelist = [])
	analysis.keys.each do |key|
		next unless whitelist.include? key

		puts "#{key} mean: #{analysis[key][:mean].round(2)}".light_black
		puts "#{key} standard_deviation: #{analysis[key][:standard_deviation].round(2)}\n".light_black
	end
end

def log_outliers(component, analysis, whitelist = [])
	outliers = []

	analysis.keys.each do |key|
		next unless whitelist.include? key

		value = component[key]
		outlier = is_outlier(value.to_f, analysis[key])

		if outlier != 0
			outliers.push([ key, outlier, value ])
		end
	end

	if outliers.length > 0
		puts "=== #{component["name"]}".white

		outliers.each do |outlier_info|
			key, outlier, value = *outlier_info

			outlier_message = (outlier == 1) ? "large" : "small"

			puts "#{key} (#{value}) is very #{outlier_message}".light_red
		end

		puts "\n"
	end
end

def _extract_mobility(mobility_string)
	mobility_score = 1

	return mobility_score unless mobility_string

	mobility_string
		.split(/,\s?/)
		.each do |mobility|
			if mobility.include? "-1/2"
				mobility_score -= 0.5
			elsif mobility.include? "1/2"
				mobility_score += 0.5
			elsif mobility.include? "1"
				mobility_score += 1
			end
		end

	mobility_score
end

def _extract_effect(effect_string)
	effect_score = 1

	if_truthy(effect_string) { effect_score = EFFECT_WEIGHT }

	effect_score
end

def _extract_damage_type(damage_type_string)
	type_score = 1

	if_truthy(damage_type_string) { type_score += damage_type_string.split(/,\s?/).count }

	type_score
end

def __extract_raw_cost(name)
	bp = componentize_table("../blueprint/cards.csv").select { |bp| bp["name"] == name }.first

	byebug if !bp

	bp["rq1_buyout"].to_i + bp["rq2_buyout"].to_i + bp["rq3_buyout"].to_i + bp["rq4_buyout"].to_i
end

# === SCRIPT
weapon_components = componentize_table("../gut/weapon_cache.csv").map do |weapon|

	mobility_score = _extract_mobility(weapon["mobility"])
	damage_type_score = _extract_damage_type(weapon["damage_type"])
	has_effect = _extract_effect(weapon["text"])
	raw_cost = __extract_raw_cost(weapon["name"])

	# computed properties
	weapon["raw_power"] = (
		(
			(weapon["damage"].to_i + 1) *
			(weapon["range"].to_i + 1) *
			mobility_score *
			damage_type_score *
			has_effect
		).to_f / raw_cost.to_f
	)

	weapon["damage_by_spread"] = (
		(weapon["damage"].to_i + 1) *
		(weapon["spread"].to_i + 1)
	)

	weapon
end.group_by { |c| c["_rank"] }.compact

limb_components = componentize_table("../gut/limb_cache.csv").map do |limb|
	weight = limb["weight"].to_i > 0 ? limb["weight"].to_i : 1

	mobility_score = _extract_mobility(limb["mobility"])
	has_effect = _extract_effect(limb["text"])
	raw_cost = __extract_raw_cost(limb["name"])

	# computed properties
	limb["raw_power"] = (
		(
			(limb["armor"].to_i + 1) *
			(limb["resilience"].to_i + 1) *
			mobility_score *
			has_effect
		).to_f / raw_cost
	)

	limb
end.group_by { |c| c["_rank"] }.compact

puts "(WPN)----------------------------------------\n"

# weapon analysis results
weapon_components.keys.sort.each do |rank|
	weapons_of_rank = weapon_components[rank]
	weapon_analysis = analyze_collection(
		weapons_of_rank,
		["raw_power", "damage", "damage_by_spread"]
	)

	puts "### WEP, rank #{rank} ###\n"

	log_stats(
		weapon_analysis,
		["raw_power", "damage", "damage_by_spread"]
	)

	weapons_of_rank.each do |weapon|
		log_outliers(
			weapon,
			weapon_analysis,
			["raw_power", "damage", "damage_by_spread"]
		)
	end
end

puts "(LMB)----------------------------------------\n"

# limb analysis results
limb_components.keys.sort.each do |rank|
	limbs_of_rank = limb_components[rank]
	limb_analysis = analyze_collection(
		limbs_of_rank,
		["raw_power", "armor"]
	)

	puts "### LMB, rank #{rank} ###\n"

	log_stats(
		limb_analysis,
		["raw_power", "armor"]
	)

	limbs_of_rank.each do |limb|
		log_outliers(
			limb,
			limb_analysis,
			["raw_power", "armor"]
		)
	end
end
