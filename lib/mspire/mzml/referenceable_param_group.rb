require 'mspire/paramable'

module Mspire
  class Mzml

    # need to call to_xml_definition (or use
    # Mspire::Mzml::ReferenceableParamGroupList.list_xml) to get the xml for the
    # object itself (and not a reference).  Merely callying #to_xml will
    # result in a referenceableParamGroupRef being created.
    class ReferenceableParamGroup
      include Mspire::Paramable

      attr_accessor :id

      def initialize(id)
        @id = id
        params_init
        yield(self) if block_given?
      end

      def to_xml(builder)
        builder.referenceableParamGroupRef(ref: @id)
        builder
      end

      def to_xml_definition(builder)
        builder.referenceableParamGroup(id: @id) do |fc_n|
          params.each {|obj| obj.to_xml(fc_n) }
        end
        builder
      end

      def self.from_xml(xml)
        obj = self.new(xml[:id])
        obj.describe_from_xml!(xml)
        obj
      end

      def self.list_xml(objs, builder)
        builder.referenceableParamGroupList(count: objs.size) do |rpgl_n|
          objs.each {|obj| obj.to_xml_definition(rpgl_n) }
        end
        builder
      end
    end
  end
end
