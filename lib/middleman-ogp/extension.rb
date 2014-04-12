module Middleman
  module OGP
    class OGPExtension < Extension
      option :namespaces, {}, 'Default namespaces'

      def after_configuration
        Middleman::OGP::Helper.namespaces = options[:namespaces] || {}
      end

      helpers do
        def ogp_tags(&block)
          Middleman::OGP::Helper.ogp_tags(data.page.ogp) do|name, value|
            if block_given?
              block.call name, value
            else
              concat_content tag(:meta, name: name, property: value)
            end
          end
        end
      end
    end

    module Helper
      include Padrino::Helpers::TagHelpers
      mattr_accessor :namespaces

      def self.ogp_tags(opts = {}, &block)
        opts ||= {}
        opts.symbolize_keys!
        options = namespaces.respond_to?(:to_h) ? namespaces.to_h : namespaces || {}
        options = options.deep_merge4(opts) {|k, old_value, new_value|
          if old_value.is_a?(Hash)
            if new_value.is_a? Hash
              old_value.deep_merge new_value
            else
              old_value[''] = new_value
              old_value
            end
          else
            new_value
          end
        }.symbolize_keys
        options.map{|k, v|
          og_tag([], v, k, &block)
        }.join("\n")
      end

      def self.og_tag(key, obj = nil, prefix = 'og', &block)
        case key
        when String, Symbol
          key = [key]
        when Hash
          prefix = obj if obj
          obj = key
          key = []
        end
        case obj
        when Hash
          obj.map{|k, v|
            og_tag(k.to_s.empty? ? key.dup : (key.dup << k.to_sym) , v, prefix, &block)
          }.join("\n")
        when Array
          obj.map{|v|
            og_tag(key, v, prefix, &block)
          }.join("\n")
        else
          block.call [prefix].concat(key).join(':'), obj.to_s
        end
      end

    end
  end
end


class Hash

  def deep_merge4(other_hash, &block)
    dup.deep_merge4!(other_hash, &block)
  end

  def deep_merge4!(other_hash, &block)
    other_hash.each_pair do |k,v|
      tv = self[k]
      if tv.is_a?(Hash) && v.is_a?(Hash)
        self[k] = tv.deep_merge4(v, &block)
      else
        self[k] = block && tv ? block.call(k, tv, v) : v
      end
    end
    self
  end

end
