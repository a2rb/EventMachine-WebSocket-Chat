require "eventmachine-websocket.rb"

class MyWebSocket < EventMachine::WebSocket::Connection
  def open
    pts "New client"    
    @@clients ||= []
    
    @@clients.each do |c|
      c.send "We have a new client"
    end
    
    @@clients << self
    send "Welcome friend"
  end

  def message(msg)
    puts "Message: #{msg}"
    @@clients.each do |c|
      if c == self
        c.send "You said #{msg}"
      else
        c.send "I heard #{msg}"
      end
    end
  end
  
  def close
    puts "WebSocket closed"
    @@clients.delete self
    MyWebSocket.send_to_all "We lost a friend"
  end
  
  def self.send_to_all(msg)
    @@clients ||= []
    @@clients.each do |c|
      c.send msg
    end
  end
end

EM.run do
  EventMachine.start_server("0.0.0.0", 8080, MyWebSocket)
  
  EventMachine::PeriodicTimer.new(5) do
    puts "the time is #{Time.now}"
    MyWebSocket.send_to_all(Time.now)
  end
  
  module KeyboardInput
    include EM::Protocols::LineText2
    def receive_line data
      puts "Console input: #{data}"
      MyWebSocket.send_to_all(data)
    end
  end
  EM.open_keyboard(KeyboardInput)
end
