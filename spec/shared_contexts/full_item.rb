# frozen_string_literal: true

RSpec.shared_context 'with a full item', shared_context: :metadata do
  let(:main_attack) do
    OpenStruct.new(id: 1, name: 'peck', damage: 'piercing')
  end

  let(:inventory) do
    [
      OpenStruct.new(id: 1, item: 'pebble'),
      OpenStruct.new(id: 2, item: 'fish'),
      OpenStruct.new(id: 3, item: 'necronomicon')
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
