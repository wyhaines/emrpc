require File.dirname(__FILE__) + '/spec_helper'

describe Protocol do

  before(:each) do
    @protocol_class = Class.new{include Protocol}
    @connection = @protocol_class.new
    
    #
    # Mock stubs
    #
    @local_uuid = local_uuid = "local-uuid"
    @remote_uuid = remote_uuid = "remote-uuid"
    
    @connection.stub!(:send_marshalled_message).and_return(nil)
    @local_pid = local_pid = mock("Pid", :uuid => @local_uuid, 
                                         :options => {:uuid => @local_uuid})
    local_pid.instance_eval do
      stub!(:_register_pid).and_return(nil)
      stub!(:connected).and_return(nil)
    end
    
    @remote_pid = remote_pid = mock("RemotePid", :uuid => @remote_uuid, 
                                                 :options => {:uuid => @remote_uuid})
  end
  
  describe "successful connection" do
    
    before(:each) do
      #
      # Mock expectations
      #
      rpid = duck_type(:uuid, :_connection, :options)
      @local_pid.should_receive(:_register_pid).once.with(rpid)
      @local_pid.should_receive(:connected).once.with(rpid)
      
      #
      # Init
      #
      @connection.address = em_addr.parsed_uri
      @connection.local_pid = @local_pid
      @connection.post_init
      @connection.connection_completed
      @connection.receive_marshalled_message([:hello, @remote_pid.options])
      @rpid = @connection.remote_pid
    end
    
    it "should have #remote_pid" do
      @rpid.should_not be_nil
    end
    
    it "should assign correct UUID to remote_pid" do
      @rpid.uuid.should == @remote_pid.uuid
    end
    
    it "should assign correct options to remote_pid" do
      @rpid.options.should == @remote_pid.options
    end
    
  end
  
  
  describe "connection refusal" do
    
    before(:each) do
      #
      # Mock expectations
      #
      @local_pid.should_receive(:connecting_failed).once.with(@connection)
      
      #
      # Init
      #
      @connection.address = em_addr.parsed_uri
      @connection.local_pid = @local_pid
      @connection.post_init
      @connection.unbind
      @rpid = @connection.remote_pid
    end
    
    it "should not have #remote_pid" do
      @rpid.should be_nil
    end
    
  end
  
end
