# frozen_string_literal: true

RSpec.shared_context 'with a full item', shared_context: :metadata do
  let(:reference) do
    OpenStruct.new(id: 6, description: 'See page 10')
  end

  let(:main_attack) do
    OpenStruct.new(id: 1, name: 'peck', damage: 'piercing')
  end

  let(:inventory) do
    [
      OpenStruct.new(id: 1, item: 'pebble', reference: reference),
      OpenStruct.new(id: 2, item: 'fish', reference: reference),
      OpenStruct.new(id: 3, item: 'necronomicon', reference: reference)
    ]
  end

  let(:penguin) do
    OpenStruct.new(id: 1,
                   alt_id: 'boogins',
                   name: 'penguin',
                   tail: true,
                   claws: true,
                   stubbable_one: 'abc',
                   stubbable_two: 'def',
                   find_method_one: 'ghi',
                   find_method_two: 'jkl',
                   inventory: inventory,
                   main_attack: main_attack)
  end
end
