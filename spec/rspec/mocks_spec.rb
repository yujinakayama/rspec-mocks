require "spec_helper"

describe RSpec::Mocks do
  describe "::setup" do
    context "with an existing Mock::Space" do
      before do
        @orig_space = RSpec::Mocks::space
      end

      after do
        RSpec::Mocks::space = @orig_space
      end

      it "memoizes the space" do
        RSpec::Mocks::setup(Object.new)
        space = RSpec::Mocks::space
        RSpec::Mocks::setup(Object.new)
        expect(RSpec::Mocks::space).to equal(space)
      end
    end

    context "with no pre-existing Mock::Space" do
      it "initializes a Mock::Space" do
        RSpec::Mocks::space = nil
        RSpec::Mocks::setup(Object.new)
        expect(RSpec::Mocks::space).not_to be_nil
      end
    end
  end

  describe "::verify" do
    it "delegates to the space" do
      foo = double
      foo.should_receive(:bar)
      expect do
        RSpec::Mocks::verify
      end.to raise_error(RSpec::Mocks::MockExpectationError)
    end
  end

  describe "::teardown" do
    it "delegates to the space" do
      foo = double
      foo.should_receive(:bar)
      RSpec::Mocks::teardown
      expect do
        foo.bar
      end.to raise_error(/received unexpected message/)
    end
  end

  describe ".configuration" do
    it 'returns a memoized configuration instance' do
      expect(RSpec::Mocks.configuration).to be_a(RSpec::Mocks::Configuration)
      expect(RSpec::Mocks.configuration).to be(RSpec::Mocks.configuration)
    end
  end

  def file_contents_for(lib, filename)
    # http://rubular.com/r/HYpUMftlG2
    path = $LOAD_PATH.find { |p| p.match(/\/rspec-#{lib}(-[a-f0-9]+)?\/lib/) }
    file = File.join(path, filename)
    File.read(file)
  end

end
