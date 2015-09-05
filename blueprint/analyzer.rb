require "csv"
require "../util"
DECK_SIZE = 340

puts ""
puts "Analyzing..."
puts ""

blueprints = CSV.read("cache.csv")
blueprints.shift

scraps = CSV.read("scrap_cache.csv")
scraps.shift

scrap_list = blueprints.map do |row|
	sub_row = row[3..7]

	sub_row.compact.map { |str| str.split(/, | & /) }.flatten.reject do |str|
		!!(/polymer|ceramic|alloy|any|\?|\-\-/i =~ str) || str.length == 0
	end
end.flatten

# uncomment to disclude rares (so they can be added manually)
scrap_list.select! do |name|
	scrap_index = scraps.map { |el| el.first }.index name
	next if !scrap_index

	scraps[scrap_index][1] != "***"
end

scrap_counts = {}.tap do |hsh|
	hsh[:agg] = [].tap do |arr|
		scrap_list.each do |str|
			count = str[/\s+\((\d)\)$/, 1]
			count ||= 1
			count = count.to_f
			str = str.gsub(/\s+\(\d\)$/, "")

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
		el[:copies] = (el[:percent] * DECK_SIZE).round.to_i
		el[:copies] = 1 if el[:copies] == 0
		el
	end
end

puts "> Unique scrap count: #{scrap_counts[:agg].count}"

rounded_deck_counts = scrap_counts[:agg].map { |el| el[:copies] }
puts "> Deck size offset: #{DECK_SIZE - rounded_deck_counts.sum}"

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

if (DECK_SIZE - rounded_deck_counts.sum) != 0
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
