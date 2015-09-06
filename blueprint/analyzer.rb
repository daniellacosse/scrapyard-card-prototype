require "csv"
require "colorize"
require "../util"
SCRAP_DECK_SIZE = 340
AVERAGE_SCRAP_VALUE = 2.6

puts ""
puts "Analyzing..."
puts ""

blueprints = CSV.read "cache.csv"
blueprints.shift

scraps = CSV.read "../scrap/cache.csv"
scraps.shift

proxy_costs = []

scrap_list = blueprints.map do |row|
	sub_row = row[3..7]
	requirement_options = []

	sub_row.each do |requirement|
		option_costs = []

		requirement.split(", ").each do |option|
			ingredient_sum = 0

			option.split(/ & /).each do |option_ingredient|
				if (/Polymer|Ceramic|Alloy/ =~ option_ingredient)
					ingredient_sum += option_ingredient[/(\d) \D/, 1].to_i
				elsif (/.* \(\d\)/ =~ option_ingredient)
					ingredient_count = option_ingredient[/.* \((\d)\)/, 1].to_i
					ingredient_sum += AVERAGE_SCRAP_VALUE * ingredient_count
				else
					if_truthy option_ingredient do
						ingredient_sum += AVERAGE_SCRAP_VALUE
					end
				end
			end

			option_costs << ingredient_sum if ingredient_sum > 0
		end

		requirement_options << option_costs.mean if option_costs.count > 0
	end

	requirement_sum = requirement_options.sum
	if requirement_sum >= 20
		puts "#{'(!) High cost'.red}: #{row[1]} (#{requirement_sum} / #{(requirement_sum / AVERAGE_SCRAP_VALUE).round(2)})"
	end
	proxy_costs << requirement_sum

	sub_row.compact.map { |str| str.split(/, | & /) }.flatten.reject do |str|
		!!(/polymer|ceramic|alloy|any|\?|\-\-/i =~ str) || str.length == 0
	end
end.flatten

scrap_counts = {}.tap do |hsh|
	hsh[:agg] = [].tap do |arr|
		scrap_list.each do |str|
			count = str[/\s+\((\d)\)$/, 1]
			count ||= 1
			count = count.to_f
			str = str.gsub(/\s+\(\d\)$/, "")

			# disclude rares & events (so they can be added manually)
			scrap_index = scraps.map { |el| el.first }.index str
			next if !!scrap_index && scraps[scrap_index][1] == "***"

			word_location = arr.index { |el| str == el[:scrap] }

			if !!word_location
				arr[word_location][:number] += count || 1
			else
				arr << { scrap: str, number: count || 1.0 }
			end
		end
	end.sort { |x, y| x[:number] <=> y[:number] }

	hsh[:total] = hsh[:agg].map { |el| el[:number] }.inject(:+)
	hsh[:agg].map! do |el|
		el[:percent] = el[:number] / hsh[:total]
		el[:copies] = (el[:percent] * SCRAP_DECK_SIZE).round.to_i
		el[:copies] = 1 if el[:copies] == 0
		el
	end
end

proxy_costs.reject! { |el| el <= 2 }
puts ""
puts "> Gross blueprint cost average: #{proxy_costs.mean} (#{(proxy_costs.mean / AVERAGE_SCRAP_VALUE).round(2)})"
puts "> Gross blueprint cost standard deviation: #{proxy_costs.standard_deviation} (#{(proxy_costs.standard_deviation / AVERAGE_SCRAP_VALUE).round(2)})"

puts ""
puts "> Unique scrap count: #{scrap_counts[:agg].count}"

rounded_deck_counts = scrap_counts[:agg].map { |el| el[:copies] }
puts "> Deck size offset: #{SCRAP_DECK_SIZE - rounded_deck_counts.sum}"

deck_count_mean = rounded_deck_counts.mean
deck_count_stdev = rounded_deck_counts.standard_deviation
puts "> Card copy count average: #{deck_count_mean}"
puts "> Card copy standard deviation: #{deck_count_stdev}"

deck_count_outliers = scrap_counts[:agg].reject do |el|
	std_devs = ( el[:copies] - deck_count_mean ) / deck_count_stdev

	std_devs > -3 && std_devs < 3
end

if deck_count_outliers.length > 0
	puts ""
	puts "> Outliers:"
	puts deck_count_outliers.map { |el| "=> #{el[:scrap]} (#{el[:copies]})" }
	puts ""
end

if (SCRAP_DECK_SIZE - rounded_deck_counts.sum) != 0
	# TODO: suggest revisions
	# => remove x from the highest count
	# => then next lowest count
	# => then highest count
	# => then next lowest count
	# => then next next... and so on, until offset is ~0
end

CSV.open("results.csv", "wb") do |csv|
	scrap_counts[:agg].each { |row| csv << [row[:scrap], row[:copies]] }
end

puts "Done! Wrote results to CSV!"
puts ""
