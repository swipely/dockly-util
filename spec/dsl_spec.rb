require 'spec_helper'

describe DSL do
  let(:included_class) do
    Class.new do
      include DSL

      dsl_attribute :ocean
    end
  end

  let(:test_class) do
    klass = included_class
    Class.new do
      include DSL

      dsl_attribute :chips
      dsl_class_attribute :meta, klass
    end
  end

  subject { test_class.new!(:name => 'Tony') }

  describe '.dsl_attribute' do
    it 'defines a method for each name given' do
      subject.should respond_to :chips
    end

    context 'the defined method(s)' do
      context 'with 0 arguments' do
        let(:test_val) { 'lays' }
        before { subject.instance_variable_set(:@chips, test_val) }

        it 'returns the value of the instance variable with a matching name' do
          subject.chips.should == test_val
        end
      end

      context 'with one argument' do
        it 'sets the corresponding instance variable to the passed-in value' do
          expect { subject.chips('bbq') }
              .to change { subject.instance_variable_get(:@chips) }
              .to 'bbq'
        end
      end
    end
  end

  describe '.dsl_class_attribute' do
    context 'when the sceond argument is not a DSL' do
      it 'raises an error' do
        expect do
          Class.new do
            include DSL

            dsl_class_attribute :test, Array
          end
        end.to raise_error
      end
    end

    context 'when the second argument is a DSL' do
      it 'defines a new method with the name of the first argument' do
        subject.should respond_to :meta
      end

      context 'the method' do
        let(:meta) { subject.instance_variable_get(:@meta) }

        context 'when a symbol is given' do
          context 'and a block is given' do
            before { subject.meta(:yolo) { ocean 'Indian' } }

            it 'creates a new instance of the specified Class with the name set' do
              meta.name.should == :yolo
              meta.ocean.should == 'Indian'
            end
          end

          context 'and a block is not given' do
            before { included_class.new!(:name => :test_name) { ocean 'Pacific' } }

            it 'looks up the instance in its Class\'s .instances hash' do
              subject.meta(:test_name).ocean.should == 'Pacific'
            end
          end
        end

        context 'when a symbol is not given' do
          context 'and a block is given' do
            before { subject.meta { ocean 'Atlantic' } }

            it 'creates a new instance of the specified Class' do
              meta.ocean.should == 'Atlantic'
            end

            it 'generates a name' do
              meta.name.should == :"#{subject.name}_#{meta.class}"
            end
          end

          context 'and a block is not given' do
            before { subject.meta(:test) { ocean 'Artic' } }

            it 'returns the corresponding instance variable' do
              subject.meta.should == meta
            end
          end
        end
      end
    end
  end

  describe '#ensure_present!' do
    context 'when at least one of the symbols is nil' do
      it 'raises an error' do
        expect { subject.send(:ensure_present!, :meta) }.to raise_error
      end
    end

    context 'when each symbol is present' do
      it 'does nothing' do
        expect { subject.send(:ensure_present!, :name) }.to_not raise_error
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

    context 'when there is no name' do
      it 'raises an error' do
        expect { test_class.new! { chips 'Tortilla' } }.to raise_error
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
