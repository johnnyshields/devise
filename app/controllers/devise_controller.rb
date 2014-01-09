# All Devise controllers are inherited from here.
class DeviseController < Devise.parent_controller.constantize
  include Devise::Mixins::Base
end
