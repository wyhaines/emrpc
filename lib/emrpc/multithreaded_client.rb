require 'thread'
module EMRPC
  class PoolTimeout < StandardError; end
  class MultithreadedClient
    attr_reader :pool, :backends, :timeout
    def initialize(options)
      @backends = options[:backends] or raise "No backends supplied!"
      @pool     = options[:queue] || ::Queue.new
      @timeout  = options[:timeout] || 5
      @timeout_thread = Thread.new { timer_action! }
      @backends.each do |backend|
        @pool.push(backend)
      end
    end
    
    def send_message(meth, args, blk)
      start = Time.now
      # wait for the available connections here
      while :timeout == (backend = @pool.pop)
        seconds = Time.now - start
        if seconds > @timeout
          raise PoolTimeout, "Thread #{Thread.current} waited #{seconds} seconds for backend connection in a pool. Pool size is #{@backends.size}. Maybe too many threads are running concurrently. Increase the pool size or decrease the number of threads."
        end
      end
      begin
        backend.send_message(meth, args, blk)
      ensure # Always push backend to a pool after using it!
        @pool.push(backend)
      end
    end
    
    # Pushes :timeout message to a queue for all 
    # the threads in a backlog every @timeout seconds.
    def timer_action!
      sleep @timeout
      @pool.num_waiting.times { @pool.push(:timeout) }
    end
    
  end
end
