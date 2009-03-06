require 'test_helper'

class ReportTest < ActionMailer::TestCase
  tests Report
  def test_send
    @expected.subject = 'Report#send'
    @expected.body    = read_fixture('send')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Report.create_send(@expected.date).encoded
  end

end
