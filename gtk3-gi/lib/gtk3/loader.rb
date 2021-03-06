# Copyright (C) 2014  Ruby-GNOME2 Project Team
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2.1 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA

module Gtk
  class Loader < GObjectIntrospection::Loader
    def initialize(base_module, init_arguments)
      super(base_module)
      @init_arguments = init_arguments
    end

    private
    def pre_load(repository, namespace)
      call_init_function(repository, namespace)
    end

    def call_init_function(repository, namespace)
      init_check = repository.find(namespace, "init_check")
      arguments = [
        1 + @init_arguments.size,
        [$0] + @init_arguments,
      ]
      succeeded, argv, error = init_check.invoke(:arguments => arguments)
      @init_arguments.replace(argv[1..-1])
      raise error unless succeeded
    end

    def post_load(repository, namespace)
      require_libraries
    end

    def require_libraries
      require "gtk3/box"
      require "gtk3/button"
      require "gtk3/label"
      require "gtk3/scrolled-window"
      require "gtk3/text-buffer"
      require "gtk3/tree-iter"
      require "gtk3/tree-selection"
      require "gtk3/tree-store"
      require "gtk3/tree-view-column"
      require "gtk3/window"

      require "gtk3/deprecated"
    end

    def load_function_info(info)
      name = info.name
      case name
      when "init", /_get_type\z/
        # ignore
      else
        super
      end
    end

    # patch for returning "self" from setter methods.
    # TODO: should be fixed in Ruby/GObjectIntrospection.
    def define_method(info, klass, method_name)
      unlock_gvl = should_unlock_gvl?(info, klass)
      validate = lambda do |arguments|
        validate_arguments(info, "#{klass}\##{method_name}", arguments)
      end
      if klass.method_defined?(method_name) and
          klass.instance_method(method_name).owner == klass
        klass.__send__(:remove_method, method_name)
      end
      function_info_p = (info.class == GObjectIntrospection::FunctionInfo)
      klass.__send__(:define_method, method_name) do |*arguments, &block|
        arguments = [self] + arguments if function_info_p
        validate.call(arguments, &block)
        if block.nil? and info.require_callback?
          Enumerator.new(self, method_name, *arguments)
        else
          options = {
            :arguments => arguments,
            :unlock_gvl => unlock_gvl,
          }
          options[:receiver] = self unless function_info_p
          # patch for returning "self" from setter methods.
          #info.invoke(options, &block)
          return_value = info.invoke(options, &block)
          if /\Aset_/ =~ method_name and return_value.nil?
            self
          else
            return_value
          end
        end
      end
    end
  end
end
