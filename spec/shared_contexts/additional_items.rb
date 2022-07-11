# frozen_string_literal: true

RSpec.shared_context 'with additional items', shared_context: :metadata do
  let(:trout) { OpenStruct.new(id: 2, name: 'trout', tail: true, claws: false) }
  let(:orangutan) { OpenStruct.new(id: 3, name: 'orangutan', tail: false, claws: false) }
end
