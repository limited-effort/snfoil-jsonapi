# frozen_string_literal: true

require 'spec_helper'
require 'ostruct'

RSpec.describe SnFoil::Policy do
  subject(:policy) { TestPolicy.new(entity, record) }

  let(:canary) { double }
  let(:entity) { User.new }
  let(:record) { OpenStruct.new }

  before do
    allow(canary).to receive(:sing)
    policy.canary = canary
  end

  describe 'self#permission' do
    it 'creates a method for an instance of the policy' do
      expect(policy.respond_to?(:block?)).to be true
    end

    it 'allows for block definitions and calls' do
      expect(policy.block?).to be true
      expect(canary).to have_received(:sing).with('block')
    end

    it 'allows for method definitions and calls' do
      expect(policy.method?).to be true
      expect(canary).to have_received(:sing).with('method')
    end

    context 'when an entity type is provided' do
      let(:policy2) { TestPolicy.new(Token.new, record) }

      it 'only tests for entities of that type' do
        expect(policy.method?).to be true
        expect(policy2.method?).to be false
        expect(canary).to have_received(:sing).once
      end
    end

    context 'when no entity type is define' do
      let(:policy2) { TestPolicy.new(Token.new, record) }

      before { policy2.canary = canary }

      it 'tests entities that match specifically and sends all others to the nil permission' do
        expect(policy.block?).to be true
        expect(policy2.block?).to be true
        expect(canary).to have_received(:sing).with('block').once
        expect(canary).to have_received(:sing).with('nil').once
      end
    end
  end

  describe 'inheritance' do
    it 'assigns instance variables to subclass' do
      expect(InheritedTestPolicy.instance_variables).to include(:@snfoil_permissions)
      expect(InheritedTestPolicy.instance_variable_get(:@snfoil_permissions).keys).to include(:block?)
    end

    it 'assigns methods the subclass' do
      expect(InheritedTestPolicy.new(entity, record).respond_to?(:block?)).to be true
    end
  end
end

class User; end

class Token; end

class TestPolicy
  include SnFoil::Policy

  permission :block?, User do
    sing('block')

    true
  end

  permission :block? do
    sing('nil')

    true
  end

  permission :method?, User, with: :test_method

  attr_accessor :canary

  def test_method
    sing('method')

    true
  end

  def sing(message)
    canary.sing(message)
  end
end

class InheritedTestPolicy < TestPolicy; end
