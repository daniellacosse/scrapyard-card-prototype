require "./util"
require "csv"
require "colorize"

include Math

SCRAP_DECK_SIZE = 250
SCRAP_CLASSES = [
	"mechanical",
	"electrical",
	"metal",
	"polymer",
	"ceramic"
]

MIN_LAYER_VALUE_COEFF = 0.75
MAX_LAYER_VALUE_COEFF = 2.5

# TODO: not quite right, doesn't stay between min & max
LAYER_COEFFS = [4, 3, 2, 1].map do |layer|
	MIN_LAYER_VALUE_COEFF - (
		MAX_LAYER_VALUE_COEFF / (
			2 * (Math.cos(PI * layer / 4) - 1)
		)
	)
end

BLUEPRINT_OPTION_COEFF = 0.5
BLUEPRINT_PERCENTILE_COEFF = 1

# (1) read from google spreadsheets
open_gsheet "../mastersheets/master_blueprint_sheet.gsheet", "../blueprint/cache.csv"
open_gsheet "../mastersheets/master_scrap_sheet.gsheet", "../scrap/cache.csv"

blueprints = CSV.read "../blueprint/cache.csv"
blueprint_properties = blueprints.shift + ["rq1_buyout", "rq2_buyout", "rq3_buyout", "rq4_buyout", "rq5_buyout"]
blueprints.hash_rows! blueprint_properties

scraps = CSV.read "../scrap/cache.csv"
scrap_properties = scraps.shift + ["layer", "value"]
scraps.hash_rows! scrap_properties

# (2) count up the scraps used in blueprint recepies and
# => weight the number of copies based on their frequency
scrap_list_from_blueprints = blueprints.map do |row|
	[
		row["rq1"], row["rq2"], row["rq3"], row["rq4"], row["rq5"]
	].compact # remove empty cells
    .map { |str| str.split(/\n|, /) }
    .flatten
end.flatten

# TODO: handle no-classes edge case well
scrap_count_from_blueprints = {}.tap do |_scfb|
	scrap_list_from_blueprints.each do |scrap_name|
		count = scrap_name[/\s+\((\d)\)$/, 1]
		count ||= 1
		count = count.to_f
		scrap_name = scrap_name.gsub(/\s+\(\d\)$/, "")
		scrap_classes = (scraps.find { |scrap| scrap["name"] == scrap_name }["classes"] || "").split(", ")

		scrap_classes.each do |class_name|
			if !!_scfb["[#{class_name}]"]
				_scfb["[#{class_name}]"] += count || 1.0
			else
				_scfb["[#{class_name}]"] = count || 1.0
			end
		end

		if !!_scfb[scrap_name]
			_scfb[scrap_name] += count || 1.0
		else
			_scfb[scrap_name] = count || 1.0
		end
	end
end

scrap_importance_from_blueprints = {}.tap do |_sifb|
  scraps.each do |scrap|
    scrap_count = scrap_count_from_blueprints[scrap["name"]]

    next unless !!scrap_count

		scrap_classes = (scrap["classes"] || "").split(", ")
		class_counts = scrap_classes.map do |class_name|
			scrap_count_from_blueprints["[#{class_name}]"]
		end.compact

		if class_counts.length > 0
			_sifb[scrap["name"]] = class_counts.mean * scrap_count
		else
			_sifb[scrap["name"]] = scrap_count
		end
  end
end

weighted_scrap_counts = {}.tap do |_wsc|
  scrap_count_from_blueprints.keys.each do |scrap_name|
    scrap_importance = scrap_importance_from_blueprints[scrap_name]

    next unless !!scrap_importance

    _wsc[scrap_name] = (
      SCRAP_DECK_SIZE *
      scrap_importance / scrap_importance_from_blueprints.values.sum
    ).ceil
  end
end

__weighted_scrap_count_mean = weighted_scrap_counts.values.mean
__weighted_scrap_count_std_dev = weighted_scrap_counts.values.standard_deviation
scrap_count_skews = Hash[
	weighted_scrap_counts.map do |scrap_name, count|
	  [
			scrap_name,
			(count - __weighted_scrap_count_mean) / __weighted_scrap_count_std_dev
		]
	end
]

skew_min, skew_max = scrap_count_skews.values.min.round, scrap_count_skews.values.max.round
weighted_scrap_count_skews = Hash[
	scrap_count_skews.map do |scrap_name, skew|
		raw_weight = -1 + 2 * (skew - skew_min) / (skew_max - skew_min)

		if raw_weight < -1
			return [scrap_name, -1]
		elsif raw_weight > 1
			return [scrap_name, 1]
		end

		[scrap_name, raw_weight]
	end
]

# (4) build out the final set of scrap cards,
# => which includes their procedurally assigned layer && monetary value
scrap_cards = {}.tap do |_sc|
  scrap_properties.each { |property| _sc[property] = [] }
end

__layer_counts = Hash.new(0)
__scrap_and_class_values = Hash.new([])
__total_scrap_count = 0
scraps.each do |scrap|
	current_scrap_count = weighted_scrap_counts[scrap["name"]]
	current_scrap_skew = weighted_scrap_count_skews[scrap["name"]]

	if !!current_scrap_count
		# layer distribution targets:
		# ---
		# 		    L1  L2  L3   L4
		# Sk1  => 62% 87% 100% --
		# Sk0  => 25% 50% 75%  100%
		# Sk-1 => 0%  12% 37%  100%

		layer_distribution = [
			0.12 * 7.87 ** current_scrap_skew,
			0.37 * 2.69 ** current_scrap_skew,
			0.65 * 1.64 ** current_scrap_skew,
			1
		]

		current_scrap_count.times do |card_number|
			__total_scrap_count += 1

			# determine card layer
			layer = layer_distribution.select do |layer_percent|
				# TODO: (this won't work lol but good try)
				layer_percent > card_number.to_f / current_scrap_count
			end.first

			layer += 1 if layer != 3 and __layer_counts[layer + 1] <= __layer_counts[layer]

			__layer_counts[layer] += 1

			# determine card value
			classes = (scrap["classes"] || "").split(", ")
			value = (LAYER_COEFFS[layer] * (classes.count + 1) / current_scrap_count).ceil

			__scrap_and_class_values[scrap["name"]] << value
			classes.each { |c| __scrap_and_class_values[c] << value }

			# push in the new card, prop-by-prop
			scrap_properties.each do |key|
				if key == "layer"
					scrap_cards[key] << layer
				elsif key == "value"
					scrap_cards[key] << value
				else
					scrap_cards[key] << scrap[key]
				end
			end
		end
	end
end

# (5) in prep for blueprints, get median cost of each option, then the
# => median of those and multiply by
# => (1 + BLUEPRINT_OPTION_COEFF ** option_count-1)
median_ingredient_value = lambda do |ingredient_name|
	# TODO: this (doesn't matter rn b/c everything costs like 1 anyway)
	1
end

scaled_median_option_values = lambda do |string|
	options = string.split("\n").map { |option| option.split ", " }
	options.map! do |option|
		option_sum = option.map(&median_ingredient_value).inject(:+)

		option_sum
	end

	options.median * (1 + BLUEPRINT_OPTION_COEFF ** (options.count - 1))
end

blueprint_median_option_values = {}.tap do |_bmov|
	blueprints.each do |blueprint|
		blueprint_requirements = [].tap do |_br|
			5.times do |rq_number|
				_br << blueprint["rq#{rq_number + 1}"]
			end
		end.compact

		_bmov[blueprint["name"]] = blueprint_requirements.map( &scaled_median_option_values)
	end
end

# (6) remap all option costs by the percentile of their blueprint's
# => overall cost * BLUEPRINT_PERCENTILE_COEFF + 1/2
blueprint_option_values_by_percentile = {}.tap do |_bovp|
	requirement_sums = blueprint_median_option_values.values.map(&:sum)
	requirement_mean = requirement_sums.mean
	requirement_std_dev = requirement_sums.standard_deviation

	blueprints.each do |blueprint|
		option_values = blueprint_median_option_values[blueprint["name"]]
		requirement_value = option_values.sum

		percentile = get_percent_from_zscore(
			(requirement_value - requirement_mean) / requirement_std_dev
		)

		_bovp[blueprint["name"]] = option_values.map do |option_value|
			(option_value * (percentile * BLUEPRINT_PERCENTILE_COEFF + 0.5)).round
		end
	end
end

# (7) build out final set of blueprint cards!
blueprint_cards = {}.tap do |_bc|
  blueprint_properties.each { |property| _bc[property] = [] }

	blueprints.each do |blueprint|
		option_values = blueprint_option_values_by_percentile[blueprint["name"]]

		blueprint_properties.each do |property|
			_bc[property] << blueprint[property]

			option_values.each_with_index do |option, index|
				_bc["rq#{index + 1}_buyout"] << option
			end
		end
	end
end

# (8) write final cards to CSV for printing w/ squib!
CSV.open("../scrap/cards.csv", "wb") do |sc_csv|
	__total_scrap_count.times do |row_number|
		sc_csv << [].tap do |csv_row|
			scrap_properties.each do |property|
				csv_row << scrap_cards[property][row_number]
			end
		end
	end
end

CSV.open("../blueprint/cards.csv", "wb") do |bp_csv|
	blueprints.count.times do |row_number|
		bp_csv << [].tap do |csv_row|
			blueprint_properties.each do |property|
				csv_row << blueprint_cards[property][row_number]
			end
		end
	end
end
