require 'spec_helper'

describe Raidis::Throttle do

  let(:interval) { 3 }
  let(:throttle) { Raidis::Throttle.new }

  before do
    Raidis::Throttle.stub!(:sleep)
  end

  context 'no action took place yet' do
    describe '#sleep_if_needed' do
      it 'does not sleep' do
        throttle.should_not_receive(:sleep)
        throttle.sleep_if_needed
      end
    end
  end

  context 'action took place 1 second ago' do
    before do
      Timecop.freeze
      throttle.action!
      Timecop.freeze Time.now + 1
    end

    describe '#sleep_if_needed' do
      it 'sleeps for 2 seconds' do
        throttle.should_receive(:sleep).with(2)
        throttle.sleep_if_needed
      end
    end
  end

  context 'action took place 2 seconds ago' do
    before do
      Timecop.freeze
      throttle.action!
      Timecop.freeze Time.now + 2
    end

    describe '#sleep_if_needed' do
      it 'sleeps for 1 seconds' do
        throttle.should_receive(:sleep).with(1)
        throttle.sleep_if_needed
      end
    end
  end

  context 'action took place 4 seconds ago' do
    before do
      Timecop.freeze
      throttle.action!
      Timecop.freeze Time.now + 4
    end

    describe '#sleep_if_needed' do
      it 'does not sleep' do
        throttle.should_not_receive(:sleep)
        throttle.sleep_if_needed
      end
    end
  end

end
