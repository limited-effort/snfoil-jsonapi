module SnFoil
	module JSONAPI
		module Serializer
      class Include
        class << self
          def parse_string(string, output = {})
            string.split(',')
                  .reduce(output) do |output, element|
                    traverse_and_inject(output, *element.split('.'))
                  end
          end

          private

          def traverse_and_inject(output, element, *string_array)
            element = element.to_sym
            output[element] = {} unless output.key? element
          
            if string_array.length.zero?
              return output
            else
              output[element] = traverse_and_inject(output[element], *string_array)
              output
            end
          end
        end
      end
    end
  end
end