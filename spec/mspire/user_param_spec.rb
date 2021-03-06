require 'spec_helper'

require 'mspire/user_param'
require 'mspire/cv/param'

describe Mspire::UserParam do

  describe 'initializing with various args' do

    it 'can be initialized with the name' do
      arg = 'special_user_param'
      param = Mspire::UserParam.new arg
      param.name.should == arg
      param.unit.should be_nil
    end

    it' can be initialized with an included UO accession' do
      arg = 'special_user_param'
      param = Mspire::UserParam.new arg, 'UO:0000108'
      param.name.should == arg
      param.unit.should_not be_nil
      param.unit.accession.should == 'UO:0000108'
    end

    it' can be initialized with an included CV::Param (unit)' do
      arg = 'special_user_param'
      param = Mspire::UserParam.new arg, Mspire::CV::Param['UO:0000108']
      param.name.should == arg
      param.unit.should_not be_nil
      param.unit.accession.should == 'UO:0000108'
    end

    it 'can be initialized with a name and value (and type)' do
      args = %w(some_user_param 88 xsd:float)
      param = Mspire::UserParam.new *args
      param.name.should == args[0]
      param.value.should == args[1]
      param.type.should == args[2]
      param.unit.should be_nil

      args = %w(some_user_param 88 xsd:float UO:0000108)
      param = Mspire::UserParam.new *args
      param.name.should == args[0]
      param.value.should == args[1]
      param.type.should == args[2]
      param.unit.accession.should == 'UO:0000108'
    end

  end

end
