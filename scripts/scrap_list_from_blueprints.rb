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

one_offs = scrap_count_from_blueprints.select { |k, v| v == 1 }
# most_common = scrap_count_from_blueprints.select { |k, v| .mean }

puts "All scraps w/ counts:".light_red
scrap_count_from_blueprints.sort.each { |k, v| puts "=> #{k}: #{v.to_i}" }
puts "Total scrap #: #{scrap_count_from_blueprints.count}".light_black
puts "Avg recidivism: #{(scrap_list_from_blueprints.length.to_f / scrap_count_from_blueprints.length).round(2)}".light_black
puts "All one-offs:".light_red
puts one_offs.keys.sort.join ", "
puts "% one offs: #{one_offs.count.to_f / scrap_count_from_blueprints.count.to_f}".light_black
