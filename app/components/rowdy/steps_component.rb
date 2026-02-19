module Rowdy
  class StepsComponent < ViewComponent::Base
    STEPS = [
      { key: :column_mapping, step_number: 1 },
      { key: :validation, step_number: 2 },
      { key: :import, step_number: 3 }
    ].freeze

    def initialize(import:)
      @import = import
    end

    def steps
      STEPS
    end

    def step_label(key)
      I18n.t("rowdy.import.steps.#{key}")
    end

    def step_class(step_number)
      current = @import.current_step

      if step_number == current
        "rowdy-step--active"
      elsif step_number < current
        "rowdy-step--completed"
      else
        ""
      end
    end
  end
end
