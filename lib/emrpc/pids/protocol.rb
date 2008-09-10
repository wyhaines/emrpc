module EMRPC
  module Pids
    module Protocol
      attr_accessor :address
      attr_accessor :local_pid
      attr_accessor :remote_pid
      
      def post_init
      end
      
      def connection_completed
        # setup single-shot version of receive_marshalled_message
        class <<self
          alias receive_marshalled_message receive_handshake_message
        end
        send_handshake_message(@local_pid.options)
      end
      
      def send_handshake_message(arg)
        send_marshalled_message([:handshake, arg])
      end
      
      def receive_handshake_message(msg)
        prefix, options = msg
        lpid = @local_pid
        prefix == :handshake or return lpid.handshake_failed(self, msg)
        rpid = RemotePid.new(self, options)
        # we don't put +_register_pid+ into +connected+ callback to avoid unneccessary +super+ calls in callbacks.
        @remote_pid = rpid = lpid._register_pid(rpid)
        lpid.connected(rpid)
        # restore receive_marshalled_message
        class <<self
          alias receive_marshalled_message receive_regular_message
        end
      end
      
      def receive_regular_message(msg)
        @local_pid._send_dirty(*msg)
      end
      
      def rescue_marshal_error(e)
        # FIXME: do something with this!
      end
      
      def unbind
        if @remote_pid
          # pid has been succesfully connected one day, but connection was lost.
          # we don't put +_unregister_pid+ into +connection_lost+ callback to avoid unneccessary +super+ calls in callbacks.
          rpid = @remote_pid
          @remote_pid = nil
          @local_pid._unregister_pid(rpid)
          @local_pid.disconnected(rpid)
        else
          # there were no connection, connecting failed. 
          @local_pid.connecting_failed(self)
        end
      end
      
    end # Protocol
  end # Pids
end # EMRPC
