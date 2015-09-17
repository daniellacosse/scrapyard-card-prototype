require "prawn"
require "./util"
require "ruby-progressbar"
include Prawn

BPRINT_ROW_SIZE, BPRINT_COL_SIZE = 3, 3
BPRINT_FRONTS = "blueprint/_output/bprint_"
BPRINT_BACKS = "component/_output/comp_"
BPRINT_COUNT = Dir["component/_output/*"].length

SCRAP_ROW_SIZE, SCRAP_COL_SIZE = 4, 5
SCRAP_FRONTS = "scrap/_output/scrap_"
SCRAP_BACKS = "scrap/_output/scrap_back_"
SCRAP_COUNT = Dir["scrap/_output/*"].length

PILOT_ROW_SIZE, PILOT_COL_SIZE = 3, 2
PILOT_FRONTS = "pilots/pilot_"
PILOT_COUNT = Dir["pilots/*"].length

PRINTER_ERROR_Y = 0.0
PRINTER_ERROR_X = 0.125

pdf_progress = ProgressBar.create(
	title: "Placing Cards:", total: nil, format: "%t <%B> %a"
)

debug_progress = 0
Document.generate "blueprint_sheets.pdf", margin: 0 do |pdf|
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
				current_card = dbl_digits(
					 sets_printed_count + (i * BPRINT_COL_SIZE + j)
				)

				next if current_card.to_i >= BPRINT_COUNT

				pdf.image(
					"#{BPRINT_BACKS}#{current_card}.png",
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

	puts "Made #{pdf.page_count} pages. Writing to file @ blueprint_sheets.pdf..."
end

Document.generate "scrap_sheets.pdf", margin: 0 do |pdf|
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

	puts "Made #{pdf.page_count} pages. Writing to file @ scrap_sheets.pdf..."
end

Document.generate "pilot_sheets.pdf", margin: 0 do |pdf|
	PILOT_ROW_SIZE.times do |i|
		PILOT_COL_SIZE.times do |j|
			current_card = dbl_digits i * PILOT_COL_SIZE + j
			next if current_card.to_i >= PILOT_COUNT

			pdf.image(
				"#{PILOT_FRONTS}#{current_card}.png",
				{
					width: 2.5.inches,
					at: [(i * 2.5) + 0.5, (10.5 - j * 3.72)].inches
				}
			)

			pdf_progress.increment
			debug_progress += 1
		end
	end
	# puts "#{debug_progress}"
	puts "Made #{pdf.page_count} pages. Writing to file @ pilot_sheets.pdf..."
end

system %{open deck_sheets.pdf}
