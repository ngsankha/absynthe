module VarName
  @@counter = 0

  def fresh
    @@counter += 1
    "tmp_#{@@counter}"
  end
end
