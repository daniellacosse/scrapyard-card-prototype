require "open-uri"
require "json"
require "deep_clone"
require "csv"
require "openssl"

def open_gsheet(filepath, destination = "cache.csv")
	# (1) open gdoc
	gdoc = JSON.parse(File.read(filepath))

	# (2) pull down sheet from gdoc url
	buffer = open("https://docs.google.com/spreadsheets/d/#{gdoc['doc_id']}/export?format=csv", ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).read

	# (3) stuff into local csv
	File.open(destination, "w") { |file| file << buffer }

	# (4) return row length, for utility
	CSV.parse(buffer).length - 1
end

def if_truthy(val)
	falsies = [
		(!val), (val == 0), (val == ""), (val == "FALSE"), (val == "--"), (val == "???"), (val == "0")
	]

	falsies.any? ? nil : yield(val)
end

def percent(amount, total)
	"#{(amount.to_f / total.to_f * 100).round.to_i}%"
end

def dbl_digits(int)
	(int <= 9) ? "0#{int}" : int
end

# http://stackoverflow.com/questions/31875909/z-score-to-probability-and-vice-verse-in-ruby
def get_percent_from_zscore(z)
  return 0 if z < -6.5
  return 1 if z > 6.5

  factk = 1
  sum = 0
  term = 1
  k = 0

  loopStop = Math.exp(-23)
  while term.abs > loopStop do
      term = 0.3989422804 * ((-1)**k) * (z**k) / (2*k+1) / (2**k) * (z**(k+1)) /factk
      sum += term
      k += 1
      factk *= k
  end

  sum += 0.5
  1-sum
end

class Float
	def inches
		self * 72
	end
end

class Integer
	def inches
		self * 72
	end
end

class Array
	def truthy_count
		self.map { |el| if_truthy(el) { el } }.compact.count
	end

	def inches
		self.map &:inches
	end

	def hash_rows!(row_keys)
		self.map! do |row|
			hashed_row = {}

			row_keys.each_with_index do |key, index|
				hashed_row[key] = row[index]
			end

			hashed_row
		end
	end

	def hash_rows(row_keys)
		self.__deep_clone__.hash_rows!(row_keys)
	end
end

class Hash
	def row_map!
		# (1) create an array of row objects
		rows, row_count = [], values.first.count

		row_count.times do |i|
			rows << {}.tap do |row|
				keys.each { |key| row[key] = self[key][i] }
			end
		end

		mapped_keys = keys

		# (2) map that array with the given block
		rows.map! do |row|
			merged_row = row.merge yield(row, {})
			mapped_keys += merged_row.keys
			mapped_keys.uniq!
			merged_row
		end

		# (3) then the row keys back into a hash
		mapped_keys.each do |key|
			self[key] = rows.collect { |row| row[key] }
		end

		self
	end

	def row_map
		self.__deep_clone__.row_map! { |row| yield(row, {}) }
	end

	# def map_values!
	# 	self = self.map_values { |v| yield(v) }
	# end

	def map_values
		mapped_values = {}

		self.each { |k, v| mapped_values[k] = yield(v) }

		return mapped_values
	end

	def compact
		delete_if { |k, v| k.nil? || v.nil? }
	end
end

class String
	def comma_split
		self.split /,\s*/
	end
end

class NilClass
	def comma_split
		[]
	end
end

module Enumerable
   def sum
   	self.inject(0) { |accum, i| accum + i.to_f }
   end

   def mean
   	self.sum / self.length.to_f
   end

	 def median
		 sorted = self.sort
		 len = sorted.length
	   (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
	 end

   def sample_variance
	   m = self.mean
	   sum = self.inject(0) { |accum, i| accum + ( i.to_f - m ) ** 2 }
	   sum / ( self.length - 1 ).to_f
   end

   def standard_deviation
	   Math.sqrt self.sample_variance
   end

	 def outliers(tolerance = 2.5)
		 m = self.mean
		 std = self.standard_deviation
		 lower_bound = m - (tolerance * std)
		 upper_bound = m + (tolerance * sorted)
		 self.filter { |el| el > upper_bound || el < lower_bound  }
	 end
end
