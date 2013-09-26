class RubyServ::IRC::Channel
  @channels = []

  def initialize(options = {})
  end

  def destroy
  end

  class << self
    def create(options = {})
    end

    def all
      @channels
    end

    def find(id, method = :cid)
    end
  end
end
