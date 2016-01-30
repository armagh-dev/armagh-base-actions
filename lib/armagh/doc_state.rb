module Armagh
  module DocState
    PENDING   = 'pending'
    PUBLISHED = 'published'
    CLOSED    = 'closed'

    def self.valid_state?(state)
      DocState::constants.collect{|c| DocState.const_get(c)}.include?(state)
    end
  end
end