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
require 'active_support/inflector'

module SnFoil
  module JSONAPI
    # ActiveSupport::Concern for adding SnFoil JSONAPI Serializer functionality to serializer file
    #
    # @author Matthew Howes
    #
    # @since 0.1.0
    module Serializer
      extend ActiveSupport::Concern

      class Error < StandardError; end

      class_methods do
        attr_reader :snfoil_type, :snfoil_id,
                    :snfoil_tranforms, :snfoil_key_transform

        def type(new_type)
          @snfoil_type = new_type
        end

        def id(id_param)
          @snfoil_id = id_param
        end

        def key_transform(tranform_type)
          @snfoil_key_transform = tranform_type
        end

        def attribute(param, with: nil, **options, &block)
          add_transform(param, :attribute, with, block, options)
        end

        def belongs_to(param, serializer: nil, with: nil, **options, &block)
          raise SnFoil::JSONAPI::Serializer::Error, "belongs_to relationship #{param} defined without a serilizer" unless serializer

          add_transform(param, :belongs_to, with, block, options.merge(serializer: serializer))
        end
        alias_method :has_one, :belongs_to

        def has_many(param, serializer: nil, with: nil, **options, &block) # rubocop:disable Naming/PredicateName reason: common nomanclature
          raise SnFoil::JSONAPI::Serializer::Error, "has_many relationship #{param} defined without a serilizer" unless serializer

          add_transform(param, :has_many, with, block, options.merge(serializer: serializer))
        end

        def attributes(*params, **options)
          params.map { |param| attribute(param, **options) }
        end

        private

        def add_transform(param, type, method, block, options)
          @snfoil_tranforms ||= []
          @snfoil_tranforms << { type: type, param: param, method: method, block: block, options: options.merge(param: param) }
        end
      end

      attr_reader :objects

      def initialize(*objects)
        @objects = objects
      end

      def serializable_hash
        return if @objects.length.zero?
        return { data: parse_object(objects[0]) } if @objects.length == 1

        { data: objects.map { |object| parse_object(object) } }
      end

      def parse_object(object)
        {
          id: get_object_id(object),
          type: self.class.snfoil_type,
          attributes: get_object_attributes(object)
        }
      end

      private # rubocop:disable Lint/UselessAccessModifier reason: linter is wrong. not redundant

      def get_object_id(object)
        object.send(self.class.snfoil_id || :id)
      end

      def get_object_attributes(object)
        self.class.snfoil_tranforms.each_with_object({}) do |transform, hash|
          hash[get_param_value(transform[:param])] = get_object_attribute(object, transform)
          hash
        end
      end

      def get_object_attribute(object, transform)
        return call_method(object, transform) if transform[:method]
        return call_block(object, transform) if transform[:block]

        call_param(object, transform)
      end

      def get_param_value(param)
        return param unless self.class.snfoil_key_transform

        ActiveSupport::Inflector.send(self.class.snfoil_key_transform, param.to_s).to_sym
      end

      def call_method(object, transform)
        if self.class.instance_method(transform[:method]).arity.abs > 1
          send(transform[:method], object, **transform[:options])
        else
          send(transform[:method], object)
        end
      end

      def call_block(object, transform)
        if transform[:block].arity.positive?
          instance_exec(object, **transform[:options], &transform[:block])
        elsif transform[:block].arity.negative?
          instance_exec(object, &transform[:block])
        else
          instance_exec(&transform[:block])
        end
      end

      def call_param(object, transform)
        object.send(transform.dig(:options, :key) || transform[:param])
      end
    end
  end
end
