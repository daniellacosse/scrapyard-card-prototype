require "./scripts/util"
require "ruby-progressbar"
require "csv"
require "prawn"
include Prawn

PRINTER_ERROR_Y = 0.0
PRINTER_ERROR_X = 0.0
PRINT_MARGIN = 0.125

BPRINT_COUNT = Dir["blueprint/_output/*"].length
BPRINT_ROW_SIZE, BPRINT_COL_SIZE = 3, 3

BPRINT_CARDS = CSV.read "./blueprint/cards.csv"
BPRINT_CARDS.shift

BPRINT_FRONTS = "blueprint/_output/bprint_"
BPRINT_BACKS = {
	"LMB" => "gut/_output/lmb_",
	"WPN" => "gut/_output/wpn_",
	"ADD" => "gut/_output/add_"
}

SCRAP_COUNT = Dir["scrap/_output/*"].length
SCRAP_ROW_SIZE, SCRAP_COL_SIZE = 4, 5

SCRAP_FRONTS = "scrap/_output/scrap_"
SCRAP_BACKS = "scrap/_output/scrap_back_"

PILOT_COUNT = Dir["contestant/_output/*"].length / 2
PILOT_ROW_SIZE, PILOT_COL_SIZE = 2, 2

PILOT_FRONTS = "contestant/_output/contestant_build_"
PILOT_BACKS = "contestant/_output/contestant_combat_"

pdf_progress = ProgressBar.create(
	title: "Placing Cards:", total: nil, format: "%t <%B> %a"
)

system %{mkdir sheets}
puts "\n"

debug_progress = 0
Document.generate "sheets/blueprint_sheets.pdf", margin: PRINT_MARGIN do |pdf|
	# blueprints
	sets_printed = 0
	until sets_printed * BPRINT_ROW_SIZE * BPRINT_COL_SIZE > BPRINT_COUNT
		sets_printed_count = sets_printed * BPRINT_ROW_SIZE * BPRINT_COL_SIZE

		BPRINT_ROW_SIZE.times do |i|
			BPRINT_COL_SIZE.times do |j|
				current_card = dbl_digits(
					sets_printed_count + (i * BPRINT_COL_SIZE + j)
				)

				next if current_card.to_i >= BPRINT_COUNT

				pdf.image(
					"#{BPRINT_FRONTS}#{current_card}.png",
					{
						width: 2.5.inches,
						at: [
							(8.5 - (i + 1) * 2.5), # x - right to left placement
							(11 - PRINTER_ERROR_Y - j * 3.5)		     # y
						].inches
					}
				)

				pdf_progress.increment
				debug_progress += 1
			end
		end

		pdf.start_new_page

		BPRINT_ROW_SIZE.times do |i|
			BPRINT_COL_SIZE.times do |j|
				current_card = sets_printed_count + (i * BPRINT_COL_SIZE + j)

				next if current_card.to_i >= BPRINT_COUNT

				# lookup current card type from blueprint cards.csv
				current_type_id = dbl_digits(BPRINT_CARDS[current_card][0].to_i - 1)
				current_type = BPRINT_CARDS[current_card][1]

				pdf.image(
					"#{BPRINT_BACKS[current_type]}#{current_type_id}.png",
					{
						width: 2.5.inches,
						at: [
							(i * 2.5 + PRINTER_ERROR_X), 		# x - left to right placement
							(11 - j * 3.5) # y
						].inches
					}
				)

				pdf_progress.increment
				debug_progress += 1
			end
		end

		sets_printed += 1
		pdf.start_new_page
	end

	puts "\nMade #{pdf.page_count} pages. Writing to file @ blueprint_sheets.pdf..."
end

Document.generate "sheets/scrap_sheets.pdf", margin: PRINT_MARGIN do |pdf|
	# scraps (could be refactored but what's the point really)
	sets_printed = 0
	until sets_printed * SCRAP_ROW_SIZE * SCRAP_COL_SIZE > SCRAP_COUNT / 2
		sets_printed_count = sets_printed * SCRAP_ROW_SIZE * SCRAP_COL_SIZE

		SCRAP_ROW_SIZE.times do |i|
			SCRAP_COL_SIZE.times do |j|
				current_card = dbl_digits(
					sets_printed_count + (i * SCRAP_COL_SIZE + j)
				)

				next if current_card.to_i >= SCRAP_COUNT / 2

				pdf.image(
					"#{SCRAP_FRONTS}#{current_card}.png",
					{
						width: 2.inches,
						at: [
							(8.5 - (i + 1) * 2), # x - right to left placement
							(11 - PRINTER_ERROR_Y - j * 2)		   # y
						].inches
					}
				)

				# pdf.text_box current_card.to_s, at: [
				# 	(8.5 - (i + 1) * 2), # x - right to left placement
				# 	(11 - j * 2)		   # y
				# ].inches

				pdf_progress.increment
				debug_progress += 1
			end
		end

		pdf.start_new_page

		SCRAP_ROW_SIZE.times do |i|
			SCRAP_COL_SIZE.times do |j|
				current_card = dbl_digits(
					 sets_printed_count + (i * SCRAP_COL_SIZE + j)
				)

				# puts current_card

				next if current_card.to_i >= SCRAP_COUNT / 2

				pdf.image(
					"#{SCRAP_BACKS}#{current_card}.png",
					{
						width: 2.inches,
						at: [
							(i * 2 + PRINTER_ERROR_X),    # x - left to right placement
							(11 - j * 2) # y
						].inches
					}
				)

				# pdf.text_box current_card.to_s, at: [
				# 	(i * 2),     # x - left to right placement
				# 	(11 - j * 2) # y
				# ].inches

				pdf_progress.increment
				debug_progress += 1
			end
		end

		sets_printed += 1
		pdf.start_new_page
	end

	puts "\nMade #{pdf.page_count} pages. Writing to file @ scrap_sheets.pdf..."
end

Document.generate "sheets/contestant_sheets.pdf", margin: PRINT_MARGIN do |pdf|
	sets_printed = 0
	until sets_printed * PILOT_ROW_SIZE * PILOT_COL_SIZE > 6
		sets_printed_count = sets_printed * PILOT_ROW_SIZE * PILOT_COL_SIZE

		PILOT_ROW_SIZE.times do |i|
			PILOT_COL_SIZE.times do |j|
				current_card = dbl_digits(
					 sets_printed_count + (i * PILOT_COL_SIZE + j)
				)
				next if current_card.to_i >= PILOT_COUNT

				pdf.image(
					"#{PILOT_FRONTS}#{current_card}.png",
					{
						width: 3.inches,
						at: [
							(8.5 - (i + 1) * 3), # x - right to left placement
							(11 - PRINTER_ERROR_Y - j * 4)		     # y
						].inches
					}
				)

				pdf_progress.increment
				debug_progress += 1
			end
		end

		pdf.start_new_page

		PILOT_ROW_SIZE.times do |i|
			PILOT_COL_SIZE.times do |j|
				current_card = dbl_digits(
					 sets_printed_count + (i * PILOT_COL_SIZE + j)
				)
				next if current_card.to_i >= PILOT_COUNT

				pdf.image(
					"#{PILOT_BACKS}#{current_card}.png",
					{
						width: 3.inches,
						at: [
							(i * 3 + PRINTER_ERROR_X), 		# x - left to right placement
							(11 - j * 4) # y
						].inches
					}
				)

				pdf_progress.increment
				debug_progress += 1
			end
		end

		sets_printed += 1
		pdf.start_new_page
	end

	# puts "#{debug_progress}"
	puts "\nMade #{pdf.page_count} pages. Writing to file @ pilot_sheets.pdf..."
end

system %{open sheets}
