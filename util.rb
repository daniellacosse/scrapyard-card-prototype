require "open-uri"
require "json"
require "deep_clone"
require "csv"

def open_gsheet(filepath)
	# (1) open gdoc
	gdoc = JSON.parse(File.read(filepath))

	# (2) pull down sheet from gdoc url
	buffer = open("https://docs.google.com/spreadsheets/d/#{gdoc['doc_id']}/export?format=csv").read

	# (3) stuff into local csv
	File.open("cache.csv", "w") { |file| file << buffer }

	# (4) return row length, for utility
	CSV.parse(buffer).length - 1
end

def if_truthy(val)
	falsies = [
		(!val), (val == 0), (val == ""), (val == "FALSE"), (val == "--"), (val == "0")
	]

	falsies.any? ? nil : yield(val)
end

def percent(amount, total)
	"#{(amount.to_f / total.to_f * 100).round.to_i}%"
end

def dbl_digits(int)
	(int <= 9) ? "0#{int}" : int
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
		DeepClone.clone(self).row_map! { |row| yield(row, {}) }
	end

	# def map_values!
	# 	self = self.map_values { |v| yield(v) }
	# end

	def map_values
		mapped_values = {}

		self.each { |k, v| mapped_values[k] = yield(v) }

		return mapped_values
	end
end

module Enumerable
   def sum
   	self.inject(0) { |accum, i| accum + i.to_i }
   end

   def mean
   	self.sum / self.length.to_f
   end

   def sample_variance
	   m = self.mean
	   sum = self.inject(0) { |accum, i| accum + ( i.to_i - m ) ** 2 }
	   sum / ( self.length - 1 ).to_f
   end

   def standard_deviation
	   Math.sqrt self.sample_variance
   end
end
