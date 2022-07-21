# frozen_string_literal: true

require 'snfoil/jsonapi/serializer/include'

RSpec.describe SnFoil::JSONAPI::Serializer::Include do
  describe 'self#parse_string' do
    let(:string) { 'test.foo.bar,test.foo.bing,baz,x.y,x' }
    let(:output) { described_class.parse_string(string) }

    it 'parses included string' do
      expect(output).to be_a Hash
    end

    it 'parses deeply nested relationships' do
      expect(output[:test][:foo].keys).to eq %i[bar bing]
    end

    it 'does overwrite earlier elements' do
      expect(output.dig(:x, :y)).to be_a Hash
    end
  end
end
