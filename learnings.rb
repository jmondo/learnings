# Ruby tips and tricks
args.select { |arg| Hash === arg  } # use the === comparison for is_a?
args.reject! {|a| a.blank? } # it's like compact, but for blank strings /and/ nils
Array.wrap(value) # is like [thing_that_could_be_array].flatten, and like Array(thing), except this won't convert a hash to an array

def reorder(*args)
  # ...
  relation.order_values = args.flatten # lets you pass args as args or array (either way, they become an array)
  # ...


# blocks on procs on blocks
def select(value = Proc.new) # see explanation below and https://github.com/rails/rails/commit/604281221ce0eb71d7b922be2cd012018cca1fbf#activerecord/lib/active_record/relation/query_methods.rb
  if block_given?
    to_a.select {|*block_args| value.call(*block_args) } # calls the proc you passed in for each thing in the enumerable (no matter how many params it passes)
  else
  # ...

  # explanation:
  def select(value = nil) # allows 0 or 1 args, but the value can't be a block (you would have to use yield)
  def select(&value) # expects 0 args and sets value to the block as a proc, so can't pass non-block value
  def select(value = Proc.new) # allows 0 or 1 args, value = the first arg passed or the block as a proc (Proc.new assumes the value of the block - see Proc.new docs), if neither, an empty proc is created (which raises an error as intended)


def extending(*modules)
  modules << Module.new(&Proc.new) if block_given?

def extending(*modules)
  # Proc.new grabs the block as a proc (just like it does above)
  # the & passes it like a block (not a param) - like select(:thing) versus select(&:thing) == select {|a| a.thing}
  # note that by doing << you can pass this thing a set of modules as params /and/ a block
  modules << Module.new(&Proc.new) if block_given?
  # ...
end

# end block on procs on blocks

# Query Methods
Teacher.where(name: 'Amy').where_values #shows all the where's in a relation
  :includes_values, :eager_load_values, :preload_values,
  :select_values, :group_values, :order_values, :joins_values,
  :where_values, :having_values, :bind_values,
  :limit_value, :offset_value, :lock_value, :readonly_value, :create_with_value,
  :from_value, :reordering_value, :reverse_order_value,
  :uniq_value

Teacher.eager_load(:students) # forces one query with temp tables to eager load
Teacher.preload(:students)    # runs 2 queries to eager load students
Teacher.includes(:students)   # decides whether it's more efficient to do eager_load or preload and does it (see usage of eager_loading? in relation.rb)
