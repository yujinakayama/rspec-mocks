require 'spec_helper'

module RSpec
  module Mocks
    describe Configuration do
      let(:config) { Configuration.new }
      let(:mod_1)  { Module.new }
      let(:mod_2)  { Module.new }

      def instance_methods_of(mod)
        mod_1.instance_methods.map(&:to_sym)
      end

      it 'adds stub and should_receive to the given modules' do
        expect(instance_methods_of(mod_1)).not_to include(:stub, :should_receive)
        expect(instance_methods_of(mod_2)).not_to include(:stub, :should_receive)

        config.add_stub_and_should_receive_to(mod_1, mod_2)

        expect(instance_methods_of(mod_1)).to include(:stub, :should_receive)
        expect(instance_methods_of(mod_2)).to include(:stub, :should_receive)
      end

      shared_examples_for "configuring any instance mocks/stubs" do
        def sandboxed
          orig_any_instance = RSpec::Mocks.configuration.enable_any_instance_mocks?
          yield
        ensure
          configure_any_instance(orig_any_instance)
        end

        around(:each) { |ex| sandboxed(&ex) }

        shared_examples_for "any instance configuration" do
          let(:expected_arguments) {
            [
              /Using.*without enabling/,
              {:replacement=>"`RSpec::Mocks::Configuration.enable_any_instance_mocks = true` to enable any instance mocks/stubs"}
            ]
          }

          it "warns once when any instance has been implicitly enabled" do
            configure_default_any_instance
            expect(RSpec).to receive(:deprecate).with(*expected_arguments)
            invoke_any_instance_expectation
          end

          it "does not warn when any instance has been explicitly enabled" do
            configure_any_instance(true)
            expect(RSpec).not_to receive(:deprecate)
            invoke_any_instance_expectation
          end

          it "disables any instance expectations when any_instance has been explicitly disabled" do
            configure_any_instance(false)
            expect { invoke_any_instance_expectation }.to raise_error(NoMethodError)
          end

          it "removes and readds the methods when the syntax is disabled then reenabled" do
            configure_any_instance(false)
            expect { invoke_any_instance_expectation }.to raise_error(NoMethodError)
            configure_any_instance(true)
            expect { invoke_any_instance_expectation }.not_to raise_error
          end

          it "removes and adds the methods when the syntax is disabled then the configuration is reset" do
            configure_any_instance(false)
            expect { invoke_any_instance_expectation }.to raise_error(NoMethodError)

            configure_default_any_instance

            expect(RSpec).to receive(:deprecate).with(*expected_arguments)
            expect { invoke_any_instance_expectation }.not_to raise_error
          end
        end

        context "allow_any_instance_of" do
          def invoke_any_instance_expectation
            allow_any_instance_of(Object).to receive(:foo)
          end

          it "includes a call site in the deprecation" do
            configure_default_any_instance
            expect_deprecation_with_call_site(__FILE__, __LINE__ + 1)
            allow_any_instance_of(Object).to receive(:foo)
          end

          it_behaves_like "any instance configuration"
        end

        #context "expect_any_instance_of" do
        #  def invoke_any_instance_expectation
        #    @call_site = __LINE__+1
        #    allow_any_instance_of(Object).to receive(:foo)
        #  end

        #  it_behaves_like "any instance configuration"
        #end

        #context "any_instance" do
        #  def invoke_any_instance_expectation
        #    @call_site = __LINE__+1
        #    allow_any_instance_of(Object).to receive(:foo)
        #  end

        #  it_behaves_like "any instance configuration"
        #end
      end

      shared_examples_for "configuring the syntax" do
        def sandboxed
          orig_syntax = RSpec::Mocks.configuration.syntax
          yield
        ensure
          configure_syntax(orig_syntax)
        end

        around(:each) { |ex| sandboxed(&ex) }
        let(:dbl) { double }
        let(:should_methods)       { [:should_receive, :stub, :should_not_receive] }
        let(:should_class_methods) { [:any_instance] }
        let(:expect_methods)      { [:receive, :allow, :expect_any_instance_of, :allow_any_instance_of] }

        it 'defaults to enabling both the :should and :expect syntaxes' do
          expect(dbl).to respond_to(*should_methods)
          expect(self).to respond_to(*expect_methods)
        end

        context 'when configured to :expect' do
          before { configure_syntax :expect }

          it 'removes the should methods from every object' do
            expect(dbl).not_to respond_to(*should_methods)
          end

          it 'removes `any_instance` from every class' do
            expect(Class.new).not_to respond_to(*should_class_methods)
          end

          it 'adds the expect methods to the example group context' do
            expect(self).to respond_to(*expect_methods)
          end

          it 'reports that the syntax is :expect' do
            expect(configured_syntax).to eq([:expect])
          end

          it 'is a no-op when configured a second time' do
            expect(Syntax.default_should_syntax_host).not_to receive(:method_undefined)
            expect(::RSpec::Mocks::ExampleMethods).not_to receive(:method_added)
            configure_syntax :expect
          end
        end

        context 'when configured to :should' do
          before { configure_syntax :should }

          it 'adds the should methods to every object' do
            expect(dbl).to respond_to(*should_methods)
          end

          it 'adds `any_instance` to every class' do
            expect(Class.new).to respond_to(*should_class_methods)
          end

          it 'removes the expect methods from the example group context' do
            expect(self).not_to respond_to(*expect_methods)
          end

          it 'reports that the syntax is :should' do
            expect(configured_syntax).to eq([:should])
          end

          it "does not warn about the should syntax" do
            RSpec.should_not_receive(:deprecate)
            Object.new.should_not_receive(:bees)
          end

          it 'is a no-op when configured a second time' do
            Syntax.default_should_syntax_host.should_not_receive(:method_added)
            ::RSpec::Mocks::ExampleMethods.should_not_receive(:method_undefined)
            configure_syntax :should
          end
        end

        context 'when configured to [:should, :expect]' do
          before { configure_syntax [:should, :expect] }

          it 'adds the should methods to every object' do
            expect(dbl).to respond_to(*should_methods)
          end

          it 'adds `any_instance` to every class' do
            expect(Class.new).to respond_to(*should_class_methods)
          end

          it 'adds the expect methods to the example group context' do
            expect(self).to respond_to(*expect_methods)
          end

          it 'reports that both syntaxes are enabled' do
            expect(configured_syntax).to eq([:should, :expect])
          end

          it "does not warn about the should syntax" do
            RSpec.should_not_receive(:deprecate)
            Object.new.should_not_receive(:bees)
          end
        end

        context "by default" do
          before do
            configure_default_syntax
          end

          let(:expected_arguments) {
            [
              /Using.*without explicitly enabling/,
              {:replacement=>"the new `:expect` syntax or explicitly enable `:should`"}
            ]
          }

          it "it warns about should once, regardless of how many times it is called" do
            expect(RSpec).to receive(:deprecate).with(*expected_arguments)
            o = Object.new
            o2 = Object.new
            o.should_receive(:bees)
            o2.should_receive(:bees)

            o.bees
            o2.bees
          end

          it "warns about should not once, regardless of how many times it is called" do
            expect(RSpec).to receive(:deprecate).with(*expected_arguments)
            o = Object.new
            o2 = Object.new
            o.should_not_receive(:bees)
            o2.should_not_receive(:bees)
          end

          it "warns about stubbing once, regardless of how many times it is called" do
            expect(RSpec).to receive(:deprecate).with(*expected_arguments)
            o = Object.new
            o2 = Object.new

            o.stub(:faces)
            o2.stub(:faces)
          end

          it "doesn't warn about stubbing after a reset and setting should" do
            expect(RSpec).not_to receive(:deprecate)
            RSpec::Mocks.configuration.reset_syntaxes_to_default
            RSpec::Mocks.configuration.syntax = :should
            o = Object.new
            o2 = Object.new
            o.stub(:faces)
            o2.stub(:faces)
          end

          it "includes the call site in the deprecation warning" do
            obj = Object.new
            expect_deprecation_with_call_site(__FILE__, __LINE__ + 1)
            obj.stub(:faces)
          end
        end
      end

      describe "configuring rspec-mocks directly" do
        it_behaves_like "configuring the syntax" do
          def configure_syntax(syntax)
            RSpec::Mocks.configuration.syntax = syntax
          end

          def configured_syntax
            RSpec::Mocks.configuration.syntax
          end

          def configure_default_syntax
            RSpec::Mocks.configuration.reset_syntaxes_to_default
          end
        end

        it_behaves_like "configuring any instance mocks/stubs" do
          def configure_any_instance(enabled)
            RSpec::Mocks.configuration.enable_any_instance_mocks = enabled
          end

          def configure_default_any_instance
            RSpec::Mocks.configuration.reset_any_instance_to_default
          end
        end
      end

      describe "configuring using the rspec-core config API" do
        it_behaves_like "configuring the syntax" do
          def configure_syntax(syntax)
            RSpec.configure do |rspec|
              rspec.mock_with :rspec do |c|
                c.syntax = syntax
              end
            end
          end

          def configured_syntax
            RSpec.configure do |rspec|
              rspec.mock_with :rspec do |c|
                return c.syntax
              end
            end
          end

          def configure_default_syntax
            RSpec.configure do |rspec|
              rspec.mock_with :rspec do |c|
                c.reset_syntaxes_to_default
              end
            end
          end
        end
      end
    end
  end
end

