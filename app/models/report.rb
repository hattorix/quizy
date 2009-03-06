class Report < ActionMailer::Base
  

  def send(sent_at = Time.now)
    subject    '通報です'
    recipients 'arais@ark-system.co.jp'
    from       ''
    sent_on    sent_at
    
    body       :greeting => 'Hi,'
  end

end
