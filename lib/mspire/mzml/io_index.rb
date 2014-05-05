require 'mspire/mzml/parser'
require 'mspire/mzml/spectrum'
require 'mspire/mzml/chromatogram'

module Mspire
  class Mzml

    # an index that retrieves its objects on the fly by index from the IO object.
    class IOIndex
      include Enumerable

      attr_reader :io

      attr_reader :byte_index

      # hash of relevant hashes and objects for linking
      attr_accessor :link

      # byte_index will typically be an Mspire::Mzml::Index object.
      #
      # link will have the following keys:
      #
      #     :ref_hash
      #     :data_processing_hash
      #     :(<sample>|<chromatogram>)_default_data_processing
      #
      # may have:
      #
      #     :source_file_hash
      #
      def initialize(io, byte_index, link)
        @io, @byte_index, @link = io, byte_index, link
        @object_class = Mspire::Mzml.const_get(@byte_index.name.to_s.capitalize)
        @closetag_regexp = %r{</#{name}>}
      end

      def name
        @byte_index.name
      end

      def each(&block)
        return to_enum(__method__) unless block
        (0...byte_index.size).each do |int|
          block.call(self[int])
        end
      end

      def [](index)
        @object_class.from_xml(fetch_xml_node(index), @link)
      end

      def length
        @byte_index.length
      end
      alias_method :size, :length

      # gets the data string through to last element
      def get_xml_string(start_byte)
        @io.seek(start_byte)
        data = ""
        @io.each_line do |line|
          data << line 
          break if @closetag_regexp.match(line)
        end
        data
      end

      def xml_node_from_start_byte(start_byte)
        # consider passing in @encoding from upstream object (as second nil):
        xml = get_xml_string(start_byte)
        Nokogiri::XML.parse(xml, nil, nil, Parser::NOBLANKS).root
      end

      def fetch_xml_node(index)
        xml_node_from_start_byte(byte_index[index])
      end

    end
  end
end
