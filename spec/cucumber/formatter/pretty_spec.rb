# frozen_string_literal: true

require 'spec_helper'
require 'cucumber/formatter/spec_helper'
require 'cucumber/formatter/pretty'
require 'cucumber/cli/options'

module Cucumber
  module Formatter
    describe Pretty do
      extend SpecHelperDsl
      include SpecHelper

      context 'with no options' do
        before(:each) do
          Cucumber::Term::ANSIColor.coloring = false
          @out = StringIO.new
          @formatter = described_class.new(actual_runtime.configuration.with_options(out_stream: @out, source: false))
        end

        describe 'given a single feature' do
          before(:each) do
            run_defined_feature
          end

          describe 'with a scenario' do
            define_feature <<-FEATURE
          Feature: Banana party

            Scenario: Monkey eats banana
              Given there are bananas
            FEATURE

            it 'outputs the scenario name' do
              expect(@out.string).to include('Scenario: Monkey eats banana')
            end

            it 'outputs the step' do
              expect(@out.string).to include('Given there are bananas')
            end
          end

          describe 'with a background' do
            define_feature <<~FEATURE
              Feature: Banana party
              
                Background: 
                  Given a tree
              
                Scenario: Monkey eats banana
                  Given there are bananas
            FEATURE

            it 'outputs the gherkin' do
              expect(@out.string).to include(self.class.feature_content)
            end

            it 'outputs the scenario name' do
              expect(@out.string).to include('Scenario: Monkey eats banana')
            end

            it 'outputs the step' do
              expect(@out.string).to include('Given there are bananas')
            end
          end

          describe 'with a scenario outline' do
            define_feature <<-FEATURE
          Feature: Fud Pyramid

            Scenario Outline: Monkey eats a balanced diet
              Given there are <Things>

              Examples: Fruit
               | Things  |
               | apples  |
               | bananas |
              Examples: Vegetables
               | Things   |
               | broccoli |
               | carrots  |
            FEATURE

            it 'outputs the scenario outline' do
              lines = <<-OUTPUT
              Examples: Fruit
               | Things  |
               | apples  |
               | bananas |
              Examples: Vegetables
               | Things   |
               | broccoli |
               | carrots  |
              OUTPUT

              lines.split("\n").each do |line|
                expect(@out.string).to include(line.strip)
              end
            end

            it 'has 4 undefined scenarios' do
              expect(@out.string).to include('4 scenarios (4 undefined)')
            end

            it 'has 4 undefined steps' do
              expect(@out.string).to include('4 steps (4 undefined)')
            end

            context 'when the examples table header is wider than the rows' do
              define_feature <<-FEATURE
          Feature: Monkey Business

            Scenario Outline: Types of monkey
              Given there are <Types of monkey>

              Examples:
               | Types of monkey |
               | Hominidae       |
              FEATURE

              it 'outputs the scenario outline' do
                lines = <<-OUTPUT
              Examples:
               | Types of monkey |
               | Hominidae       |
                OUTPUT

                lines.split("\n").each do |line|
                  expect(@out.string).to include line.strip
                end
              end
            end
          end

          # To ensure https://rspec.lighthouseapp.com/projects/16211/tickets/475 remains fixed.
          describe 'with a scenario outline with a pystring' do
            define_feature <<-FEATURE
          Feature:
            Scenario Outline: Monkey eats a balanced diet
              Given a multiline string:
                """
                Monkeys eat <things>
                """

              Examples:
               | things |
               | apples |
            FEATURE

            it 'outputs the scenario outline' do
              lines = <<-OUTPUT
              Given a multiline string:
                """
                Monkeys eat <things>
                """

              Examples:
               | things |
               | apples |
              OUTPUT

              lines.split("\n").each do |line|
                expect(@out.string).to include line.strip
              end
            end
          end

          describe 'with a step with a py string' do
            define_feature <<-FEATURE
          Feature: Traveling circus

            Scenario: Monkey goes to town
              Given there is a monkey called:
               """
               foo
               """
            FEATURE

            it 'displays the pystring nested' do
              expect(@out.string).to include <<OUTPUT
      """
      foo
      """
OUTPUT
            end
          end

          describe 'with a multiline step arg' do
            define_feature <<-FEATURE
          Feature: Traveling circus

            Scenario: Monkey goes to town
              Given there are monkeys:
               | name |
               | foo  |
               | bar  |
            FEATURE

            it 'displays the multiline string' do
              expect(@out.string).to include <<OUTPUT
    Given there are monkeys:
      | name |
      | foo  |
      | bar  |
OUTPUT
            end
          end

          describe 'with a table in the background and the scenario' do
            define_feature <<-FEATURE
          Feature: accountant monkey

            Background:
              Given table:
                | a | b |
                | c | d |
            Scenario:
              Given another table:
               | e | f |
               | g | h |
            FEATURE

            it 'displays the table for the background' do
              expect(@out.string).to include <<OUTPUT
    Given table:
      | a | b |
      | c | d |
OUTPUT
            end

            it 'displays the table for the scenario' do
              expect(@out.string).to include <<OUTPUT
    Given another table:
      | e | f |
      | g | h |
OUTPUT
            end
          end

          describe 'with a py string in the background and the scenario' do
            define_feature <<-FEATURE
          Feature: py strings

            Background:
              Given stuff:
                """
                foo
                """
            Scenario:
              Given more stuff:
                """
                bar
                """
            FEATURE

            it 'displays the background py string' do
              expect(@out.string).to include <<OUTPUT
    Given stuff:
      """
      foo
      """
OUTPUT
            end

            it 'displays the scenario py string' do
              expect(@out.string).to include <<OUTPUT
    Given more stuff:
      """
      bar
      """
OUTPUT
            end
          end

          describe 'with output from hooks' do
            define_feature <<-FEATURE
          Feature:
            Scenario:
              Given this step passes
            Scenario Outline:
              Given this step <status>
              Examples:
              | status |
              | passes |
            FEATURE

            define_steps do
              Before do
                log 'Before hook'
              end
              AfterStep do
                log 'AfterStep hook'
              end
              After do
                log 'After hook'
              end
              Given('this step passes') {}
            end

            it 'displays hook output appropriately ' do
              expect(@out.string).to include <<~OUTPUT
                Feature: 
                
                  Scenario: 
                      Before hook
                    Given this step passes
                      AfterStep hook
                      After hook
                
                  Scenario Outline: 
                    Given this step <status>
                
                    Examples: 
                      | status |
                      | passes |  Before hook, AfterStep hook, After hook
                
                2 scenarios (2 passed)
                2 steps (2 passed)
              OUTPUT
            end
          end

          describe 'with background and output from hooks' do
            define_feature <<-FEATURE
          Feature:
            Background:
              Given this step passes
            Scenario:
              Given this step passes
            FEATURE

            define_steps do
              Before do
                log 'Before hook'
              end
              AfterStep do
                log 'AfterStep hook'
              end
              After do
                log 'After hook'
              end
              Given('this step passes') {}
            end

            it 'displays hook output appropriately ' do
              expect(@out.string).to include <<~OUTPUT
                Feature: 
                
                  Background: 
                      Before hook
                    Given this step passes
                      AfterStep hook
                
                  Scenario: 
                    Given this step passes
                      AfterStep hook
                      After hook
                
                1 scenario (1 passed)
                2 steps (2 passed)
              OUTPUT
            end
          end

          describe 'with tags on all levels' do
            define_feature <<-FEATURE
          @tag1
          Feature:
            @tag2
            Scenario:
              Given this step passes
            @tag3
            Scenario Outline:
              Given this step passes
              @tag4
              Examples:
              | dummy |
              | dummy |
            FEATURE

            it 'includes the tags in the output ' do
              expect(@out.string).to include <<~OUTPUT
                @tag1
                Feature: 
                
                  @tag2
                  Scenario: 
                    Given this step passes
                
                  @tag3
                  Scenario Outline: 
                    Given this step passes
                
                    @tag4
                    Examples: 
                      | dummy |
                      | dummy |
              OUTPUT
            end
          end

          describe 'with comments on all levels' do
            define_feature <<-FEATURE
          #comment1
          Feature:
            #comment2
            Background:
              #comment3
              Given this step passes
            #comment4
            Scenario:
              #comment5
              Given this step passes
              #comment6
              | dummy |
            #comment7
            Scenario Outline:
              #comment8
              Given this step passes
              #comment9
              Examples:
                #comment10
                | dummy |
                #comment11
                | dummy |
                #comment12
            FEATURE

            it 'includes the all comments in the output' do
              expect(@out.string).to include <<~OUTPUT
                #comment1
                Feature: 
                
                  #comment2
                  Background: 
                    #comment3
                    Given this step passes
                
                  #comment4
                  Scenario: 
                    #comment5
                    Given this step passes
                      #comment6
                      | dummy |
                
                  #comment7
                  Scenario Outline: 
                    #comment8
                    Given this step passes
                
                    #comment9
                    Examples: 
                      #comment10
                      | dummy |
                      #comment11
                      | dummy |
                #comment12
              OUTPUT
            end
          end

          describe 'with the rule keyword' do
            define_feature <<-FEATURE
          Feature: Some rules

            Background: FB
              Given fb

            Rule: A
              The rule A description

              Background: AB
                Given ab

              Example: Example A
                Given a

            Rule: B
              The rule B description

              Example: Example B
                Given b
            FEATURE

            it 'ignores the rule keyword' do
              expect(@out.string).to include <<~OUTPUT
                Feature: Some rules
                
                  Background: FB
                    Given fb
                    Given ab
                
                  Example: Example A
                    Given a
                
                  Example: Example B
                    Given b
              OUTPUT
            end
          end
        end
      end

      context 'with --no-multiline passed as an option' do
        before(:each) do
          Cucumber::Term::ANSIColor.coloring = false
          @out = StringIO.new
          @formatter = described_class.new(actual_runtime.configuration.with_options(out_stream: @out, source: false, no_multiline: true))
        end

        describe 'given a single feature' do
          before(:each) do
            run_defined_feature
          end

          describe 'with a scenario' do
            define_feature <<-FEATURE
          Feature: Banana party

            Scenario: Monkey eats banana
              Given there are bananas
            FEATURE

            it 'outputs the scenario name' do
              expect(@out.string).to include 'Scenario: Monkey eats banana'
            end

            it 'outputs the step' do
              expect(@out.string).to include 'Given there are bananas'
            end
          end

          describe 'with a scenario outline' do
            define_feature <<-FEATURE
          Feature: Fud Pyramid

            Scenario Outline: Monkey eats a balanced diet
              Given there are <Things>

              Examples: Fruit
               | Things  |
               | apples  |
               | bananas |
              Examples: Vegetables
               | Things   |
               | broccoli |
               | carrots  |
            FEATURE

            it 'outputs the scenario outline' do
              lines = <<-OUTPUT
              Examples: Fruit
               | Things  |
               | apples  |
               | bananas |
              Examples: Vegetables
               | Things   |
               | broccoli |
               | carrots  |
              OUTPUT

              lines.split("\n").each do |line|
                expect(@out.string).to include line.strip
              end
            end

            it 'has 4 undefined scenarios' do
              expect(@out.string).to include '4 scenarios (4 undefined)'
            end

            it 'has 4 undefined steps' do
              expect(@out.string).to include '4 steps (4 undefined)'
            end
          end

          describe 'with a step with a py string' do
            define_feature <<-FEATURE
          Feature: Traveling circus

            Scenario: Monkey goes to town
              Given there is a monkey called:
               """
               foo
               """
            FEATURE

            it 'does not display the pystring' do
              expect(@out.string).not_to include <<OUTPUT
      """
      foo
      """
OUTPUT
            end
          end

          describe 'with a multiline step arg' do
            define_feature <<-FEATURE
          Feature: Traveling circus

            Scenario: Monkey goes to town
              Given there are monkeys:
               | name |
               | foo  |
               | bar  |
            FEATURE

            it 'does not display the multiline string' do
              expect(@out.string).not_to include <<OUTPUT
      | name |
      | foo  |
      | bar  |
OUTPUT
            end
          end

          describe 'with a table in the background and the scenario' do
            define_feature <<-FEATURE
          Feature: accountant monkey

            Background:
              Given table:
                | a | b |
                | c | d |
            Scenario:
              Given another table:
               | e | f |
               | g | h |
            FEATURE

            it 'does not display the table for the background' do
              expect(@out.string).not_to include <<OUTPUT
      | a | b |
      | c | d |
OUTPUT
            end

            it 'does not display the table for the scenario' do
              expect(@out.string).not_to include <<OUTPUT
      | e | f |
      | g | h |
OUTPUT
            end
          end

          describe 'with a py string in the background and the scenario' do
            define_feature <<-FEATURE
          Feature: py strings

            Background:
              Given stuff:
                """
                foo
                """
            Scenario:
              Given more stuff:
                """
                bar
                """
            FEATURE

            it 'does not display the background py string' do
              expect(@out.string).not_to include <<OUTPUT
      """
      foo
      """
OUTPUT
            end

            it 'does not display the scenario py string' do
              expect(@out.string).not_to include <<OUTPUT
      """
      bar
      """
OUTPUT
            end
          end
        end
      end

      context 'when using --expand mode' do
        let(:options) { { expand: true } }

        before(:each) do
          Cucumber::Term::ANSIColor.coloring = false
          @out = StringIO.new
          @formatter = described_class.new(actual_runtime.configuration.with_options(out_stream: @out))
        end

        describe 'given a single feature' do
          before(:each) do
            run_defined_feature
          end

          describe 'with a scenario outline' do
            define_feature <<-FEATURE
          Feature: Fud Pyramid

            Scenario Outline: Monkey eats a balanced diet
              Given there are <Things>

              Examples: Fruit
               | Things  |
               | apples  |
               | bananas |
              Examples: Vegetables
               | Things   |
               | broccoli |
               | carrots  |
            FEATURE

            it 'outputs the instantiated scenarios' do
              lines = <<-OUTPUT
              Examples: Fruit
                Example: | apples |
                  Given there are apples
                Example: | bananas |
                  Given there are bananas
              Examples: Vegetables
                Example: | broccoli |
                  Given there are broccoli
                Example: | carrots |
                  Given there are carrots
              OUTPUT

              lines.split("\n").each do |line|
                expect(@out.string).to include line.strip
              end
            end
          end

          describe 'with a scenario outline in en-lol' do
            define_feature <<-FEATURE
          # language: en-lol
          OH HAI: STUFFING

            MISHUN SRSLY: CUCUMBR
              I CAN HAZ IN TEH BEGINNIN <BEGINNIN> CUCUMBRZ
              WEN I EAT <EAT> CUCUMBRZ
              DEN I HAS <EAT> CUCUMBERZ IN MAH BELLY
              AN IN TEH END <KTHXBAI> CUCUMBRZ KTHXBAI

              EXAMPLZ:
               | BEGINNIN | EAT | KTHXBAI |
               |    3     |  2  |    1    |
            FEATURE

            it 'outputs localized text' do
              lines = <<-OUTPUT
          OH HAI: STUFFING

            MISHUN SRSLY: CUCUMBR
              I CAN HAZ IN TEH BEGINNIN <BEGINNIN> CUCUMBRZ
              WEN I EAT <EAT> CUCUMBRZ
              DEN I HAS <EAT> CUCUMBERZ IN MAH BELLY
              AN IN TEH END <KTHXBAI> CUCUMBRZ KTHXBAI
              EXAMPLZ:
                MISHUN: | 3 | 2 | 1 |
                  I CAN HAZ IN TEH BEGINNIN 3 CUCUMBRZ
                  WEN I EAT 2 CUCUMBRZ
                  DEN I HAS 2 CUCUMBERZ IN MAH BELLY
                  AN IN TEH END 1 CUCUMBRZ KTHXBAI
              OUTPUT

              lines.split("\n").each do |line|
                expect(@out.string).to include line.strip
              end
            end
          end
        end
      end

      context 'when using --expand mode with --source as an option' do
        let(:options) { { expand: true } }

        before(:each) do
          Cucumber::Term::ANSIColor.coloring = false
          @out = StringIO.new
          @formatter = described_class.new(actual_runtime.configuration.with_options(out_stream: @out, source: true))
        end

        describe 'given a single feature' do
          before(:each) do
            run_defined_feature
          end

          describe 'with a scenario outline' do
            define_feature <<-FEATURE
          Feature: Fud Pyramid

            Scenario Outline: Monkey eats a balanced diet
              Given there are <Things>

              Examples: Fruit
               | Things  |
               | apples  |
               | bananas |
              Examples: Vegetables
               | Things   |
               | broccoli |
               | carrots  |
            FEATURE

            it 'includes the source in the output' do
              lines = <<-OUTPUT
              Scenario Outline: Monkey eats a balanced diet # spec.feature:3
                Given there are <Things>                    # spec.feature:4
                Examples: Fruit
                  Example: | apples |      # spec.feature:8
                    Given there are apples # spec.feature:8
                  Example: | bananas |      # spec.feature:9
                    Given there are bananas # spec.feature:9
                Examples: Vegetables
                  Example: | broccoli |      # spec.feature:12
                    Given there are broccoli # spec.feature:12
                  Example: | carrots |      # spec.feature:13
                    Given there are carrots # spec.feature:13
              OUTPUT

              lines.split("\n").each do |line|
                expect(@out.string).to include line.strip
              end
            end

            context 'with very wide cells' do
              define_feature <<-FEATURE
            Feature: Monkey Business

              Scenario Outline: Types of monkey
                Given there are <Types of monkey>

                Examples:
                 | Types of monkey | Extra                  |
                 | Hominidae       | Very long cell content |
              FEATURE

              it 'the scenario line controls the source indentation' do
                lines = <<-OUTPUT
              Examples:
                 Example: | Hominidae | Very long cell content | # spec.feature:8
                   Given there are Hominidae                     # spec.feature:8

                OUTPUT

                lines.split("\n").each do |line|
                  expect(@out.string).to include(line.strip)
                end
              end
            end
          end
        end
      end

      context 'with snippets that contain relevant keyword replacements' do
        before(:each) do
          Cucumber::Term::ANSIColor.coloring = false
          @out = StringIO.new
          @formatter = described_class.new(actual_runtime.configuration.with_options(out_stream: @out, snippets: true))
          run_defined_feature
        end

        describe 'With a scenario that has undefined steps' do
          define_feature <<-FEATURE
          Feature: Banana party

            Scenario: many monkeys eat many things
              Given there are bananas and apples
              And other monkeys are around
              But there was only one chimpanzee
              When one monkey eats a banana
              And the other monkeys eat all the apples
              But the chimpanzee ate nothing 
              Then bananas remain
              But there are no apples left
              And there was never any marshmallows
          FEATURE

          it "offers the exact snippet of a 'Given' step name" do
            expect(@out.string).to include("Given('there are bananas and apples')")
          end

          it "replaces snippets containing 'And' to the previous 'Given' step name" do
            expect(@out.string).to include("Given('other monkeys are around')")
          end

          it "replaces snippets containing 'But' to the previous 'Given' step name" do
            expect(@out.string).to include("Given('there was only one chimpanzee')")
          end

          it "offers the exact snippet of a 'When' step name" do
            expect(@out.string).to include("When('one monkey eats a banana')")
          end

          it "replaces snippets containing 'And' to the previous 'When' step name" do
            expect(@out.string).to include("When('the other monkeys eat all the apples')")
          end

          it "replaces snippets containing 'But' to the previous 'When' step name" do
            expect(@out.string).to include("When('the chimpanzee ate nothing')")
          end

          it "offers the exact snippet of a 'Then' step name" do
            expect(@out.string).to include("Then('bananas remain')")
          end

          it "replaces snippets containing 'But' to the previous 'Then' step name" do
            expect(@out.string).to include("Then('there are no apples left')")
          end

          it "replaces snippets containing 'And' to the previous 'Then' step name" do
            expect(@out.string).to include("Then('there was never any marshmallows')")
          end
        end

        describe "With a scenario that uses *" do
          define_feature <<-FEATURE
          Feature: Banana party

            Scenario: many monkeys eat many things
              * there are bananas and apples
              * other monkeys are around
              When one monkey eats a banana
              * the other monkeys eat all the apples
              Then bananas remain
              * there are no apples left
          FEATURE

          it "replaces the first step with 'Given'" do
            expect(@out.string).to include("Given('there are bananas and apples')")
          end

          it "uses actual keywords as the previous 'Given' keyword for future replacements" do
            expect(@out.string).to include("Given('other monkeys are around')")
          end

          it "uses actual keywords as the previous 'When' keyword for future replacements" do
            expect(@out.string).to include("When('the other monkeys eat all the apples')")
          end

          it "uses actual keywords as the previous 'Then' keyword for future replacements" do
            expect(@out.string).to include("Then('there are no apples left')")
          end
        end

        describe "With a scenario where the only undefined step uses 'And'" do
          define_feature <<-FEATURE
          Feature:

            Scenario:
              Given this step passes
              Then this step passes
              And this step is undefined
          FEATURE

          define_steps do
            Given('this step passes') {}
          end

          it 'uses actual keyword of the previous passing step for the undefined step' do
            expect(@out.string).to include("Then('this step is undefined')")
          end
        end

        describe "With scenarios where the first step is undefined and uses '*'" do
          define_feature <<-FEATURE
          Feature:

            Scenario:
              * this step is undefined
              Then this step passes

            Scenario:
              * this step is also undefined
              Then this step passes
          FEATURE

          define_steps do
            Given('this step passes') {}
          end

          it "uses 'Given' as the actual keyword for the step in the first scenario" do
            expect(@out.string).to include("Given('this step is undefined')")
          end

          it "uses 'Given' as the actual keyword for the step in the last scenario" do
            expect(@out.string).to include("Given('this step is also undefined')")
          end
        end

        describe 'with a scenario in en-lol' do
          define_feature <<-FEATURE
          # language: en-lol
          OH HAI: STUFFING

            MISHUN: CUCUMBR
              I CAN HAZ IN TEH BEGINNIN CUCUMBRZ
              AN I EAT CUCUMBRZ
          FEATURE

          it 'uses actual keyword of the previous passing step for the undefined step' do
            expect(@out.string).to include("ICANHAZ('I EAT CUCUMBRZ')")
          end
        end
      end
    end
  end
end
