require "spec_helper"
require "delegate"

describe "Stubbing/mocking methods in before(:all) blocks" do
  old_rspec = nil

  shared_examples_for "A stub/mock in a before(:all) block" do |message_expectation_block|
    the_error = nil
    before(:all) do
      begin
        message_expectation_block.call
      rescue
        the_error = $!
      end
    end

    it "raises an error with a useful message" do
      expect(the_error).to be_a_kind_of(RuntimeError)

      expect(the_error.message).to match(/The use of doubles or partial doubles from rspec-mocks outside of the per-test lifecycle is not supported./)
    end
  end

  describe "#stub" do
    it_behaves_like "A stub/mock in a before(:all) block", lambda { Object.stub(:foo); __LINE__ }
  end

  describe "#unstub" do
    it_behaves_like "A stub/mock in a before(:all) block", lambda { Object.unstub(:foo); __LINE__ }
  end

  describe "#should_receive" do
    it_behaves_like "A stub/mock in a before(:all) block", lambda { Object.should_receive(:foo); __LINE__ }
  end

  describe "#should_not_receive" do
    it_behaves_like "A stub/mock in a before(:all) block", lambda { Object.should_not_receive(:foo); __LINE__ }
  end

  describe "#any_instance" do
    it_behaves_like "A stub/mock in a before(:all) block", lambda { Object.any_instance.should_receive(:foo); __LINE__ }
  end

  describe "#stub_chain" do
    it_behaves_like "A stub/mock in a before(:all) block", lambda { Object.stub_chain(:foo); __LINE__ }
  end

  describe "#expect(...).to receive" do
    it_behaves_like "A stub/mock in a before(:all) block", lambda { expect(Object).to receive(:foo); __LINE__ }
  end
end
