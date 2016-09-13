require 'rails_helper'

# These tests split out testing diff elements, into separate tests, so for each
# we need a clean empty class as the State Machines are held at the class level
# and this is easier than trying to manage diff state machines in one class

class CheckoutEmpty < ActiveRecord::Base;  end
class CheckoutA < ActiveRecord::Base;  end
class CheckoutB < ActiveRecord::Base;  end
class CheckoutC < ActiveRecord::Base; end

module DatashiftJourney

  module Journey

    RSpec.describe MachineBuilder do

      describe 'DSL' do

        before(:all) do
          # Only required as we are testing multiple machines using same Class here
          # under normal circumstances build 1 journey per class
          ::StateMachines::Machine.ignore_method_conflicts = true
        end

        context "CheckoutEmpty - Simple MachineBuilder with no transitions" do

          let(:klass) { DatashiftJourney.journey_plan_class }

          before(:all) do
            DatashiftJourney.journey_plan_class = "CheckoutEmpty"
          end

          it 'does not break the extended Rails class' do
            expect(klass.new).to be
            expect(klass.create).to be
          end

          it "can build an empty machine with a given name" do
            machine = Journey::MachineBuilder.extend_journey_plan_class(machine_name: :checkout_empty)

            expect(machine).to be_a ::StateMachines::Machine

            expect(machine.name).to eq :checkout_empty
          end
        end

        context "CheckoutA - Simple Sequence" do

          before(:all) do
            DatashiftJourney.journey_plan_class = "CheckoutA"

            @machine = MachineBuilder.extend_journey_plan_class(machine_name: :checkout_a, initial: :page1) do
              sequence :page1, :page2, :page3, :page4
            end
          end

          let(:klass) { DatashiftJourney.journey_plan_class }

          it 'enables a sequential journey to be planned via list' do
            expect(@machine).to be_a ::StateMachines::Machine

            expect(@machine).to eq CheckoutA.state_machines[:checkout_a]

            checkout = CheckoutA.new

            # Methods are generated based on the StateMachine name, so where the default is state
            # you get the current column name from 'state_name' so for our tests  becomes checkout_a_name
            expect(checkout.checkout_a_name).to eq :page1
            expect(checkout.checkout_a).to eq "page1"
            expect(checkout.page1?).to eq true
            expect(checkout.page4?).to eq false

            # SO StateMachines::PathCollection seems to map related transitions together, and
            # progressively, so by the last it reports all 6 possible transitions (back/next )
            # not sure based on what yet
            expect( checkout.checkout_a_paths.last.size).to eq 6

            # events is a StateMachines::EventCollection
            # puts CheckoutA.state_machines[:checkout_a].events.each{|e| puts e.inspect }
            expect(CheckoutA.state_machines[:checkout_a].events.keys.sort).to eq [:back, :next]

            #puts CheckoutA.state_machines[:checkout_a].events[:back].known_states.inspect
            expect(
              CheckoutA.state_machines[:checkout_a].events[:back].known_states.sort
            ).to eq [:page1, :page2, :page3, :page4]

          end

          it 'creates back & next transitions for sequential journey' do
            checkout = CheckoutA.new

            # initially can only go fwd
            #puts CheckoutA.state_machines[:checkout_a].events.transitions_for(checkout).inspect

            expect( checkout.checkout_a_events.size).to eq 1
            expect( checkout.checkout_a_transitions.size).to eq 1

            expect(checkout.can_back?).to eq false
            expect(checkout.can_next?).to eq true
            checkout.next!

            # puts checkout.methods.sort.grep( /trans/ ).inspect

            # now we should be able to go back and fwd
            expect( checkout.checkout_a_events.size).to eq 2
            expect( checkout.checkout_a_transitions.size).to eq 2

            expect(checkout.can_back?).to eq true
            expect(checkout.can_next?).to eq true
          end
        end

        context "CheckoutB - Simple Sequence as Array" do

          before(:all) do
            DatashiftJourney.journey_plan_class = "CheckoutB"

            @machine = MachineBuilder.extend_journey_plan_class(machine_name: :checkout_b, initial: :array1) do
              sequence [:array1, :array2, :array3]
            end

          end

          let(:klass) { DatashiftJourney.journey_plan_class }

          it 'enables a sequential journey to be planned via array' do
            expect(
              CheckoutB.state_machines[:checkout_b].events[:back].known_states.sort
            ).to eq  [:array1, :array2, :array3]

            # If I add in This line :
            #     puts CheckoutB.state_machine.states.map(&:name).inspect
            #
            # It causes the next line to then fail - but it passes ok once outs is commented out !
            # NoMethodError:
            #   undefined method `state=' for #<CheckoutB:0x00000005489018>
            #Did you mean?  state?
            # /home/rubyuser/rubystack-2.2.3-3/rvm/gems/ruby-2.3.1/gems/activemodel-4.2.6/lib/active_model/attribute_methods.rb:433:in `method_missing'
            # /home/rubyuser/rubystack-2.2.3-3/rvm/gems/ruby-2.3.1/gems/state_machines-0.4.0/lib/state_machines/machine.rb:1074:in `write'

            checkout = klass.new

            expect(checkout.checkout_b_name).to eq :array1
            expect(checkout.checkout_b).to eq "array1"

            expect(checkout.array2?).to eq false

            expect(checkout.can_back?).to eq false
            expect(checkout.can_next?).to eq true
            checkout.next!
            expect(checkout.can_back?).to eq true
            expect(checkout.can_next?).to eq true
            checkout.next!
            expect(checkout.can_back?).to eq true
            expect(checkout.can_next?).to eq false
          end
        end

        context "Checkout - Complete API" do

          # See
          before(:all) do
            DatashiftJourney.journey_plan_class = "Checkout"

            [:visa, :mastercard, :paypal].each { |p| Payment.create( name: p) }
          end

          let(:payment_types) { [:visa, :mastercard, :paypal] }

          def check_state( checkout, expected_state )
            expect(checkout.state_name).to eq expected_state
            expect(checkout.state).to eq expected_state.to_s
            expect(checkout.state? expected_state).to eq true
          end

          def check_state_and_next!(checkout, expected_state )
            check_state( checkout, expected_state )

            expect(checkout.can_back?).to eq true
            expect(checkout.can_next?).to eq true

            checkout.next!
          end

          # STATE ENGINE DEFINITION

          it 'enables a complete journey to be planned via simple DSL', duff: true do

            MachineBuilder.extend_journey_plan_class(initial: :ship_address) do

              sequence [:ship_address, :bill_address]

              # first define the sequences
              split_sequence :visa_sequence, [:page_1_A, :page_2_A]

              split_sequence :mastercard_sequence, [:page_mastercard_1, :page_mastercard_2, :page_mastercard_3]

              split_sequence :paypal_sequence, []

              # now define the parent state and the routing criteria to each sequence

              split_on_equality( :payment,
                                 "payment_card",    # Helper method on Checkout that returns card type from Payment
                                 visa_sequence: 'visa',
                                 mastercard_sequence: 'mastercard',
                                 paypal_sequence: 'paypal'
              )

              sequence [:review, :complete ]
            end

            checkout = DatashiftJourney.journey_plan_class.new

            #puts checkout.state_names.inspect
            #puts Checkout.state_machine.states.map(&:name).inspect

            expect(checkout.state? :ship_address).to eq true
            expect(checkout.can_back?).to eq false    # this is the initial state
            expect(checkout.can_next?).to eq true
            checkout.next!

            check_state_and_next!(checkout, :bill_address )

            check_state( checkout, :payment )
            # But non of the conditions to move on from payment have been met yet so cannot next
            expect(checkout.can_next?).to eq false
            expect(checkout.can_back?).to eq true

            # TODO - should we also create an Event per state ?
            # Implications to how to manage acceptable transitions to that event
            #expect(checkout.payment?).to eq true

            checkout.create_payment!( card: :mastercard)

            # now the conditions should have been met - one block (mastercard_page) should match payment_card value
            expect(checkout.can_next?).to eq true
            checkout.next!

            check_state_and_next!(checkout, :page_mastercard_1 )
            check_state_and_next!(checkout, :page_mastercard_2 )
            check_state_and_next!(checkout, :page_mastercard_3 )

            check_state(checkout, :review )

            expect(checkout.can_next?).to eq true

            # TODO Implement BACK with event transitions - reverse criteria of the start of split next
            expect(checkout.can_back?).to eq false

            checkout.next!

            check_state( checkout, :complete )
            # End point so no next
            expect(checkout.can_next?).to eq false
            expect(checkout.can_back?).to eq true

            # TODO Implement BACK with event transitions - reverse criteria of the start of split next

            # Now go all way back to split point and try another path
=begin
            checkout.back until(!checkout.can_back? || checkout.payment?)

            check_state( checkout, :payment )

            checkout.payment.update(card: :paypal)

            checkout.next!

            check_state_and_next!(checkout, :paypal_page )
            check_state_and_next!(checkout, :review )
=end

          end

        end

      end
    end
  end
end
