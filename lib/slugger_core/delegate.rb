module SluggerCore::Delegate
  def delegate(*syms, options)
    target = options[:to]
    syms.each { |sym| define_method(sym) { |*args, &block| send(target).send(sym, *args, &block) } }
  end
end
