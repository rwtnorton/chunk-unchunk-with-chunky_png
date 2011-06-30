#!/usr/bin/env ruby

require 'chunky_png'

# 300 x 225
image = ChunkyPNG::Image.from_file('output.png')

puts image.metadata['Title']
puts image.metadata['Author']
puts "w x h = #{image.width} x #{image.height}"

# Define methods to extract a sub-canvas from an existing canvas.
module Chunks
  def self.ensure_length(total, start, len)
    start + len > total ? total - start : len
  end
  def self.calculate_chunked_indexes(width, height, x, y, w, h)
    w = ensure_length(width,  x, w)
    h = ensure_length(height, y, h)
    chunks = []
    y.upto(y + h - 1) do |row|
      col_start = row * width + x
      col_end   = row * width + x + w - 1
      chunks += (col_start .. col_end).to_a
    end
    chunks
  end
end

class Array
  def extract_chunks(*args)
    indexes = Chunks.calculate_chunked_indexes(*args)
    return indexes.map {|i| self[i] }
  end
end

class ChunkyPNG::Canvas

#  def extract_chunk(x, y, w, h)
#    w = width  - x if x + w > width
#    h = height - y if y + h > height
#    new_pixels = []
#    y.upto(y + h - 1) do |row|
#      col_start = row * width + x
#      col_end   = row * width + x + w - 1
#      new_pixels += self.pixels[col_start .. col_end]
#    end
#    self.class.new(w, h, new_pixels)
#  end
  def extract_chunk(x, y, w, h)
    w = Chunks.ensure_length(width,  x, w)
    h = Chunks.ensure_length(height, y, h)
    new_pixels = pixels.extract_chunks(width, height, x, y, w, h)
    self.class.new(w, h, new_pixels)
  end

end

# Try to split the image into two vertically.
left_image   = image.extract_chunk(  0,   0,
                                   image.width / 2, image.height)
right_image  = image.extract_chunk(image.width / 2, 0,
                                   image.width / 2, image.height)
left_image.save('images/left.png')
right_image.save('images/right.png')

# and now horizontally.
top_image    = image.extract_chunk(  0,   0,
                                   image.width, image.height / 2)
bottom_image = image.extract_chunk(  0, image.height / 2,
                                   image.width, image.height / 2 + 1)
top_image.save('images/top.png')
bottom_image.save('images/bottom.png')

__END__
0.upto(300 / 10) do |x|
  0.upto(
end
