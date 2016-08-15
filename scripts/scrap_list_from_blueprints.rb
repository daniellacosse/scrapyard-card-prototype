require "./util"
require "colorize"

open_gsheet "../mastersheets/master_blueprint_sheet.gsheet", "../blueprint/cache.csv"

blueprints = CSV.read "../blueprint/cache.csv"
blueprint_properties = blueprints.shift + ["rq1_buyout", "rq2_buyout", "rq3_buyout", "rq4_buyout", "rq5_buyout"]
blueprints.hash_rows! blueprint_properties

scrap_list_from_blueprints = blueprints.map do |row|
	[
		row["rq1"], row["rq2"], row["rq3"], row["rq4"], row["rq5"]
	].compact # remove empty cells
    .map { |str| str.split(/\n|, /) }
    .flatten
end.flatten

scrap_count_from_blueprints = {}.tap do |_scfb|
	scrap_list_from_blueprints.each do |scrap_name|
		next if scrap_name =~ /^\[/ # filter class names

		count = scrap_name[/\s+\((\d)\)$/, 1]
		count ||= 1
		count = count.to_f
		scrap_name = scrap_name.gsub(/\s+\(\d\)$/, "")

		if !!_scfb[scrap_name]
			_scfb[scrap_name] += count || 1.0
		else
			_scfb[scrap_name] = count || 1.0
		end
	end
end

scraps_grouped_by_count = Hash[
	scrap_count_from_blueprints
		.group_by {|_, v| v }
		.map {|k, v| [k, v.map(&:first).sort] }
		.sort
]

puts "---".light_black

puts "Total scrap #: #{scrap_count_from_blueprints.count}".light_black
puts "Avg recidivism: #{(scrap_list_from_blueprints.length.to_f / scrap_count_from_blueprints.length).round(2)}".light_black
puts "% one offs: #{scraps_grouped_by_count[1.0].count.to_f / scrap_count_from_blueprints.count.to_f}".light_black

puts "---".light_black

puts "All scraps w/ counts:".light_red

scraps_grouped_by_count.each do |count, scraps|
	puts "=> #{count.to_i} Count".yellow

	scraps.each { |scrap| puts "=> => #{scrap}".light_black}
end
