# frozen_string_literal: true

module SnFoil
  module JSONAPI
    module Serializer
      class Include
        class << self
          def parse_string(string, starting_output = {})
            string.split(',')
                  .reduce(starting_output) do |output, element|
                    traverse_and_inject(output, *element.split('.'))
                  end
          end

          private

          def traverse_and_inject(output, element, *string_array)
            element = element.to_sym
            output[element] = {} unless output.key? element

            output[element] = traverse_and_inject(output[element], *string_array) if string_array.length.positive?

            output
          end
        end
      end
    end
  end
end
