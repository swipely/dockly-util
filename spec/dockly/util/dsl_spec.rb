require 'spec_helper'

class IncludedClass
  include Dockly::Util::DSL

  dsl_attribute :ocean
end

class TestClass
  include Dockly::Util::DSL

  dsl_attribute :chips
  dsl_class_attribute :meta, IncludedClass
end

class ArrayClass
  include Dockly::Util::DSL

  dsl_class_attribute :attr, IncludedClass, type: Array
end

describe Dockly::Util::DSL do
  let(:included_class) { IncludedClass }
  let(:test_class) { TestClass }
  let(:array_class) { ArrayClass }

  let(:test_instance) { test_class.new!(:name => 'Tony') }
  let(:array_instance) { array_class.new! }

  describe '.dsl_attribute' do
    it 'defines a method for each name given' do
      test_instance.should respond_to :chips
    end

    context 'the defined method(s)' do
      context 'with 0 arguments' do
        let(:test_val) { 'lays' }
        before { test_instance.instance_variable_set(:@chips, test_val) }

        it 'returns the value of the instance variable with a matching name' do
          test_instance.chips.should == test_val
        end
      end

      context 'with one argument' do
        it 'sets the corresponding instance variable to the passed-in value' do
          expect { test_instance.chips('bbq') }
              .to change { test_instance.instance_variable_get(:@chips) }
              .to 'bbq'
        end
      end

      context 'with a block' do
        it 'sets the corresponding instance variable to the block' do
          expect { test_instance.chips { 'test' } }
              .to change { test_instance.instance_variable_get(:@chips) }
          expect(test_instance.chips.call).to eq('test')
        end
      end

    end
  end

  describe '.dsl_class_attribute' do
    context 'when the sceond argument is not a DSL' do
      it 'raises an error' do
        expect do
          Class.new do
            include Dockly::Util::DSL

            dsl_class_attribute :test, Array
          end
        end.to raise_error
      end
    end

    context 'when the second argument is a DSL' do
      it 'defines a new method with the name of the first argument' do
        test_instance.should respond_to :meta
        array_instance.should respond_to :attr
      end

      it 'defines a new method on the DSL class with the name of the current class' do
        included_class.new.should respond_to :test_class
        included_class.new.should respond_to :array_class
      end

      context 'the method' do
        context 'for a regular class attribute' do
          let(:meta) { test_instance.instance_variable_get(:@meta) }

          context 'when a symbol is given' do
            context 'and a block is given' do
              before { test_instance.meta(:yolo) { ocean 'Indian' } }

              it 'creates a new instance of the specified Class with the name set' do
                meta.name.should == :yolo
                meta.ocean.should == 'Indian'
              end
            end

            context 'and a block is not given' do
              before { included_class.new!(:name => :test_name) { ocean 'Pacific' } }

              it 'looks up the instance in its Class\'s .instances hash' do
                test_instance.meta(:test_name).ocean.should == 'Pacific'
              end
            end
          end

          context 'when a symbol is not given' do
            context 'and a block is given' do
              before { test_instance.meta { ocean 'Atlantic' } }

              it 'creates a new instance of the specified Class' do
                meta.ocean.should == 'Atlantic'
              end

              it 'generates a name' do
                meta.name.should == :"#{test_instance.name}_#{meta.class}"
              end
            end

            context 'and a block is not given' do
              before { test_instance.meta(:test) { ocean 'Artic' } }

              it 'returns the corresponding instance variable' do
                test_instance.meta.should == meta
              end
            end
          end
        end

        context 'for an array class attribute' do
          let(:attr) { array_instance.instance_variable_get(:@attr) }

          context 'when a symbol is given' do
            context 'and a block is given' do
              before { array_instance.attr(:yolo) { ocean 'Indian' } }

              it 'creates a new instance of the specified Class with the name set' do
                expect(attr.length).to be == 1
                expect(attr.first.ocean).to be == 'Indian'
              end
            end

            context 'and a block is not given' do
              before { included_class.new!(:name => :test_name) { ocean 'Pacific' } }

              it 'looks up the instance in its Class\'s .instances hash' do
                expect(array_instance.attr(:test_name).first.ocean).to be == 'Pacific'
              end
            end
          end

          context 'when a symbol is not given' do
            context 'and a block is given' do
              before { array_instance.attr { ocean 'Atlantic' } }

              it 'creates a new instance of the specified Class' do
                attr.first.ocean.should == 'Atlantic'
              end

              it 'generates a name' do
                attr.first.name.should == :"#{array_instance.name}_#{IncludedClass.to_s}"
              end
            end

            context 'and a block is not given' do
              before { array_instance.attr(:test) { ocean 'Artic' } }

              it 'returns the corresponding instance variable' do
                array_instance.attr.should == attr
              end
            end
          end
        end
      end
    end
  end

  describe '#ensure_present!' do
    context 'when at least one of the symbols is nil' do
      it 'raises an error' do
        expect { test_instance.send(:ensure_present!, :meta) }.to raise_error
      end
    end

    context 'when each symbol is present' do
      it 'does nothing' do
        expect { test_instance.send(:ensure_present!, :name) }.to_not raise_error
      end
    end
  end

  describe '.default_value' do
    context 'when a block is given' do
      it 'calls the block and adds it to he default_values hash' do
        test_class.send(:default_value, :meta) { included_class.new!(:name => :joey) }
        test_class.default_values[:meta].name.should == :joey
      end
    end

    context 'when a value is given' do
      it 'adds the pair to the default_values hash' do
        test_class.send(:default_value, :chips, 'Cool Ranch')
        test_class.default_values[:chips].should == 'Cool Ranch'
      end
    end

    context 'when extending' do
      class Parent
        include Dockly::Util::DSL

        dsl_attribute :test
        default_value :test, 'not so fancy'
      end

      class Child < Parent
        dsl_attribute :fancy_test
        default_value :fancy_test, 'fancy'
      end

      it "should have all default values in child" do
        expect( Child.default_values).to match_array(
          [[:fancy_test, 'fancy'], [:test, 'not so fancy']] )
      end

      it "should not include child default values in parent" do
        expect( Parent.default_values).to_not include(:fancy_test)
      end
    end
  end

  describe '#initialize' do
    context 'when a block is given' do
      it 'is instance evaluated' do
        test_class.new! { name :timmy }.name.should == :timmy
      end
    end

    context 'when a hash is given' do
      it 'sends each key value pair to the object as a message' do
        test_class.new!(:name => :tommy).name.should == :tommy
      end
    end

    context 'when there is a name' do
      it 'adds the current instance to the class\'s instances hash' do
        test_class.instances[:jillian].should be_nil
        test_class.new! { name :jillian }
        test_class.instances[:jillian].name.should == :jillian
      end
    end
  end
end
