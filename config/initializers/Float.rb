class Float
  def round_down n=0
    n < 1 ? self.to_i.to_f : (self - 0.5 / 10**n).round(n)
  end
end