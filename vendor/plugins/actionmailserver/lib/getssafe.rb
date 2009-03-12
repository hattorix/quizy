# $Id: getssafe.rb,v 1.2 2004/12/02 06:09:52 tommy Exp $
#
# Copyright (C) 2003-2004 TOMITA Masahiro
# tommy@tmtm.org
#

module GetsSafe
  def gets_safe(rs=nil, timeout=@timeout, maxlength=@maxlength)
    rs = $/ unless rs
    f = self.kind_of?(IO) ? self : STDIN
    @gets_safe_buf = "" unless @gets_safe_buf
    until @gets_safe_buf.include? rs do
      if maxlength and @gets_safe_buf.length > maxlength then
        raise Errno::E2BIG, "too long"
      end
      if IO.select([f], nil, nil, timeout) == nil then
        raise Errno::ETIMEDOUT, "timeout exceeded"
      end
      begin
        @gets_safe_buf << f.sysread(4096)
      rescue EOFError, Errno::ECONNRESET
        return @gets_safe_buf.empty? ? nil : @gets_safe_buf.slice!(0..-1)
      end
    end
    p = @gets_safe_buf.index rs
    if maxlength and p > maxlength then
      raise Errno::E2BIG, "too long"
    end
    return @gets_safe_buf.slice!(0, p+rs.length)
  end
  attr_accessor :timeout, :maxlength
end
