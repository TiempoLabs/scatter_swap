module ScatterSwap
  class Hasher
    def initialize(spin = 0)
      @spin = spin
    end

    # obfuscates an integer up to 10 digits in length
    def hash(plain_integer)
      working_array = build_working_array(plain_integer)
      working_array = swap(working_array)
      working_array = scatter(working_array)
      return completed_string(working_array)
    end

    # de-obfuscates an integer
    def reverse_hash(hashed_integer)
      working_array = build_working_array(hashed_integer)
      working_array = unscatter(working_array)
      working_array = unswap(working_array)
      return completed_string(working_array)
    end

    def completed_string(working_array)
      str = '0000000000' # Start with an empty string of 10 spaces
      working_array.each_with_index do |i, idx|
        if (i != 0)
          str[idx] = INT_CHAR_LOOKUP[i]
        end
      end
      str
    end

    # We want a unique map for each place in the original number
    def swapper_map(index)
      # Lazy load the swapper_map for this index
      if (!@_swapper_maps || !@_swapper_maps[index])
        @_swapper_maps ||= []
        index_swapper_map = []

        array = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
        10.times do |i|
          index_swapper_map << array.rotate!(index + i ^ spin).pop
        end

        @_swapper_maps[index] = index_swapper_map
      end

      return @_swapper_maps[index]
    end

    # Using a unique map for each of the ten places,
    # we swap out one number for another
    def swap(working_array)
      swapped_working_array = working_array.collect.with_index do |digit, index|
        swapper_map(index)[digit]
      end

      return swapped_working_array
    end

    # Reverse swap
    def unswap(working_array)
      unswapped_working_array = working_array.collect.with_index do |digit, index|
        swapper_map(index).rindex(digit)
      end

      return unswapped_working_array
    end

    # Rearrange the order of each digit in a reversable way by using the 
    # sum of the digits (which doesn't change regardless of order)
    # as a key to record how they were scattered
    def scatter(working_array)
      sum_of_digits = working_array.inject(:+).to_i
      rotation = spin ^ sum_of_digits
      scattered_working_array = 10.times.collect do
        working_array.rotate!(rotation).pop
      end

      return scattered_working_array
    end

    # Reverse the scatter
    def unscatter(working_array)
      scattered_array = working_array
      sum_of_digits = scattered_array.inject(:+).to_i
      rotation = (sum_of_digits ^ spin) * -1
      unscattered_working_array = []
      unscattered_working_array.tap do |unscatter|
        10.times do
          unscatter << scattered_array.pop
          unscatter.rotate!(rotation)
        end
      end

      return unscattered_working_array
    end

    # Add some spice so that different apps can have differently mapped hashes
    def spin
      @spin || 0
    end

    # Right justifies the integer/string that's passed in creating an array of integers (representing digits in the final ID)
    # Optimized for using arithmetic to left justify instead of string casting + rjusting
    def build_working_array(original_integer)
      zero_pad = [0,0,0,0,0,0,0,0,0,0]
      rem = original_integer.to_i
      denominator = 1_000_000_000
      index = 0
      while (rem > 0)
        zero_pad[index] = rem / denominator
        rem = rem % denominator
        denominator = denominator / 10
        index += 1
      end
      return zero_pad
    end

    private
      attr_accessor :_swapper_maps

    INT_CHAR_LOOKUP = {
        0 => '0'.freeze,
        1 => '1'.freeze,
        2 => '2'.freeze,
        3 => '3'.freeze,
        4 => '4'.freeze,
        5 => '5'.freeze,
        6 => '6'.freeze,
        7 => '7'.freeze,
        8 => '8'.freeze,
        9 => '9'.freeze,
    }
  end
end
