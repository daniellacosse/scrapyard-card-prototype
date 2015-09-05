require "prawn"
require "../util"
require "ruby-progressbar"
include Prawn

BPRINT_ROW_SIZE = 3
BPRINT_COL_SIZE = 3
BPRINT_FRONTS = "../blueprint/_output/bprint_"
BPRINT_BACKS = "../component/_output/comp_"
BPRINT_COUNT = Dir["../component/_output/*"].length

SCRAP_ROW_SIZE = 4
SCRAP_COL_SIZE = 5
SCRAP_FRONTS = "../scrap/_output/scrap_"
SCRAP_BACKS = "../scrap/_output/scrap_back_"
SCRAP_COUNT = Dir["../scrap/_output/*"].length / 2

pages = ProgressBar.create(
	title: "Pages",
	total: [
		(BPRINT_COUNT.to_f / (BPRINT_ROW_SIZE * BPRINT_COL_SIZE)).ceil * 2,
		(SCRAP_COUNT.to_f / (SCRAP_ROW_SIZE * SCRAP_COL_SIZE)).ceil * 2,
		1
	].inject(:+)
)

def dbl_digits(int)
	(int <= 9) ? "0#{int}" : int
end

Document.generate "decks.pdf", margin: 0 do |pdf|
	pages.increment

	# blueprints
	sets_printed = 0
	until sets_printed * BPRINT_ROW_SIZE * BPRINT_COL_SIZE > BPRINT_COUNT
		sets_printed_count = sets_printed * BPRINT_ROW_SIZE * BPRINT_COL_SIZE

		BPRINT_ROW_SIZE.times do |i|
			BPRINT_COL_SIZE.times do |j|
				current_card = dbl_digits(
					sets_printed_count + (i * BPRINT_ROW_SIZE + j)
				)

				next if current_card.to_i >= BPRINT_COUNT

				pdf.image(
					"#{BPRINT_FRONTS}#{current_card}.png",
					{
						width: 2.5.inches,
						at: [
							(8.5 - (i + 1) * 2.5), # x - right to left placement
							(11 - j * 3.5)		     # y
						].inches
					}
				)
			end
		end

		pdf.start_new_page
		pages.increment

		BPRINT_ROW_SIZE.times do |i|
			BPRINT_COL_SIZE.times do |j|
				current_card = dbl_digits(
					 sets_printed_count + (i * BPRINT_ROW_SIZE + j)
				)

				next if current_card.to_i >= BPRINT_COUNT

				pdf.image(
					"#{BPRINT_BACKS}#{current_card}.png",
					{
						width: 2.5.inches,
						at: [
							(i * 2.5), 		# x - left to right placement
							(11 - j * 3.5) # y
						].inches
					}
				)
			end
		end

		sets_printed += 1
		pdf.start_new_page
		pages.increment
	end

	# scraps (could be refactored but what's the point really)
	sets_printed = 0
	until sets_printed * SCRAP_ROW_SIZE * SCRAP_COL_SIZE > SCRAP_COUNT
		sets_printed_count = sets_printed * SCRAP_ROW_SIZE * SCRAP_COL_SIZE

		SCRAP_ROW_SIZE.times do |i|
			SCRAP_COL_SIZE.times do |j|
				current_card = dbl_digits(
					sets_printed_count + (i * SCRAP_ROW_SIZE + j)
				)

				next if current_card.to_i >= SCRAP_COUNT

				pdf.image(
					"#{SCRAP_FRONTS}#{current_card}.png",
					{
						width: 2.inches,
						at: [
							(8.5 - (i + 1) * 2), # x - right to left placement
							(11 - j * 2)		   # y
						].inches
					}
				)
			end
		end

		pdf.start_new_page
		pages.increment

		SCRAP_ROW_SIZE.times do |i|
			SCRAP_COL_SIZE.times do |j|
				current_card = dbl_digits(
					 sets_printed_count + (i * SCRAP_ROW_SIZE + j)
				)

				next if current_card.to_i >= SCRAP_COUNT

				pdf.image(
					"#{SCRAP_BACKS}#{current_card}.png",
					{
						width: 2.inches,
						at: [
							(i * 2),     # x - left to right placement
							(11 - j * 2) # y
						].inches
					}
				)
			end
		end

		sets_printed += 1
		pdf.start_new_page
		pages.increment
	end

	puts "Done. Made #{pdf.page_count} pages. Writing to file (I guess)..."
end
