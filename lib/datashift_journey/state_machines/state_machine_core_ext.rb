require_relative 'planner'

# rubocop:disable Metrics/BlockLength

StateMachines::Machine.class_eval do
  include DatashiftJourney::StateMachines::Planner
  extend DatashiftJourney::StateMachines::Planner

  # Create both a next link from lhs to rhs, and a back link from rhs to lhs

  def create_pair(lhs, rhs)
    create_back(lhs, rhs)
    create_next(rhs, lhs)
  end

  def create_pairs(sequence)
    #puts "DEBUG: Create Pairs - PROCESS #{sequence} "
    create_back_transitions sequence
    create_next_transitions sequence
  end

  def create_back(from, to, &block)
    #raise "Bad transitions supplied for Back - FROM #{from} - TO #{to}" if from.nil? || to.nil?
    if block_given?
      #puts "DEBUG: Creating BACK transition from #{from} to #{to} with Block from:\n#{caller.first}"
      transition(from => to, on: :back, if: block.call)
    else
      #puts "DEBUG: Creating BACK transition from #{from} to #{to}"
      transition(from => to, on: :back)
    end
  end

  # We use skip_fwd as the event type to avoid keyword next
  #
  # This will add usual helpers like
  #
  #   vehicle.skip_fwd?                 # => true
  #   vehicle.can_skip_fwd?             # => true
  #
  def create_next(from, to, &block)
    raise "Bad transitions supplied for Next - FROM #{from} - TO #{to}" if from.nil? || to.nil?
    if block_given?
      #puts "DEBUG: Creating NEXT transition from #{from} to #{to} with Block from:\n#{caller.first}"
      transition(from => to, on: :skip_fwd, if: block.call)
    else
      #puts "DEBUG: Creating NEXT transition from #{from} to #{to}"
      transition(from => to, on: :skip_fwd)
    end
  end

  # BACK - Create a 'back' event for each step in list
  # Automatically removes first state, as nothing to go back to from that state
  # You can exclude any other steps with the except list
  #
  def create_back_transitions(journey, except = [])
    # puts "DEBUG: Creating BACK transitions for #{journey.inspect}"
    journey.drop(1).each_with_index do |t, i|
      next if except.include?(t)
      create_back(t, journey[i]) # n.b previous index is actually i not (i-1) due to the drop
    end
  end

  # NEXT - Create a 'next' event for each step (apart from last) in journey
  # You can exclude  any other steps with the except list
  #
  def create_next_transitions(journey, except = [])
    #puts "DEBUG: Creating NEXT transitions for #{journey.inspect}"
    journey[0...-1].each_with_index do |t, i|
      next if except.include?(t)
      create_next(t, journey[i + 1])
    end
  end
end
