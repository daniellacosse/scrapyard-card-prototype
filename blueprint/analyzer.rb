require "csv"
require "colorize"
require "../util"
SCRAP_DECK_SIZE = 340
AVERAGE_SCRAP_VALUE = 1

puts ""
puts "Analyzing..."
puts ""

blueprints = CSV.read "cache.csv"
blueprints.shift

scraps = CSV.read "../scrap/cache.csv"
scraps.shift

proxy_costs = []

# okay. we need to assess value across two degrees of
# freedom now; class and name.
#
# we should count up the no. of times a class is used.
# and the no. of times a scrap of a specific name is mentioned.
#
# then multiply those and get their percentage out of the whole

# (!!!) then divide those evenly amongst the levels -- rarer stuff toward
# the bottom.

# a-like so:

# layer 1: 4
# layer 2: 4
# layer 3: 3 1
# layer 4: 2 2

scrap_list = blueprints.map do |row|
	sub_row = [row[3], row[5], row[7], row[9], row[11]]
	# requirement_options = []

	# sub_row.each do |requirement|
	# 	option_costs = []
	#
	# 	requirement.split("\n").each do |option|
	# 		ingredient_sum = 0
	#
	# 		option.split(", ").each do |option_ingredient|
	# 			if (/.* \(\d\)/ =~ option_ingredient)
	# 				ingredient_count = option_ingredient[/.* \((\d)\)/, 1].to_i
	# 				ingredient_sum += AVERAGE_SCRAP_VALUE * ingredient_count
	# 			else
	# 				if_truthy option_ingredient do
	# 					ingredient_sum += AVERAGE_SCRAP_VALUE
	# 				end
	# 			end
	# 		end
	#
	# 		option_costs << ingredient_sum if ingredient_sum > 0
	# 	end
	#
	# 	requirement_options << option_costs.mean if option_costs.count > 0
	# end
	#
	# requirement_sum = requirement_options.sum
	# if requirement_sum >= 24
	# 	puts "#{'(!) High cost'.red}: #{row[1]} (#{requirement_sum} / #{(requirement_sum / AVERAGE_SCRAP_VALUE).round(2)})"
	# end
	# proxy_costs << requirement_sum

	sub_row.compact.map { |str| str.split(/\n|, /) }.flatten
end.flatten

scrap_counts = {}.tap do |hsh|
	hsh[:agg] = {}.tap do |agg|
		scrap_list.each do |str|
			count = str[/\s+\((\d)\)$/, 1]
			count ||= 1
			count = count.to_f
			str = str.gsub(/\s+\(\d\)$/, "")

			# word_location = agg.index { |el| str == el[:scrap] }

			if !!agg[str]
				agg[str][:number] += count || 1
			else
				# if class (aka [] notation) class: true
				# is_class = true if (/^\[.*\]$/ =~ str)

				agg[str] { number: count || 1.0 }
			end
		end
	end

	# hsh[:total] = hsh[:agg].map { |el| el[:number] }.inject(:+)
	# hsh[:agg].map! do |el|
	# 	el[:percent] = el[:number] / hsh[:total]
	# 	el[:copies] = (el[:percent] * SCRAP_DECK_SIZE).round.to_i
	# 	el[:copies] = 1 if el[:copies] == 0
	# 	el
	# end

	hsh[:importance_model] = {}.tap do |importance_model|
		scraps.each do |scrap|
			name = scrap[0]
			classes = scrap[1].split(", ")

			importance_model[name] = classes
				.map { |class_name| hsh[:agg][class_name][:count] }
				.mean * hsh[:agg][name][:count]
		end
	end
end

importance_sum = hsh[:importance_model].values.sum

# proxy_costs.reject! { |el| el <= 2 }
# puts ""
# puts "> Gross blueprint cost average: #{proxy_costs.mean} (#{(proxy_costs.mean / AVERAGE_SCRAP_VALUE).round(2)})"
# puts "> Gross blueprint cost standard deviation: #{proxy_costs.standard_deviation} (#{(proxy_costs.standard_deviation / AVERAGE_SCRAP_VALUE).round(2)})"
#
# puts ""
# puts "> Unique scrap count: #{scrap_counts[:agg].count}"
#
# rounded_deck_counts = scrap_counts[:agg].map { |el| el[:copies] }
# puts "> Deck size offset: #{SCRAP_DECK_SIZE - rounded_deck_counts.sum}"
#
# deck_count_mean = rounded_deck_counts.mean
# deck_count_stdev = rounded_deck_counts.standard_deviation
# puts "> Card copy count average: #{deck_count_mean}"
# puts "> Card copy standard deviation: #{deck_count_stdev}"
#
# deck_count_outliers = scrap_counts[:agg].reject do |el|
# 	std_devs = ( el[:copies] - deck_count_mean ) / deck_count_stdev
#
# 	std_devs > -3 && std_devs < 3
# end
#
# if deck_count_outliers.length > 0
# 	puts ""
# 	puts "> Outliers:"
# 	puts deck_count_outliers.map { |el| "=> #{el[:scrap]} (#{el[:copies]})" }
# 	puts ""
# end

if (SCRAP_DECK_SIZE - rounded_deck_counts.sum) != 0
	# TODO: suggest revisions
	# => remove x from the highest count
	# => then next lowest count
	# => then highest count
	# => then next lowest count
	# => then next next... and so on, until offset is ~0
end

CSV.open("results.csv", "wb") do |csv|
	scrap_counts[:agg].keys.each do |scrap_name|
		# scrap_distribution = [
		# 	# ??? (see line 30)
		# 	# or maybe this is the scrap deck's job.
		# ].join(", ")

		csv << [
			scrap_name,
			(scrap_counts[:importance_model][scrap_name] / importance_sum) * SCRAP_DECK_SIZE
		]
	end
end

puts "Wrote results to CSV!"
puts ""

def blueprint_cost(blueprint_row) {
	sub_row = blueprint_row[3..7]
	requirement_options = []

	sub_row.each do |requirement|
		option_costs = []

		requirement.split(", ").each do |option|
			option_value, option_rarity = 0, 1

			option.split(/ & /).each do |option_ingredient|
				if (/Override/ =~ option_ingredient)
					option_value += option_ingredient[/\D (\d)/, 1].to_i
				elsif (/.* \(\d\)/ =~ option_ingredient)
					# find option_ingredient
					ingredient = scrap_counts[:agg].select do |scrap|
						scrap[:name] == option_ingredient
					end.first

					ingredient_count = option_ingredient[/.* \((\d)\)/, 1].to_i
					option_value += ingredient_count * ingredient[:value]
					option_rarity *= ingredient_count * ingredient[:percent]
				else
					if_truthy option_ingredient do
						# find option_ingredient
						ingredient = scrap_counts[:agg].select do |scrap|
							scrap[:name] == option_ingredient
						end.first

						ingredient_count = option_ingredient[/.* \((\d)\)/, 1].to_i
						option_value += ingredient_count * ingredient[:value]
						option_rarity *= ingredient_count * ingredient[:percent]
					end
				end
			end

			option_costs << option_value / option_rarity
		end

		requirement_options << option_costs.mean if option_costs.count > 0
	end

	blueprint_row[:rank].to_f * Math.log(requirement_options.sum)
end
