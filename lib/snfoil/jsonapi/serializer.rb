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
        attr_reader :snfoil_type, :snfoil_id, :snfoil_tranforms, :snfoil_key_transform,
                    :snfoil_render_relationships

        def type(new_type)
          @snfoil_type = new_type
        end

        def id(id_param)
          @snfoil_id = id_param
        end

        def render_relationships(view)
          unless %i[none included partial full].include?(view)
            raise SnFoil::JSONAPI::Serializer::Error, 'render_relationships must be one of the following: :none, :included, :partial, :full'
          end

          @snfoil_render_relationships = view
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

        def has_one(param, serializer: nil, with: nil, **options, &block) # rubocop:disable Naming/PredicateName reason: common nomanclature
          raise SnFoil::JSONAPI::Serializer::Error, "has_one relationship #{param} defined without a serilizer" unless serializer

          add_transform(param, :has_one, with, block, options.merge(serializer: serializer))
        end

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

      attr_reader :objects, :options

      def initialize(*objects, **options)
        @objects = objects
        @options = options
      end

      def serializable_hash
        return if @objects.length.zero?

        parsed_data = @objects.map { |obj| parse_object(obj) }
        included = parsed_data.map { |d| parse_includes(d[:relationships]) }.flatten
        parsed_data = simplify_relationships(parsed_data)

        parsed_data = parsed_data[0] if parsed_data.length == 1
        {
          data: parsed_data,
          included: included
        }
      end

      private # rubocop:disable Lint/UselessAccessModifier reason: linter is wrong. not redundant

      def parse_object(object)
        attributes = object_attributes(object)
        relationships = object_relationships(object)

        hash = { id: object_id(object), type: self.class.snfoil_type }
        hash[:attributes] = attributes unless attributes.empty?
        hash[:relationships] = relationships
        hash
      end

      def parse_includes(relationships)
        return [] if relationships.nil? || relationships.empty?

        relationships = relationships.keys.map do |relationship|
          data = relationships.dig(relationship, :data)
          data = [data] unless data.is_a? Array
          included = relationships.dig(relationship, :included) || []
          [*data, *included]
        end.flatten.compact

        relationships.uniq { |r| "#{r[:type]}#{r[:id]}" }
      end

      def simplify_relationships(datas)
        datas.map do |data|
          next data if data[:relationships].nil? || data[:relationships].empty?

          data[:relationships] = data[:relationships].keys.each_with_object({}) do |key, output|
            relationship = data[:relationships][key]

            output[key] = if relationship && relationship[:data].is_a?(Array)
                            relationship[:data].map { |rdata| simplify_relationship(rdata) }
                          else
                            simplify_relationship(relationship&.dig(:data))
                          end
          end
          data
        end
      end

      def simplify_relationship(relationship)
        return { data: nil } unless relationship

        { data: { type: relationship[:type], id: relationship[:id] } }
      end

      def object_id(object)
        object.send(self.class.snfoil_id || :id)
      end

      def object_attributes(object)
        self.class.snfoil_tranforms.select { |t| t[:type] == :attribute }.each_with_object({}) do |transform, hash|
          hash[get_param_value(transform[:param])] = get_object_attribute(object, transform)
          hash
        end
      end

      def get_object_attribute(object, transform)
        return call_method(object, transform) if transform[:method]
        return call_block(object, transform) if transform[:block]

        call_param(object, transform)
      end

      def object_relationships(object)
        return [] if self.class.snfoil_render_relationships == :none

        relationship_transforms.each_with_object({}) do |transform, output|
          attribute = get_object_attribute(object, transform)
          attribute = [attribute] unless attribute.nil? || transform[:type] == :has_many

          output[transform[:param]] = transform[:options][:serializer].new(*attribute, **options, includes: options.dig(:includes, transform[:param]))
                                                                      .serializable_hash
        end
      end

      def relationship_transforms
        if self.class.snfoil_render_relationships.nil? || self.class.snfoil_render_relationships == :full
          self.class.snfoil_tranforms.reject { |t| t[:type] == :attribute }
        else
          filtered_object_relationships
        end
      end

      def filtered_object_relationships
        includes = options[:includes] || {}

        self.class.snfoil_tranforms.select do |t|
          next false if t[:type] == :attribute
          next true if t[:type] == :belongs_to && self.class.snfoil_render_relationships == :partial

          includes.key? t[:param]
        end
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
