require "csv"
require "colorize"
require "../util"

OUTLIER_TOLERANCE = 2.5

# === METHODS
def componentize_table(filepath)
	table = CSV.read filepath
	keys = table.shift
	table.map do |table_row|
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
		collection_values = collection.map { |c| c[key].to_i }

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
		result = -1
	end

	result
end

def log_stats(analysis, whitelist = [])
	analysis.keys.each do |key|
		next unless whitelist.include? key

		puts "#{key} mean: #{analysis[key][:mean]}\n".light_black
		puts "#{key} standard_deviation: #{analysis[key][:standard_deviation]}\n".light_black
	end
end

def log_outliers(component, analysis, whitelist = [])
	outliers = []

	analysis.keys.each do |key|
		next unless whitelist.include? key

		value = component[key]
		outlier = is_outlier(value.to_i, analysis[key])

		if outlier != 0
			outliers.push([ key, outlier, value ])
		end
	end

	if outliers.length > 0
		puts "=== #{component["name"]}\n".white

		outliers.each do |outlier_info|
			key, outlier, value = *outlier_info

			outlier_message = (outlier == 1) ? "large" : "small"

			puts "#{key} (#{value}) is very #{outlier_message}\n".light_red
		end

		puts "\n\n"
	end
end

# === SCRIPT
weapon_components = componentize_table("weapon_cache.csv").map do |weapon|
	damage_count = if_truthy(weapon["damage_type"]) { weapon["damage_type"].split(", ").length }
	damage_count ||= 1

	# computed properties
	weapon["raw_power"] = (
		weapon["damage"].to_i * weapon["range"].to_i * weapon["spread"].to_i * damage_count
	)

	weapon
end.group_by { |c| c["_rank"] }.compact

limb_components = componentize_table("limb_cache.csv").map do |limb|
	weight = limb["weight"].to_i > 0 ? limb["weight"].to_i : 1

	# computed properties
	limb["raw_power"] = (
		limb["armor"].to_i * limb["resilience"].to_i / weight
	)

	limb
end.group_by { |c| c["_rank"] }.compact

# weapon analysis results
weapon_components.keys.sort.each do |rank|
	weapons_of_rank = weapon_components[rank]
	weapon_analysis = analyze_collection(
		weapons_of_rank,
		["raw_power", "damage", "range", "spread"]
	)

	puts "### WEP, rank #{rank} ###\n\n"

	log_stats(
		weapon_analysis,
		["raw_power"]
	)

	weapons_of_rank.each do |weapon|
		log_outliers(
			weapon,
			weapon_analysis,
			["raw_power", "damage", "range", "spread"]
		)
	end
end

# limb analysis results
limb_components.keys.sort.each do |rank|
	limbs_of_rank = limb_components[rank]
	limb_analysis = analyze_collection(
		limbs_of_rank,
		["raw_power", "armor", "resilience", "weight"]
	)

	puts "### LMB, rank #{rank} ###\n\n"

	log_stats(
		limb_analysis,
		["raw_power"]
	)

	limbs_of_rank.each do |limb|
		log_outliers(
			limb,
			limb_analysis,
			["raw_power", "armor", "resilience", "weight"]
		)
	end
end
