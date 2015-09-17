require "csv"
require "colorize"
require "../util"

ID_IDX, NAME_IDX, RANK_IDX, TYPE_IDX, ARMOR_IDX, RES_IDX, SPEED_IDX,
EFFECT_IDX, DIG_IDX, FLY_IDX, HAS_WEP_IDX,
WEP_TYPE_IDX, WEP_DMG_IDX, WEP_ELEM_IDX, WEP_ACC_IDX = *(0..14)

components = CSV.read("cache.csv")
components.shift

components_by_rank = components.group_by { |row| row[RANK_IDX] };
components_by_type = components.group_by { |row| row[TYPE_IDX] };

def stats_for(group, idx)
	collection = group.map { |row| if_truthy(row[idx]) { row[idx] } }.compact

	"#{collection.mean.round(2)} / #{collection.standard_deviation.round(2).to_s.light_black}"
end

def log_weapon_element_counts(weapons)
	corro_weps = incin_weps = elec_weps = 0
	weapons.each do |wep|
		wep_elem = wep[WEP_ELEM_IDX];

		corro_weps += 1 if wep_elem =~ /Corro/
		elec_weps += 1 if wep_elem =~ /Elec/
		incin_weps += 1 if wep_elem =~ /Incin/
	end

	total_elemental = corro_weps + elec_weps + incin_weps
	puts "=> => elemental #{total_elemental} (#{percent(total_elemental, weapons.count)})"
	puts "=> => => corrosive   #{corro_weps} (#{percent(corro_weps, weapons.count)})"
	puts "=> => => electrical  #{elec_weps} (#{percent(elec_weps, weapons.count)})"
	puts "=> => => inflamatory #{incin_weps} (#{percent(incin_weps, weapons.count)})"
end

def log_analytics_for_component_group(msg, components, total)
	puts "-- #{msg} --".light_black
	puts "> # of components: #{components.length} (#{percent(components.count, total)})".light_white
	puts "> attributes    (avg / stdev):".light_white
	puts "=> armor        #{stats_for(components, ARMOR_IDX)}"
	puts "=> speed        #{stats_for(components, SPEED_IDX)}"

	digging_count = components.select { |row| row[DIG_IDX] === "TRUE" }.count
	flying_count = components.select { |row| row[FLY_IDX] === "TRUE" }.count

	puts "=> digging      #{digging_count} (#{percent(digging_count, total)})"
	puts "=> flying       #{flying_count} (#{percent(flying_count, total)})"
	puts "=> res     #{stats_for(components, RES_IDX)}"

	# TODO: element!
	weapons = components.select { |row| row[HAS_WEP_IDX] == "TRUE" }
	puts ""
	puts "> # of weapons: #{weapons.count} (#{percent(weapons.count, components.count)})".light_white
	puts "=> damage       #{stats_for(weapons, WEP_DMG_IDX)}"
	log_weapon_element_counts(weapons)

	weapons_by_type = weapons.group_by { |row| row[WEP_TYPE_IDX] }
	melee_weapons, ranged_weapons = weapons_by_type["Melee"], weapons_by_type["Ranged"]
	if !!melee_weapons
		puts ""
		puts "=> # melee:     #{melee_weapons.count} (#{percent(melee_weapons.count, weapons.count)})".light_white
		puts "=> => damage    #{stats_for(melee_weapons, WEP_DMG_IDX)}"
		log_weapon_element_counts(melee_weapons)
	end

	if !!ranged_weapons
		puts ""
		puts "=> # ranged:    #{ranged_weapons.count} (#{percent(ranged_weapons.count, weapons.count)})".light_white
		puts "=> => damage    #{stats_for(ranged_weapons, WEP_DMG_IDX)}"
		puts "=> => acc       #{stats_for(ranged_weapons, WEP_ACC_IDX)}"
		log_weapon_element_counts(ranged_weapons)
	end

	puts ""
end

components_by_rank.each do |rank, components_of_rank|
	log_analytics_for_component_group(
		"Rank <#{rank}>",
		components_of_rank,
		components.count
	)
end

components_by_type.each do |type, components_of_type|
	log_analytics_for_component_group(
		"Type <#{type}>",
		components_of_type,
		components.count
	)
end

log_analytics_for_component_group "Summary:", components, components.count
