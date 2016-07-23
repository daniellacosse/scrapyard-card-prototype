require "util"
require "csv"
require "colorize"
SCRAP_DECK_SIZE = 250
SCRAP_CLASSES = [
	# TBD
]

MIN_LAYER_VALUE_COEFF = 0.75
MAX_LAYER_VALUE_COEFF = 2.5
LAYER_COEFFS = [0, 1, 2, 3].map do |layer|
	MIN_LAYER_VALUE_COEFF - (
		MAX_LAYER_VALUE_COEFF / (
			2 * (
			Math.cos(Math.PI * layer / 3) - 1
			)
		)
	)
end

BLUEPRINT_OPTION_COEFF = 0.5
BLUEPRINT_PERCENTILE_COEFF = 1

# (1) read from google spreadsheets
open_gsheet "../mastersheets/master_blueprint_sheet.gsheet", "blueprint/cache.csv"
open_gsheet "../mastersheets/master_scrap_sheet.gsheet", "scrap/cache.csv"

blueprints = CSV.read "blueprints/cache.csv"
blueprint_properties = blueprints.shift + ["rq1_buyout", "rq2_buyout", "rq3_buyout", "rq4_buyout", "rq5_buyout"]
blueprints.hash_rows! blueprint_properties

scraps = CSV.read "scrap/cache.csv"
scrap_properties = scraps.shift + ["layer", "value"]
scraps.hash_rows! scrap_properties

# (2) count up the scraps used in blueprint recepies and
# => weight the number of copies based on their frequency
scrap_list_from_blueprints = blueprints.map do |row|
	sub_row
    .compact # remove empty cells
    .map { |str| str.split(/\n|, /) }
    .flatten
end.flatten

scrap_count_from_blueprints = {}.tap do |_scfb|
	scrap_list_from_blueprints.each do |scrap_name|
		count = scrap_name[/\s+\((\d)\)$/, 1]
		count ||= 1
		count = count.to_f
		scrap_name = scrap_name.gsub(/\s+\(\d\)$/, "")

		if !!_scfb[scrap_name]
			_scfb[scrap_name] += count || 1
		else
			_scfb[scrap_name] = count || 1.0
		end
	end
end

scrap_importance_from_blueprints = {}.tap do |_sifb|
  scraps.each do |scrap|
    scrap_count = scrap_count_from_blueprints[scrap["name"]]

    next unless !!scrap_count

    _sifb[scrap["name"]] = scrap["classes"].split(", ")
      .map { |class_name| _scfb[:aggreggates]["[#{class_name}]"] }
      .compact
      .mean * scrap_count
  end
end

weighted_scrap_counts = {}.tap do |_wsc|
  scrap_count_from_blueprints[:aggreggates].keys.each do |scrap_name|
    scrap_importance = scrap_importance_from_blueprints[scrap_name]

    next unless !!scrap_importance

    _wsc[scrap_name] = (
      SCRAP_DECK_SIZE *
      scrap_importance[scrap_name] /
      scrap_importance_from_blueprints.values.sum
    ).ceil
  end
end

scrap_count_skews = weighted_scrap_counts.values.map do |count|
  (count.to_i - weighted_scrap_counts.values.mean) / weighted_scrap_counts.values.standard_deviation
end

skew_min, skew_max = scrap_count_skews.min.round, scrap_count_skews.max.round

weighted_scrap_count_skews = scrap_count_skews.map do |skew|
	raw_weight = -1 + 2 * (skew - skew_min) / (skew_max - skew_min)

	if raw_weight < -1
		return -1
	elsif raw_weight > 1
		return 1
	end

	raw_weight
end

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
			classes = scrap["classes"].split(", ")
			value = (LAYER_COEFFS[layer] * classes.count / current_scrap_count).ceil

			__scrap_and_class_values[scrap["name"]] << value
			classes.each { |c| __scrap_and_class_values[c] << value }

			# push in the new card, prop-by-prop
			scrap_properties.each do |key|
				if key is "layer"
					scrap_cards[key] << layer
				elsif key is "value"
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
scaled_median_option_values = lambda do |string|
	options = string.split("\n").map { |option| option.split ", " }
	options.map! do |option|

	end
end

blueprint_median_option_values = {}.tap do |_bmov|
	blueprints.each do |blueprint|
		blueprint_requirements = [].tap do |_br|
			5.times do |rq_number|
				_br << blueprint["rq#{rq_number + 1}"]
			end.compact
		end

		_bmov[blueprint["name"]] = blueprint_requirements.map scaled_median_option_values
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
			option_value * (percentile * BLUEPRINT_PERCENTILE_COEFF + 0.5)
		end
	end
end

# (7)
blueprint_cards = {}.tap do |_bc|
  blueprint_properties.each { |property| _bc[property] = [] }

	blueprints.each do |blueprint|
		option_values = blueprint_option_values_by_percentile[blueprint["name"]]

		blueprint_properties.each do |property|
			_bc[property] << blueprint[property]

			option_values.each_with_index do |option, index|
				_bc["rq#{index + 1}"] << option
			end
		end
	end
end

# (8) write cards to CSV!
CSV.open("scraps/cards.csv", "wb") do |sc_csv|
	__total_scrap_count.times do |row_number|
		sc_csv << [].tap do |csv_row|
			scrap_properties.each do |property|
				csv_row << scrap_card[property][row_number]
			end
		end
	end
end

CSV.open("blueprints/cards.csv", "wb") do |bp_csv|
	blueprints.count.times do |row_number|
		sc_csv << [].tap do |csv_row|
			blueprint_properties.each do |property|
				csv_row << blueprint_card[property][row_number]
			end
		end
	end
end
