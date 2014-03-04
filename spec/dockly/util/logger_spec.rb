require 'spec_helper'

describe Dockly::Util::Logger do
  before(:all) { Dockly::Util::Logger.enable! }
  after(:all) { Dockly::Util::Logger.disable! unless ENV['ENABLE_LOGGER'] == 'true' }

  describe '#initialize' do
    its(:prefix) { should be_empty }
    its(:print_method?) { should be_true }
    its(:output) { should == STDOUT }
  end

  describe '#log' do
    context 'when the logger is enabled' do
      let(:level) { :debug }
      let(:message) { 'hey mom' }
      let(:formatted) { 'T hey mom' }

      before { subject.stub(:format_message).with(level, message).and_return(formatted) }

      it 'sends a formatted level and message to the output' do
        subject.output.should_receive(:puts).with(formatted)
        subject.log(level, message)
      end
    end

    context 'when the logger is disabled' do
      before(:all) { Dockly::Util::Logger.disable! }
      after(:all) { Dockly::Util::Logger.enable! }

      it 'does nothing' do
        subject.output.should_not_receive(:puts)
        subject.log(:debug, 'this wont be printed')
      end
    end
  end

  Dockly::Util::Logger::LEVELS.each do |level|
    describe "##{level}" do
      let(:message) { "message for #{level}" }

      it "sends the message to #log with #{level} as the level" do
        subject.should_receive(:log).with(level, message)
        subject.public_send(level, message)
      end
    end
  end

  describe '#format_message' do
    before do
      subject.stub(:prefix).and_return(prefix)
      subject.stub(:get_last_method).and_return(method)
      subject.stub(:format_level).with(level).and_return(formatted_level)
    end

    context 'when all of the fields are present' do
      let(:level) { :debug }
      let(:formatted_level) { 'D' }
      let(:prefix) { '[deployz logger]' }
      let(:method) { 'test' }
      let(:message) { 'here i am' }

      it 'returns each of them with a space in the middle' do
        subject.format_message(level, message).should ==
          "#{formatted_level} #{Thread.current.object_id} #{prefix} #{method} #{message}"
      end
    end

    context 'when one of the fields returns nil' do
      let(:level) { :info }
      let(:formatted_level) { 'I' }
      let(:prefix) { '[deployz logger]' }
      let(:method) { nil }
      let(:message) { 'there you are' }

      it 'does not insert an extra space' do
        subject.format_message(level, message).should ==
          "#{formatted_level} #{Thread.current.object_id} #{prefix} #{message}"
      end
    end
  end

  describe '#format_level' do
    context 'when the level is nil or empty' do
      it 'returns nil' do
        [nil, '', :''].should be_all { |level| subject.format_level(level).nil?  }
      end
    end

    context 'when the level is present' do
      it 'returns the first character upper-cased' do
        { :info => 'I',
          :debug => 'D',
          '>>=' => '>'
        }.should be_all { |level, formatted|
          subject.format_level(level) == formatted
        }
      end
    end
  end

  describe '#get_last_method' do
    def test_get_last_method
      subject.get_last_method
    end

    context 'when calls are not nested' do
      it 'returns the calling method' do
        test_get_last_method.should == 'test_get_last_method'
      end
    end

    context 'when calls are nested' do
      def outer_method
        test_get_last_method
      end

      it 'still returns the calling method' do
        outer_method.should == 'test_get_last_method'
      end
    end
  end

  describe '#with_prefix' do
    context 'when the new prefix is empty' do
      context 'and the old prefix is empty' do
        it 'yields a new logger with an empty prefix' do
          subject.with_prefix(nil) { |logger| logger.prefix.should be_empty }
        end
      end

      context 'and the old prefix is present' do
        let(:prefix) { 'hello' }
        subject { described_class.new(prefix) }

        it 'yields a new logger with the old prefix' do
          subject.with_prefix(nil) { |logger| logger.prefix.should == prefix }
        end
      end
    end

    context 'when the new prefix is present' do
      context 'and the old prefix is empty' do
        let(:prefix) { 'hola' }

        it 'yields a new logger with the new prefix' do
          subject.with_prefix(prefix) { |logger| logger.prefix.should == prefix }
        end
      end

      context 'and the old prefix is present' do
        let(:old_prefix) { 'hello' }
        let(:new_prefix) { 'hola' }
        let(:prefix) { "#{old_prefix} #{new_prefix}" }

        subject { described_class.new(old_prefix) }

        it 'yields a new logger with the old prefix' do
          subject.with_prefix(new_prefix) { |logger| logger.prefix.should == prefix }
        end
      end
    end
  end

  describe 'the meta class' do
    subject { described_class }

    (Dockly::Util::Logger::LEVELS + [:default, :logger, :log, :with_prefix]).each do |method|
      it { should respond_to method }
    end
  end

  describe Dockly::Util::Logger::Mixin do
    let(:test_class) { Class.new { include Dockly::Util::Logger::Mixin } }

    subject { test_class.new }

    describe '#logger' do
      its(:logger) { should be_a Dockly::Util::Logger }

      it 'has the class name as the prefix' do
        subject.logger.prefix.should == test_class.name
      end
    end

    (Dockly::Util::Logger::LEVELS + [:log, :with_prefix]).each do |method|
      describe "##{method}" do
        it "sends ##{method} to #logger" do
          subject.logger.should_receive(method)
          subject.public_send(method)
        end
      end
    end
  end
end
