module Armagh
  class ActionDocument
    attr_accessor :content, :meta, :state

    def initialize(content, meta, state)
      @content = content
      @meta = meta
      @state = state
    end
  end
end
