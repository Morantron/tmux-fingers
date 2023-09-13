require "uuid"

SEGMENT_LENGTH = 16
COLUMNS = ENV["COLUMNS"].to_i
LINES = ENV["LINES"].to_i

def compute_divisions
  result = (COLUMNS / SEGMENT_LENGTH).floor.to_i

  loop do
    break if (result * SEGMENT_LENGTH + (result - 1)) <= COLUMNS
    result = result - 1
  end

  result
end

DIVISIONS = compute_divisions

LINES.times do
  codes = [] of String

  DIVISIONS.times do
    codes << UUID.random.to_s.gsub("-", "").to_s[0..SEGMENT_LENGTH - 1]
  end

  puts codes.join(" ")
end
