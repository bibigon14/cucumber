# frozen_string_literal: true

require 'cucumber/formatter/fail_fast'
require 'cucumber/core'
require 'cucumber/core/gherkin/writer'
require 'cucumber/core/test/result'
require 'cucumber/core/filter'
require 'cucumber'
require 'support/standard_step_actions'

module Cucumber
  module Formatter
    describe FailFast do
      include Cucumber::Core
      include Cucumber::Core::Gherkin::Writer

      let(:configuration) { Cucumber::Configuration.new }

      before { described_class.new(configuration) }

    context 'with a failing scenario' do
      before(:each) do
        @gherkin = gherkin('foo.feature') do
          feature do
            scenario do
              step 'failing'
            end

            scenario do
              step 'failing'
            end
          end
        end
      end

      after(:each) do
        Cucumber.wants_to_quit = false
      end

      it 'sets Cucumber.wants_to_quit' do
        execute [@gherkin], [StandardStepActions.new], configuration.event_bus

        expect(Cucumber.wants_to_quit).to be true
      end
    end

    context 'with a passing scenario' do
      before(:each) do
        @gherkin = gherkin('foo.feature') do
          feature do
            scenario do
              step 'passing'
            end
          end
        end
      end

        it "doesn't set Cucumber.wants_to_quit" do
          execute [@gherkin], [StandardStepActions.new], configuration.event_bus
          expect(Cucumber.wants_to_quit).to be_falsey
        end
      end

      context 'with an undefined scenario' do
        before(:each) do
          @gherkin = gherkin('foo.feature') do
            feature do
              scenario do
                step 'undefined'
              end
            end
          end
        end


        it "doesn't set Cucumber.wants_to_quit" do
          execute [@gherkin], [StandardStepActions.new], configuration.event_bus

          expect(Cucumber.wants_to_quit).to be_falsey
        end

        context 'when in strict mode' do
          let(:configuration) { Cucumber::Configuration.new strict: Cucumber::Core::Test::Result::StrictConfiguration.new([:undefined]) }

          it 'sets Cucumber.wants_to_quit' do
            execute [@gherkin], [StandardStepActions.new], configuration.event_bus
            expect(Cucumber.wants_to_quit).to be_truthy
          end
        end
      end
    end
  end
end
