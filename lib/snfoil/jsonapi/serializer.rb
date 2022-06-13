# frozen_string_literal: true

# Copyright 2021 Matthew Howes, Cliff Campbell

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#   http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'active_support/concern'

module SnFoil
  # ActiveSupport::Concern for adding SnFoil JSONAPI Serializer functionality to serializer file
  #
  # @author Matthew Howes
  #
  # @since 0.1.0
  module JSONAPI
    module Serializer
      extend ActiveSupport::Concern

      class_methods do
        attr_reader :snfoil_transforms

        def attribute(key, **options,&block)
          @snfoil_transforms ||= []
          @snfoil_transforms << {
            key: key,
            param: options[:param],
            block: block
          }
        end

        def attributes(*keys)
          keys.each { attribute(key) }
        end
      end

      def serialize(object)
        if object.is_a? Enumerable

        else

        end
      end

      private

      def serialize_object(object)
        
      end
    end
  end
end
