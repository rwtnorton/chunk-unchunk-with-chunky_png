#!/usr/bin/env ruby

require 'chunky_png'
require 'pp'

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

  # Returns Array of indexes, treating +self+ as a +width+ by +height+
  # matrix (origin at upper-left corner), where returned indexes match
  # the box (chunk) at (+x+, +y+) of width +w+ and height +h+.
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

  class Panel
    attr_reader :x, :y, :w, :h
    def initialize(x, y, w, h)
      @x, @y, @w, @h = x, y, w, h
    end
    def inspect
      x = sprintf '%3d', @x
      y = sprintf '%3d', @y
      "[#{x},#{y}]"
    end
  end

  # Helper class for partitioning an area into squares (panels).
  # +panels+ is the payoff, containing an array of Panels.
  # If +image_width+ or +image_height+ are not evenly divisible by
  # +panel_size+, then extra panels will be added that overlap other panels.
  class Chunker
    attr_reader :panels, :panel_size, :image_width, :image_height
    def initialize(image_width, image_height, panel_size=10)
      @image_width, @image_height, @panel_size =
       image_width,  image_height,  panel_size

      col_count, extra_col = image_width.divmod(panel_size)
      row_count, extra_row = image_height.divmod(panel_size)
      extra_col = extra_col > 0
      extra_row = extra_row > 0

      grid_xs = (0 .. col_count - 1).map {|x| x * panel_size }
      grid_xs << image_width - panel_size if extra_col
      grid_ys = (0 .. row_count - 1).map {|y| y * panel_size }
      grid_ys << image_height - panel_size if extra_row

      panels = []
      grid_ys.each do |y|
        grid_xs.each do |x|
          panels << Panel.new(x, y, panel_size, panel_size)
        end
      end
      @panels = panels
    end
  end
end

class Array
  def extract_chunks(*args)
    indexes = Chunks.calculate_chunked_indexes(*args)
    return indexes.map {|i| self[i] }
  end
end

class ChunkyPNG::Canvas
  def extract_chunk(x, y, w, h)
    w = Chunks.ensure_length(width,  x, w)
    h = Chunks.ensure_length(height, y, h)
    new_pixels = pixels.extract_chunks(width, height, x, y, w, h)
    self.class.new(w, h, new_pixels)
  end

end

chunker = Chunks::Chunker.new(image.width, image.height, 50)
pp chunker.panels
chunker.panels.each do |panel|
  chunk = image.extract_chunk(panel.x, panel.y, panel.w, panel.h)
  chunk.save("images/chunk-#{panel.x}-#{panel.y}.png")
end
