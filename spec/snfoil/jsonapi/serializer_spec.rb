# frozen_string_literal: true

require 'snfoil/jsonapi/serializer'
require 'ostruct'
require 'securerandom'
require 'shared_contexts/full_item'
require 'shared_contexts/additional_items'

RSpec.describe SnFoil::JSONAPI::Serializer do
  subject(:serializer) { serializer_class.new(*target, **options) }

  include_context 'with a full item'

  let(:serializer_class) { AnimalSerializer }
  let(:target) { penguin }
  let(:options) { {} }

  describe 'self#type' do
    it 'sets the snfoil_type for the class' do
      expect(AnimalSerializer.snfoil_type).to eq(:animals)
    end
  end

  describe '#self.id' do
    let(:overriden_class) { AnimalSerializer.clone }

    it 'sets the snfoil_id for the class' do
      overriden_class.id :uuid
      expect(overriden_class.snfoil_id).to eq(:uuid)
    end
  end

  describe '#self.render_relationships' do
    let(:serializer_class) { AnimalSerializer.clone }

    it 'sets the snfoil_render_relationships for the class' do
      serializer_class.render_relationships :partial
      expect(serializer_class.snfoil_render_relationships).to eq(:partial)
    end

    context 'when the value sent is not in the approved list' do
      it 'raises an error' do
        expect do
          serializer_class.render_relationships :pickle
        end.to raise_error SnFoil::JSONAPI::Serializer::Error
      end
    end
  end

  describe 'self#attributes' do
    it 'adds the attributes to the snfoil_tranforms' do
      expect(AnimalSerializer.snfoil_tranforms.map { |att| att[:param] }).to include(:tail, :claws)
    end
  end

  describe 'self#attribute' do
    it 'adds the attribute to the snfoil_tranforms' do
      expect(AnimalSerializer.snfoil_tranforms.map { |att| att[:param] }).to include(:name)
    end

    it 'applies a type of :attribute in the transform config' do
      expect(AnimalSerializer.snfoil_tranforms.find { |att| att[:param] == :name }[:type]).to eq :attribute
    end
  end

  describe 'self#belongs_to' do
    it 'adds the relationship to the snfoil_tranforms' do
      expect(AnimalSerializer.snfoil_tranforms.map { |att| att[:param] }).to include(:main_attack)
    end

    it 'applies a type of :belongs_to in the transform config' do
      expect(AnimalSerializer.snfoil_tranforms.find { |att| att[:param] == :main_attack }[:type]).to eq :belongs_to
    end

    context 'when defined without a serializer argument' do
      let(:overriden_class) { AnimalSerializer.clone }

      it 'raises an error' do
        expect do
          overriden_class.belongs_to :fake_relationship
        end.to raise_error SnFoil::JSONAPI::Serializer::Error
      end
    end
  end

  describe 'self#has_one' do
    it 'adds the relationship to the snfoil_tranforms' do
      expect(AnimalSerializer.snfoil_tranforms.map { |att| att[:param] }).to include(:reference)
    end

    it 'applies a type of :has_one in the transform config' do
      expect(AnimalSerializer.snfoil_tranforms.find { |att| att[:param] == :reference }[:type]).to eq :has_one
    end

    context 'when defined without a serializer argument' do
      let(:overriden_class) { AnimalSerializer.clone }

      it 'raises an error' do
        expect do
          overriden_class.has_one :fake_relationship
        end.to raise_error SnFoil::JSONAPI::Serializer::Error
      end
    end
  end

  describe 'self#has_many' do
    it 'adds the relationship to the snfoil_tranforms' do
      expect(AnimalSerializer.snfoil_tranforms.map { |att| att[:param] }).to include(:inventory_items)
    end

    it 'applies a type of :has_many in the transform config' do
      expect(AnimalSerializer.snfoil_tranforms.find { |att| att[:param] == :inventory_items }[:type]).to eq :has_many
    end

    context 'when defined without a serializer argument' do
      let(:overriden_class) { AnimalSerializer.clone }

      it 'raises an error' do
        expect do
          overriden_class.has_many :fake_relationships
        end.to raise_error SnFoil::JSONAPI::Serializer::Error
      end
    end
  end

  describe 'self#key_transform' do
    let(:overriden_class) { AnimalSerializer.clone }

    it 'sets the snfoil_key_transform for the class' do
      overriden_class.key_transform :dasherize
      expect(overriden_class.snfoil_key_transform).to eq(:dasherize)
    end
  end

  describe '#new' do
    let(:options) { { test: true } }

    it 'sets the objects' do
      expect(serializer.objects.length).to eq 1
      expect(serializer.objects).to include penguin
    end

    it 'sets the options' do
      expect(serializer.options).to eq options
    end
  end

  describe '#serializable_hash' do
    context 'when there is only one model' do
      it 'returns data as an hash' do
        expect(serializer.serializable_hash[:data]).to be_a Hash
      end
    end

    context 'when there is more than one model' do
      include_context 'with additional items'
      let(:target) { [penguin, trout, orangutan] }

      it 'returns data as an array' do
        expect(serializer.serializable_hash[:data]).to be_a Array
      end
    end

    context 'when there is no model' do
      let(:target) { [] }

      it 'returns nil' do
        expect(serializer.serializable_hash).to be_nil
      end
    end

    it 'sets the type' do
      binding.pry
      expect(serializer.serializable_hash[:data][:type]).to eq :animals
    end

    it 'includes the associated attributes as a hash' do
      expect(serializer.serializable_hash[:data][:attributes]).to be_a Hash
    end

    it 'includes the values of the model in the attributes' do
      expect(serializer.serializable_hash[:data][:attributes][:name]).to be 'penguin'
    end

    context 'when a key transform is explicitly set' do
      let(:serializer_class) { AnimalSerializer.clone }

      it 'tranforms the keys based on the tranform type' do
        serializer_class.key_transform :dasherize
        expect(serializer.serializable_hash[:data][:attributes].key?(:'opposable-thumb')).to be true
        expect(serializer.serializable_hash[:data][:attributes].key?(:opposable_thumb)).to be false
      end
    end

    context 'when a key tranform isn\'t explicitly set' do
      it 'defaults to the param' do
        expect(serializer.serializable_hash[:data][:attributes].key?(:opposable_thumb)).to be true
      end
    end

    context 'when an attribute is assigned' do
      context 'when it is configured with a key' do
        it 'returns the key with nil' do
          expect(serializer.serializable_hash[:data][:attributes][:cola]).to be true
        end
      end

      context 'when it doesn\'t exist on the model' do
        it 'returns the key with nil' do
          expect(serializer.serializable_hash[:data][:attributes][:eyes]).to be_nil
        end
      end

      context 'with the :with configuration' do
        before { allow(penguin).to receive(:find_method_one).and_call_original }

        it 'calls the method with the object to get the value' do
          expect(serializer.serializable_hash[:data][:attributes][:method]).to eq penguin.find_method_one
          expect(penguin).to have_received(:find_method_one).twice # one call for expect and one for serializer
        end
      end

      context 'with the :block configuration' do
        before { allow(penguin).to receive(:stubbable_one).and_call_original }

        it 'calls the block with the object to get the value' do
          expect(serializer.serializable_hash[:data][:attributes][:block]).to eq penguin.stubbable_one
          expect(penguin).to have_received(:stubbable_one).twice # one call for expect and one for serializer
        end
      end

      context 'with the :with and :block configuration' do
        before do
          allow(penguin).to receive(:find_method_two).and_call_original
          allow(penguin).to receive(:stubbable_two).and_call_original
        end

        it 'calls the method with the object to get the value' do
          expect(serializer.serializable_hash[:data][:attributes][:method_block]).to eq penguin.find_method_two
          expect(penguin).to have_received(:find_method_two).twice # one call for expect and one for serializer
          expect(penguin).not_to have_received(:stubbable_two)
        end
      end
    end

    context 'when id is explicitly set' do
      let(:serializer_class) { AnimalSerializer.clone }

      it 'sets id to the configuration' do
        serializer_class.id :alt_id
        expect(serializer.serializable_hash[:data][:id]).to eq 'boogins'
      end
    end

    context 'when id isn\'t explicitly set' do
      it 'sets id to :id' do
        expect(serializer.serializable_hash[:data][:id]).to eq 1
      end
    end
  end

  # describe '#parse_object' do

  #   context 'when a belongs_to relationship is assigned' do
  #     context 'when render_relationships is :none' do
  #     end

  #     context 'when render_relationships is :included' do
  #     end

  #     context 'when render_relationships is :partial' do
  #     end

  #     context 'when render_relationships is :full' do
  #     end
  #   end

  #   context 'when a has_one relationship is assigned' do
  #     context 'when render_relationships is :none' do
  #     end

  #     context 'when render_relationships is :included' do
  #     end

  #     context 'when render_relationships is :partial' do
  #     end

  #     context 'when render_relationships is :full' do
  #     end
  #   end

  #   context 'when a has_many relationship is assigned' do
  #     context 'when render_relationships is :none' do
  #     end

  #     context 'when render_relationships is :included' do
  #     end

  #     context 'when render_relationships is :partial' do
  #     end

  #     context 'when render_relationships is :full' do
  #     end
  #   end
  # end
end

class ReferenceSerializer
  include SnFoil::JSONAPI::Serializer

  type :references

  attributes :description
end

class AttackSerializer
  include SnFoil::JSONAPI::Serializer

  type :attacks

  attributes :name, :damage
end

class InventoryItemSerializer
  include SnFoil::JSONAPI::Serializer

  type :inventory_items

  attributes :item

  belongs_to :reference, serializer: ReferenceSerializer
end

class AnimalSerializer
  prepend SnFoil::JSONAPI::Serializer

  type :animals
  render_relationships :none

  attributes :tail, :claws, :opposable_thumb
  attribute :name
  attribute :eyes
  attribute :cola, key: :tail
  attribute :method, with: :find_method_one
  attribute(:block, &:stubbable_one)
  attribute(:method_block, with: :find_method_two, &:stubbable_two)

  belongs_to :main_attack, serializer: AttackSerializer
  belongs_to :reference, serializer: ReferenceSerializer
  has_one :equipped_item, serializer: InventoryItemSerializer
  has_many(:inventory_items, serializer: InventoryItemSerializer, &:inventory)

  def find_method_one(obj)
    obj.find_method_one
  end

  def find_method_two(obj)
    obj.find_method_two
  end
end
