require "./util"
require "csv"
require "colorize"
require "byebug"

include Math

SCRAP_DECK_SIZE = 160
SCRAP_CLASSES = [
	"mechanical",
	"electrical",
	"alloy",
	"polymer",
	"ceramic"
]

MIN_LAYER_VALUE_COEFF = 1
MAX_LAYER_VALUE_COEFF = 10
LAYER_VALUE_COEFF_RANGE = MAX_LAYER_VALUE_COEFF - MIN_LAYER_VALUE_COEFF

LAYER_VALUE_COEFFS = [3, 2, 1, 0].map do |layer|
	MIN_LAYER_VALUE_COEFF - (
		(LAYER_VALUE_COEFF_RANGE / 2) * (Math.cos(PI * layer / 4) - 1)
	)
end

BUYOUT_OPTIONALITY_COEFF = 0.6
BUYOUT_PERCENTILE_COEFF = 1.7
ADDON_TAX_COEFF = 1.85

# (1) read from google spreadsheets
open_gsheet "../mastersheets/master_blueprint_sheet.gsheet", "../blueprint/cache.csv"
open_gsheet "../mastersheets/master_scrap_sheet.gsheet", "../scrap/cache.csv"

blueprints = CSV.read "../blueprint/cache.csv"
blueprint_properties = blueprints.shift
blueprint_properties_with_buyouts = blueprint_properties + [
	"rq1_buyout", "rq2_buyout", "rq3_buyout", "rq4_buyout", "rq5_buyout"
]
blueprints.hash_rows! blueprint_properties

scraps = CSV.read "../scrap/cache.csv"
scrap_properties = scraps.shift + ["layer", "value"]
scraps.hash_rows! scrap_properties

treasures = scraps.select { |scrap| scrap["_is_treasure?"] == "y" }

# (2) count up the scraps used in blueprint recepies and
# => weight the number of copies based on their frequency
scrap_list_from_blueprints = blueprints.map do |row|
	[
		row["rq1"], row["rq2"], row["rq3"], row["rq4"], row["rq5"]
	].compact # remove empty cells
    .map { |str| str.split(/\n|, /) }
    .flatten
end.flatten

# TODO: handle no-classes edge case better
scrap_count_from_blueprints = {}.tap do |_scfb|
	scrap_list_from_blueprints.each do |scrap_name|
		count = scrap_name[/\s+\((\d)\)$/, 1]
		count ||= 1
		count = count.to_f
		scrap_name = scrap_name.gsub(/\s+\(\d\)$/, "")
		found_scrap = scraps.find { |scrap| scrap["name"] == scrap_name }

		unless found_scrap || SCRAP_CLASSES.include?(scrap_name[/\[(.+)\]/, 1])
			throw "Scrap #{scrap_name} not found. Try regenerating the scrap mastersheet."
		end

		if found_scrap
			scrap_classes = found_scrap["classes"].comma_split

			scrap_classes.each do |class_name|
				if !!_scfb["[#{class_name}]"]
					_scfb["[#{class_name}]"] += count || 1.0
				else
					_scfb["[#{class_name}]"] = count || 1.0
				end
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

		scrap_classes = scrap["classes"].comma_split
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

	treasures.each do |treasure|
		_wsc[treasure["name"]] = treasure["_count_override"].to_i
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
		result = nil

		if raw_weight < -1
			result = [scrap_name, -1]
		elsif raw_weight > 1
			result = [scrap_name, 1]
		else
			result = [scrap_name, raw_weight]
		end

		result
	end
]

# (4) build out the final set of scrap cards,
# => which includes their procedurally assigned layer && monetary value
scrap_cards = {}.tap do |_sc|
  scrap_properties.each { |property| _sc[property] = [] }
end

__layer_counts = Hash.new(0)
__scrap_and_class_values = {}
__scrap_values_only = {}
__scrap_layers_by_name = {}
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

			classes = scrap["classes"].comma_split

			# determine card layer
			if scrap["_is_treasure?"] == "y"
				layer = 0
				__layer_counts[0] += 1
			else
				layer = layer_distribution.find_index do |layer_percent|
					(card_number.to_f / current_scrap_count) <= layer_percent
				end

				layer += 1 if layer != 3 and __layer_counts[layer + 1] <= __layer_counts[layer]

				__layer_counts[layer] += 1
			end

			# determine card value
			if scrap["_value_override"]
				value = scrap["_value_override"].to_i
			else
				value = (
					LAYER_VALUE_COEFFS[layer] * (classes.count + 1) / current_scrap_count
				).ceil
			end

			# (save card value for later)
			if !!__scrap_and_class_values[scrap["name"]]
				__scrap_and_class_values[scrap["name"]] << value
				__scrap_values_only[scrap["name"]] << value
			else
				__scrap_and_class_values[scrap["name"]] = [ value ]
				__scrap_values_only[scrap["name"]] = [ value ]
			end

			classes.each do |class_name|
				if !!__scrap_and_class_values["[#{class_name}]"]
					__scrap_and_class_values["[#{class_name}]"] << value
				else
					__scrap_and_class_values["[#{class_name}]"] = [ value ]
				end
			end

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
# => (1 + BUYOUT_OPTIONALITY_COEFF ** option_count-1)
average_scrap_value = __scrap_values_only.values.flatten.mean.round(2)
scaled_max_option_values = lambda do |string|
	options = string.split("\n").map { |option| option.comma_split }
	max_option_ingredient_count = 0

	options.map! do |option|
		option_ingredient_count = 0

		option_sum = option.map do |ingredient|
			ingredient_name = ingredient[/^[a-zA-Z \[\]\-]+/].strip
			ingredient_count = ingredient[/\s+\((\d)\)$/, 1].to_i
			ingredient_count = 1 if ingredient_count == 0

			option_ingredient_count += ingredient_count

			__scrap_and_class_values[ingredient_name].median * ingredient_count
		end

		if option_ingredient_count > max_option_ingredient_count
			max_option_ingredient_count = option_ingredient_count
		end

		option_sum.inject(:+)
	end

	raw_option_value = options.max * (1 + BUYOUT_OPTIONALITY_COEFF ** (options.count - 1))
	min_option_value = max_option_ingredient_count * average_scrap_value

	if raw_option_value < min_option_value
		return min_option_value
	else
		return raw_option_value
	end
end

blueprint_median_option_values = {}.tap do |_bmov|
	blueprints.each do |blueprint|
		blueprint_requirements = [].tap do |_br|
			5.times do |rq_number|
				_br << blueprint["rq#{rq_number + 1}"]
			end
		end.compact

		_bmov[blueprint["name"]] = blueprint_requirements.map( &scaled_max_option_values)
	end
end

# (6) remap all option costs by the percentile of their blueprint's
# => overall cost * BUYOUT_PERCENTILE_COEFF + 1/2
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
			coeff = BUYOUT_PERCENTILE_COEFF
			coeff *= ADDON_TAX_COEFF if blueprint["type"] == "ADD"

			if_truthy(blueprint["_tax"]) { coeff *= blueprint["_tax"].to_f }

			(option_value * (percentile * coeff + 0.5)).round
		end
	end
end

# (7) build out final set of blueprint cards!
blueprint_cards = {}.tap do |_bc|
  blueprint_properties_with_buyouts.each { |property| _bc[property] = [] }

	blueprints.each do |blueprint|
		option_values = blueprint_option_values_by_percentile[blueprint["name"]]

		blueprint_properties.each do |property|
			_bc[property] << blueprint[property]
		end

		5.times do |index|
			_bc["rq#{index + 1}_buyout"] << option_values[index]
		end
	end
end

# (7.1) log results TODO: outliers [add to util]
puts "Total Scraps: #{__total_scrap_count}".light_red.underline
puts "Scrap Count Error: #{(1 - (__total_scrap_count.to_f / SCRAP_DECK_SIZE)).round(2)}".red
puts "Avg. Scrap Value: #{__scrap_values_only.values.flatten.mean.round(2)}".red
puts "Std dev. Scrap Value: #{__scrap_values_only.values.flatten.standard_deviation.round(2)}".red
puts "Highest Scrap Value: #{__scrap_values_only.values.flatten.max}".red

puts "Scraps per layer:".light_green.underline
__layer_counts.sort.each do |layer, count|
	puts "=> Layer #{layer + 1}: #{count} (#{(count.to_f/__total_scrap_count*100).round(2)}%)".green
end
puts "Scrap value by class:".light_yellow.underline
SCRAP_CLASSES.each do |class_name|
	puts "=> #{class_name}\t #{__scrap_and_class_values["[#{class_name}]"].count}".light_yellow
	puts "=> => mean value: \t#{__scrap_and_class_values["[#{class_name}]"].mean.round(2)}".yellow
	puts "=> => std dev: \t\t#{__scrap_and_class_values["[#{class_name}]"].standard_deviation.round(2)}".yellow
end

# BLUEPRINT ANALYSIS
blueprint_costs = blueprint_option_values_by_percentile.values.map {|o| o.inject(:+)}.compact
blueprint_average = blueprint_costs.mean.round(2)
blueprint_std_dev = blueprint_costs.standard_deviation.round(2)

blueprint_min = blueprint_option_values_by_percentile.min_by { |k, v| v.sum }
cheapest_blueprints = blueprint_option_values_by_percentile.select do |k, v|
	total_value = v.inject(:+)

	next unless total_value

	total_value <= blueprint_average - blueprint_std_dev * 2.5
end

blueprint_max = blueprint_option_values_by_percentile.max_by { |k, v| v.sum }
costliest_blueprints = blueprint_option_values_by_percentile.select do |k, v|
	total_value = v.inject(:+)

	next unless total_value

	total_value >= blueprint_average + blueprint_std_dev * 2.5
end

puts "---".light_blue
puts "Average Blueprint cost: \t\t#{blueprint_average}".light_blue
puts "Average Blueprint standard_deviation: \t#{blueprint_std_dev}".blue

if cheapest_blueprints.length == 0
	puts "Least Expensive Blueprint: #{blueprint_min.first.to_s.downcase} (#{blueprint_min.last.sum})".light_blue
else
	puts "Cheapest Blueprints: (#{cheapest_blueprints.length})".light_blue

	cheapest_blueprints.each do |k, v|
		puts "=> #{k.downcase}: #{v.join(', ')} (#{v.sum})".blue
	end
end

if costliest_blueprints.length == 0
	puts "Most Expensive Blueprint: #{blueprint_max.first.to_s.downcase} (#{blueprint_max.last.sum})".light_blue
else
	puts "Costliest Blueprints: (#{costliest_blueprints.length})".light_blue

	costliest_blueprints.each do |k, v|
		puts "=> #{k.downcase}: #{v.join(', ')} (#{v.sum})".blue
	end
end


# (8) write final cards to CSV for printing w/ squib!
CSV.open("../scrap/cards.csv", "wb") do |sc_csv|
	sc_csv << scrap_properties

	__total_scrap_count.times do |row_number|
		sc_csv << [].tap do |csv_row|
			scrap_properties.each do |property|
				csv_row << scrap_cards[property][row_number]
			end
		end
	end
end

CSV.open("../blueprint/cards.csv", "wb") do |bp_csv|
	bp_csv << blueprint_properties_with_buyouts

	blueprints.count.times do |row_number|
		bp_csv << [].tap do |csv_row|
			blueprint_properties_with_buyouts.each do |property|
				csv_row << blueprint_cards[property][row_number]
			end
		end
	end
end
