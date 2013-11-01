module DSL::DSL
  def self.included(base)
    base.instance_eval do
      extend ClassMethods
      dsl_attribute :name
    end
  end

  module ClassMethods
    def new!(options = {}, &block)
      inst = new(options, &block)
      instances[inst.name] = inst
    end

    def dsl_attribute(*names)
      names.each do |name|
        define_method(name) do |val = nil|
          val.nil? ? instance_variable_get(:"@#{name}")
                   : instance_variable_set(:"@#{name}", val)
        end
      end
    end
    private :dsl_attribute

    def dsl_class_attribute(name, klass)
      unless klass.ancestors.include?(DSL::DSL)
        raise "#{self.class}.dsl_class_attribute requires a class that includes DSL"
      end
      define_method(name) do |sym = nil, &block|
        new_value = case
                    when !block.nil? && !sym.nil? then klass.new!(:name => sym, &block)
                    when block.nil?               then klass.instances[sym]
                    when sym.nil?                 then klass.new!(:name => :"#{self.name}_#{klass}", &block)
                    end
        instance_variable_set(:"@#{name}", new_value) unless new_value.nil?
        instance_variable_get(:"@#{name}")
      end
    end
    private :dsl_class_attribute

    def default_value(name, val = nil)
      default_values[name] = block_given? ? yield : val
    end
    private :default_value

    def default_values
      @default_values ||= {}
    end

    def instances
      @instances ||= {}
    end

    def generate_unique_name
      name = nil
      (0..(1.0 / 0.0)).each do |n|
        name = :"#{self.name.demodulize}_#{n}"
        break unless instances.has_key?(name)
      end
      name
    end

    def [](sym)
      instances[sym]
    end
  end

  def to_s
    "#{self.class.name} (#{
      instance_variables.map { |var|
        "#{var} = #{instance_variable_get(var)}"
      }.join(', ')
    })"
  end

  def [](var)
    instance_variable_get(:"@#{var}")
  end

  def []=(var, val)
    instance_variable_set(:"@#{var}", val)
  end

  def ==(other_dsl)
    (other_dsl.class == self.class) && (other_dsl.name == self.name)
  end
  def initialize(options = {}, &block)
    self.class.default_values.merge(options).each do |k, v|
      v = v.dup rescue v unless v.class.ancestors.include?(DSL::DSL)
      public_send(k, v)
    end
    instance_eval(&block) unless block.nil?
    name(self.class.generate_unique_name) if name.nil?
    self.instance_variable_get(:@name).freeze
  end

  def to_hash
    Hash[instance_variables.map { |ivar| [ivar.to_s[1..-1].to_sym, instance_variable_get(ivar)] }]
  end

  def ensure_present!(*syms)
    syms.each do |sym|
      if instance_variable_get(:"@#{sym}").nil?
        method_name = /.*`(?<method_name>.+)'$/.match(caller[2])[:method_name]
        raise "The following must be present to use #{self.class}##{method_name}: #{sym}"
      end
    end
  end
  private :ensure_present!
end
