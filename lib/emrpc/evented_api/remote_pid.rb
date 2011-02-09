module EMRPC  
  # RemotePid is the interface through which one interacts with a remote Pid.
  # It allows one to call methods on the remote Pid or kill the remote Pid,
  # and it implements a useful #inspect method which will return information
  # about the remote Pid.
  class RemotePid
    include Pid
    attr_accessor :_connection

    def initialize(conn, options)
      _common_init
      @_connection = conn
      @uuid        = options[:uuid]
      @options     = options
    end

    # As a shortcut for using #send, one can invoke arbitrary methods on
    # an instance of RemotePid, which will proxy those method calls over
    # to #send.
    def method_missing(*args)
      send(*args)
    end

    # This is used to send a message (a method call)to a remote Pid. It is
    # invoked by passing a symbol identifying the method to invoke, followed
    # by the arguments to pass to the method.
    def send(*args)
      cmd = args.first
      if cmd == :kill
        return if @killed # It's not undead; you can't kill it twice.
        @killed = true
        @_connection.close_connection_after_writing
      end
      @_connection.send_raw_message(args)
    end

    # Tell the remote Pid that it should die.
    def kill
      send(:kill)
    end
    
    def inspect
      return "#<RemotePid:#{_uid} KILLED>" if @killed
      "#<RemotePid:#{_uid} on #{@_connection.address} connected with local pid #{@_connection.local_pid._uid}>"
    end
          
  end # RemotePid
end # EMRPC
