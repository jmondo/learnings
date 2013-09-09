# Ruby tips and tricks
args.select { |arg| Hash === arg  } # use the === comparison for is_a?
args.grep(Hash)                     # do the same thing, but more cleanly. grep uses ===
args.reject! {|a| a.blank? }        # it's like compact, but for blank strings /and/ nils

# Rails tips and tricks
Array.wrap(value)                   # is like [thing_that_could_be_array].flatten, and like Array(thing), except this won't convert a hash to an array
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
  # :includes_values, :eager_load_values, :preload_values,
  # :select_values, :group_values, :order_values, :joins_values,
  # :where_values, :having_values, :bind_values,
  # :limit_value, :offset_value, :lock_value, :readonly_value, :create_with_value,
  # :from_value, :reordering_value, :reverse_order_value,
  # :uniq_value

Teacher.scoped                # turns a model into a relation
Teacher.eager_load(:students) # forces one query with temp tables to eager load
Teacher.preload(:students)    # runs 2 queries to eager load students
Teacher.includes(:students)   # decides whether it's more efficient to do eager_load or preload and does it (see usage of eager_loading? in relation.rb)
Teacher.scoped.extending(SomeModule) # extends the scope with the module (or you can use a block to define methods, or both)
Teacher.scoped.reverse_order  # reverses the final order of the results

# Great refactors
# https://github.com/rails/rails/commit/b68407f7f013ce3b08d1273ac3c2ffd7a8a510c9


# ActiveSupport

# with SafeBuffer (html safe), addition is not commutative (order changes behavior) :(
"<script></script>".html_safe + "<script></script>" #=> safe (unsafe part gets sanitized)
  #=> HTML: <script></script> '<script></script>'
"<script></script>" + "safe".html_safe #=> unsafe all the way
  #=> HTML: '<script></script> <script></script>'

# ActiveSupport::OrderedOptions is a special hash with dot operator setter/getter - snippet:
module ActionDispatch
  class Railtie < Rails::Railtie
    config.action_dispatch = ActiveSupport::OrderedOptions.new
    config.action_dispatch.x_sendfile_header = nil
    config.action_dispatch.ip_spoofing_check = true
    # ...

config.action_dispatch.ip_spoofing_check #=> true

# you can make one like above or by passing an existing hash with [], NOT .new
options = ActiveSupport::OrderedOptions[{option_a: true, option_b: false}]
options.option_b #=> false

# ActiveSupport::StringInquirer is a whole class to just allow you to question mark booleans.
# it controls Rails.env.production?

ActiveSupport::StringInquirer.new("so_bomb").so_bomb? #=> true

# TimeWithZone... Time isn't that complicated!
# http://api.rubyonrails.org/files/activesupport/lib/active_support/time_with_zone_rb.html
# ruby only lets you see the time in your system time zone or UTC. rails introduces time zones.
Time.now              #=> 2013-09-07 21:55:01 -0700 (pacific time - my system time - ruby)
Time.zone             #=> TimeZone object (rails), UTC by default configured by your rails app


Time.zone = 'Eastern Time (US & Canada)'
# my system time is in Pacific
Time.zone.now               #=> rails TimeWithZone in eastern time!
Time.now.in_time_zone       #=> rails TimeWithZone in eastern time! (same thing)
Time.zone.now.localtime     #=> ruby Time in pacific time (same as Time.now)
Time.zone.now.to_time       #=> ruby Time in pacific time (same as Time.now)
Time.zone.now.to_datetime   #=> ruby DateTime in eastern time
Time.now.in_time_zone.to_time.in_time_zone.to_time... #switch back and forth
Time.zone.now.utc           #=> ruby Time in UTC
                            #=> 2013-09-09 03:50:08 UTC (like, the current time on the east coast represented in UTC)
Time.zone.now.time          #=> ruby Time in UTC, but replaces time zone with UTC without adjusting for the time difference
                            #=> 2013-09-08 23:50:08 UTC (like, not the current time at all)

# can use the all the ruby Time methods on TimeWithZone via method missing and will still be wrapped as TimeWithZone
# all times are stored in UTC in the database, but if you want to observe your rails app's Time.zone
# you should always lead with Time.zone (Time.zone.now, Time.zone.parse, etc), otherwise everything will
# be at the will of your server's system time. And don't use .time.
