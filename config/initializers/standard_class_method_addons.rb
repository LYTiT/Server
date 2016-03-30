class Float
  def round_down n=0
    n < 1 ? self.to_i.to_f : (self - 0.5 / 10**n).round(n)
  end
end

class Array
  def page(pg, offset = 10)
    self[((pg-1)*offset)..((pg*offset)-1)]
  end
end