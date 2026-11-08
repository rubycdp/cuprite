# frozen_string_literal: true

describe Capybara::Cuprite::Node::Extensions do
  before do
    @session = TestSessions::Cuprite
    @driver = @session.driver
  end

  after { @session.reset! }

  describe "#drag_by" do
    it "drags the element by an offset" do
      @session.visit "/cuprite/drag"

      draggable = @session.find(:css, "#drag_by .draggable")

      top_before = @session.evaluate_script(%($("#drag_by .draggable").position().top))
      left_before = @session.evaluate_script(%($("#drag_by .draggable").position().left))

      draggable.native.drag_by(8000, 8000)

      top_after = @session.evaluate_script(%($("#drag_by .draggable").position().top))
      left_after = @session.evaluate_script(%($("#drag_by .draggable").position().left))

      expect(top_after).to eq(top_before + 8000)
      expect(left_after).to eq(left_before + 8000)
    end
  end
end
