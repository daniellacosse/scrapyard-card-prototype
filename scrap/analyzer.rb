require "csv"
require "../util"

blueprint_results = CSV.read("../blueprint/results.csv")
scraps = CSV.read("cache.csv")

scraps.shift

total_polymers = total_alloys = total_ceramics = 0
total_common = total_uncommon = total_rare = 0
total = 0

scraps.each do |row|
	name, rarity, polymers, alloys, ceramics = *row
	polymers ||= 0; alloys ||= 0; ceramics ||= 0
	next if row.compact.count == 0

	row_of_count = blueprint_results.index { |res_row| res_row.first == name }
	next unless row_of_count

	count = blueprint_results[row_of_count].last.to_i
	total += count

	case rarity
	when "*"
		total_common += count
	when "**"
		total_uncommon += count
	when "***"
		total_rare += count
	end

	total_polymers += polymers.to_i * count
	total_alloys += alloys.to_i * count
	total_ceramics += ceramics.to_i * count
end

total_materials = total_polymers + total_alloys + total_ceramics

puts ""
puts "> Total polymers: #{total_polymers} (#{percent(total_polymers, total_materials)})"
puts "> Total alloys: #{total_alloys} (#{percent(total_alloys, total_materials)})"
puts "> Total ceramics: #{total_ceramics} (#{percent(total_ceramics, total_materials)})"

puts ""
puts "> Common count: #{total_common} (#{percent(total_common, total)})"
puts "> Uncommon count: #{total_uncommon} (#{percent(total_uncommon, total)})"
# puts "> Rare count: #{total_rare} (#{percent(total_rare, total)})"
puts ""
