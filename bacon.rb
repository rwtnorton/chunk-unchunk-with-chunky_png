#!/usr/bin/env ruby

# Solution for http://codebrawl.com/contests/pixelizing-images-with-chunkypng

require 'chunky_png'

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
end

class Array
  def extract_chunks(*args)
    indexes = Chunks.calculate_chunked_indexes(*args)
    return indexes.map {|i| self[i] }
  end
end

# Add extract_chunk method to ChunkyPNG::Canvas to extract a sub-canvas.
class ChunkyPNG::Canvas
  def extract_chunk(x, y, w, h)
    w = Chunks.ensure_length(width,  x, w)
    h = Chunks.ensure_length(height, y, h)
    new_pixels = pixels.extract_chunks(width, height, x, y, w, h)
    self.class.new(w, h, new_pixels)
  end
end

# Add a few more helper classes to our utility module to help with the
# partitioning of an area into squares.
module Chunks
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

# Done with helper module code.  Time for the solution.

CHUNK_SIZE = 10

image = ChunkyPNG::Image.from_file('output.png')
# 300 x 225

# Creates a template of how to partition image area into CHUNK_SIZE squares.
chunker = Chunks::Chunker.new(image.width, image.height, CHUNK_SIZE)

# Gather sub-images (chunks) with their positions.
positioned_chunks = chunker.panels.map do |panel|
  chunk = image.extract_chunk(panel.x, panel.y, panel.w, panel.h)
  { :chunk => chunk, :x => panel.x, :y => panel.y }
end

pixelized_image = ChunkyPNG::Canvas.new(image.width, image.height)

# Recompose original image from image chunks.
positioned_chunks.each do |pos_chunk|
  chunk = pos_chunk[:chunk]
  x     = pos_chunk[:x]
  y     = pos_chunk[:y]
  pixelized_image.replace!(chunk, x, y)
end

pixelized_image.save("pixelized_image.png")
