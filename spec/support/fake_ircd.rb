class FakeIRCd < EventMachine::Connection
  def initialize
    super

    @buffer = []
  end

  def receive_data(data)
    @buffer << data.chomp
  end
end
