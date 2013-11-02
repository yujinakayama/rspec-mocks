require "spec_helper"

describe "Stubbing/mocking methods in before(:all) blocks" do
  old_rspec = nil

  shared_examples_for "A stub/mock in a before(:all) block" do |method|
    warn_message = nil
    old_warn = Kernel.method(:warn)

    before(:all) do
      Kernel.singleton_class.send(:remove_method, :warn)
      Kernel.send(:define_singleton_method, :warn) { |message| warn_message = message }
      Object.send(method, :foo)
    end

    it "warns" do
      expect(warn_message).not_to be nil
    end

    it "includes the call site in the warning" do
      #Expect the call site to be the line 9 above where Object.stub(:foo) is called
      expect(warn_message).to match(/#{__FILE__}:#{__LINE__-9}/)
    end

    it "does not stub/mock the method" do
      expect {
        Object.foo
      }.to raise_error
    end

    after(:all) do
      Kernel.singleton_class.send(:remove_method, :warn)
      Kernel.send(:define_singleton_method, :warn, &old_warn)
    end
  end

  describe "#stub" do
    it_behaves_like "A stub/mock in a before(:all) block", :stub
  end

  describe "#should_receive" do
    it_behaves_like "A stub/mock in a before(:all) block", :should_receive
  end

  describe "#should_not_receive" do
    it_behaves_like "A stub/mock in a before(:all) block", :should_not_receive
  end

  describe "#stub_chain" do
    it_behaves_like "A stub/mock in a before(:all) block", :stub_chain
  end

  describe "#unstub" do
    it_behaves_like "A stub/mock in a before(:all) block", :unstub
  end
end
