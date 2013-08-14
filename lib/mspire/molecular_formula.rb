require 'mspire/isotope'
require 'mspire/mass'

module Mspire
  class MolecularFormula < Hash

    class << self
      def from_aaseq(aaseq, formula_hash=Mspire::Isotope::AA::FORMULAS)
        hash = aaseq.each_char.inject({}) do |hash,aa| 
          hash.merge(formula_hash[aa]) {|hash,old,new| (old ? old : 0) + new }
        end
        hash[:H] += 2
        hash[:O] += 1
        self.new(hash)
      end

      # takes a string, with properly capitalized elements making up the
      # formula.  The elements may be in any order.
      def from_string(mol_form_str, charge=0)
        mf = self.new({}, charge)
        mol_form_str.scan(/([A-Z][a-z]?)(\d*)/).each do |k,v| 
          mf[k.to_sym] = (v == '' ? 1 : v.to_i)
        end
        mf
      end

      # arg may be a String, Hash, or MolecularFormula object.
      def from_any(arg, charge=0)
        if arg.is_a?(String)
          from_string(arg, charge)
        else
          self.new(arg, arg.respond_to?(:charge) ? arg.charge : 0)
        end
      end
      alias_method :[], :from_any

    end

    # integer desribing the charge state
    # mass calculations will add/remove electron mass from this
    attr_accessor :charge

    # Takes a hash and an optional Integer expressing the charge
    #     {H: 22, C: 12, N: 1, O: 3, S: 2}  # case and string/sym doesn't matter
    def initialize(hash={}, charge=0)
      @charge = charge
      self.merge!(hash)
    end

    # returns a new formula object where all the atoms have been added up
    def +(*others)
      self.dup.add!(*others)
    end

    # returns self
    def add!(*others)
      others.each do |other|
        self.merge!(other) {|key, oldval, newval| self[key] = oldval + newval }
        self.charge += other.charge
      end
      self
    end

    # returns a new formula object where all the formulas have been subtracted
    # from the caller
    def -(*others)
      self.dup.sub!(*others)
    end

    def sub!(*others)
      others.each do |other|
        oth = other.dup
        self.each do |k,v|
          if oth.key?(k)
            self[k] -= oth.delete(k)
          end
        end
        oth.each do |k,v|
          self[k] = -v
        end
        self.charge -= other.charge
      end
      self
    end

    def *(int)
      self.dup.mul!(int)
    end

    def mul!(int, also_do_charge=true)
      raise ArgumentError, "must be an integer" unless int.is_a?(Integer)
      self.each do |k,v|
        self[k] = v * int
      end
      self.charge *= int if also_do_charge
      self
    end

    def /(int)
      self.dup.div!(int)
    end

    def div!(int, also_do_charge=true)
      raise ArgumentError, "must be an integer" unless int.is_a?(Integer)
      self.each do |k,v|
        quotient, modulus = v.divmod(int)
        raise ArgumentError "all numbers must be divisible by int" unless modulus == 0
        self[k] = quotient
      end
      if also_do_charge
        quotient, modulus = self.charge.divmod(int) 
        raise ArgumentError "charge must be divisible by int" unless modulus == 0
        self.charge = quotient
      end
      self
    end

    # gives the monoisotopic mass adjusted by the current charge (i.e.,
    # adds/subtracts electron masses for the charges)
    def mass(consider_electron_masses = true)
      mss = inject(0.0) do |sum,(el,cnt)| 
        sum + (Mspire::Mass::Element::MONO[el]*cnt)
      end
      mss -= (Mspire::Mass::ELECTRON * charge) if consider_electron_masses
      mss
    end

    def avg_mass
      inject(0.0) {|sum,(el,cnt)| sum + (Mspire::Mass::Element::AVG[el]*cnt) }
    end

    # returns nil if the charge == 0
    def mz(consider_electron_masses = true)
      if charge == 0
        nil
      else
        mass(consider_electron_masses) / charge
      end
    end

    def to_s(alphabetize=true)
      h = alphabetize ? self.sort : self
      st = ''
      h.each do |k,v|
        if v > 0
          st << k.to_s.capitalize
          st << v.to_s if v > 1
        end
      end 
      st
    end

    def to_hash
      Hash[ self ]
    end

    alias_method :old_equal, '=='.to_sym

    def ==(other)
      old_equal(other) && self.charge == other.charge
    end

  end
end

require 'mspire/isotope/aa'
