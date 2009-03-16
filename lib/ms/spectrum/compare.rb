
require 'ms/spectrum'

module Kernel
private
   def this_method
     caller[0] =~ /`([^']*)'/ and $1
   end
end

class Array
  def sum
    self.inject(0.0) {|_sum, v| _sum += v }
  end
end

module Ms
  class Spectrum
    module Compare
  
      # percent ion current score: the percent of total ion current of the
      # calling object that can be explained by other. Ranges from 0-100
      def pic_score(other, opts={})
        opts= {:normalize => true}.merge(opts)
        (a_spec, b_spec) = 
          if opts[:normalize] == true
            [self.normalize, other.normalize]
          else
            [self, other]
          end
        overlapping_current = 0.0
        a_spec.compare(b_spec, opts.merge( {:yield_diff => false} )) do |sint, oint|
          overlapping_current += [oint, sint].min
        end
        100.0 * (overlapping_current / a_spec.intensities.sum)
      end


      # Zhang Analytical Chemistry. 2004 76(14)
      # "the ratio between the sum of geometric mean and sum of arithmetic mean
      # of all ions, after the two spectra are normalized to the same total
      # ion intensity"
      # The score will be 1 for identical spectra
      # (Σ (Ii*Ij)^½) / (ΣIi * ΣIj)^½
      #
      # options:
      # 
      #   :normalize => true | false (d: true) normalizes intensities first
      #
      # relevant options given for 'compare' will be passed through:
      #
      #     :radius
      #     :type
      def sim_score(other, opts={})
        opts = {:normalize => true}.merge(opts)
        (a_spec, b_spec) = 
          if opts[:normalize] == true
            [self.normalize, other.normalize]
          else
            [self, other]
          end
        numer = 0.0
        
        a_spec.compare(b_spec, opts.merge( {:yield_diff => false} )) do |sint, oint|
          numer += Math.sqrt(sint * oint)
        end
        numer / Math.sqrt( a_spec.ints.sum * b_spec.ints.sum )
      end

      # opts[:type] == :mutual_best
      #     will only return intensities on mutual best matches within radius.
      #     yields [self_intensity, other_intensity] for each match within
      #     the radius.  
      #
      # opts[:type] == :best
      #     yields the best match in the radius peak.  If one peak is already
      #     spoken for, a different peak may still match a close peak if it is
      #     its best match (how to explain this?).
      #
      # if opts[:yield_diff] == true then returns [..., diff] (d: true)
      # if opts[:yield_mz] == true then returns [mz, mz, int, int] (d: false)
      # if opts[:yield_indices] == true then returns [i,j] (d: false)
      # assumes mzs are increasing
      def compare(other, opts={})
        defaults = {:radius => 1.0, :type=>:mutual_best, :yield_diff => true, :yield_mz => false, :yield_indices => false}
        (radius, type, yield_diff, yield_mz, yield_indices) = defaults.merge(opts).values_at(:radius, :type, :yield_diff, :yield_mz, :yield_indices)
        blk = block_given?
        output = [] if !blk
        s_ints = self.intensities
        s_size = self.mzs.size
        o_mzs = other.mzs
        o_size = o_mzs.size
        o_ints = other.intensities
        oi = 0
        start_j = 0
        save = []
        self.mzs.each_with_index do |mz,i|
          break if start_j >= o_size
          hi = mz + radius
          lo = mz - radius
          start_j.upto(o_size-1) do |j|
            diff = mz - o_mzs[j]
            absdiff = diff.abs
            if absdiff <= radius  # a potential hit!
              save << [absdiff, i, j]
            elsif diff < 0  # we overshot
              break  
            else  # undershot
              start_j = j + 1  # this is for the benefit of the next search
            end
          end
        end

        #puts "BEFORE SORT: "
        #p save
        #save.sort!
        #puts "AFTER SORT: "
        #p save
        iset = Array.new(s_size)
        jset = Array.new(o_size)
        save.each do |diff, i, j|
          unless iset[i] || jset[j]
            if type == :best
              iset[i] = true
              jset[j] = true
            end
            to_ret = 
              if yield_indices
                [i,j]
              else
                [s_ints[i], o_ints[j]]
              end
            if yield_mz
              to_ret.unshift( s_mzs[i], o_mzs[j] )
            end
            if yield_diff
              to_ret.push( diff )
            end
            if blk
              yield to_ret
            else
              output << to_ret
            end
          end
          if type == :mutual_best
            iset[i] = true
            jset[j] = true
          end
        end
        output
      end
    end # Compare

    include Compare
  end # Spectrum
end # Ms


