module Armagh
  module ActionErrors
    class ActionError                 < StandardError; end
    class ActionMethodNotImplemented  < StandardError; end
    class DoctypeError                < StandardError; end
    class ParameterError              < StandardError; end
    class StateError                  < StandardError; end
    class UnableToCreateError         < StandardError; end
  end
end