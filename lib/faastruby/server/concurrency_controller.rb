module FaaStRuby
  class ConcurrencyController
    def self.store
      @@store ||= {} 
    end
    attr_accessor :params, :name, :max, :type
    def initialize(name, max: 1, type:)
      @type = type
      @name = name
      @max = max
      @running = 0
      # @mutex = Mutex.new
      self.class.store[name] = self
      puts "[ConcurrencyController] Started controller for '#{name}' with max_concurrency = #{@max}".yellow
    end
  
    def running
      # puts "[ConcurrencyController] [#{name}] Reading runners".red
      # wait
      # puts "[ConcurrencyController] [#{name}] Locking mutex".red
      # @mutex.lock
      @running
    # ensure
      # puts "[ConcurrencyController] [#{name}] Unlocking mutex".red
      # @mutex.unlock
    end

    def decr(amount = 1)
      incr(0 - amount)
    end
  
    def incr(amount = 1)
      # puts "[ConcurrencyController] [#{name}] Incr #{amount}".red
      # wait
      # puts "[ConcurrencyController] [#{name}] Locking mutex".red
      # @mutex.lock
      current = @running + amount
      return nil if max < current
      @running += amount
    # ensure
    #   puts "[ConcurrencyController] [#{name}] Unlocking mutex".red
    #   @mutex.unlock
    end
  
    # def wait
    #   puts "[ConcurrencyController] [#{name}] Waiting for mutex lock to release".red
    #   while @mutex.locked? do;end
    #   puts "[ConcurrencyController] [#{name}] Mutex released".red
    # end
  end
end
