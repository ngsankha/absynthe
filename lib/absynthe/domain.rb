class AbstractDomain
  attr_accessor :glb, :lub

  def <=(rhs)
    raise AbsyntheError, "Unexpected type error #{self.class} with #{rhs.class}" if rhs.class != self.class
    lhs = self
    leq_impl(lhs, rhs)
  end

  def leq_impl(lhs, rhs)
    root_vars = Globals.root_vars
    if lhs.top?
      if rhs.top?
        true
      elsif rhs.bot?
        false
      elsif rhs.val?
        false
      elsif rhs.var?
        if root_vars.include? rhs
          false
        else
          rhs.lub = lhs
          true
        end
      else
        raise AbsyntheError, "Unknown abstract value variant"
      end
    elsif lhs.bot?
      if rhs.top?
        true
      elsif rhs.bot?
        true
      elsif rhs.val?
        true
      elsif rhs.var?
        if root_vars.include? rhs
          true
        else
          rhs.lub = lhs
          true
        end
      else
        raise AbsyntheError, "Unknown abstract value variant"
      end
    elsif lhs.val?
      if rhs.top?
        true
      elsif rhs.bot?
        false
      elsif rhs.val?
        val_leq(lhs, rhs)
      elsif rhs.var?
        if root_vars.include? rhs
          false
        else
          rhs.glb = lhs
          true
        end
      else
        raise AbsyntheError, "Unknown abstract value variant"
      end
    elsif lhs.var?
      if rhs.top?
        lhs.glb = rhs
        true
      elsif rhs.bot?
        lhs.glb = rhs
        true
      elsif rhs.val?
        if root_vars.include? lhs
          false
        else
          lhs.glb = rhs
          true
        end
      elsif rhs.var?
        var_leq_update(lhs, rhs)
      else
        raise AbsyntheError, "Unknown abstract value variant"
      end
    else
      raise AbsyntheError, "Unknown abstract value variant"
    end
  end

  def var_leq_update(lhs, rhs)
    root_vars = Globals.root_vars
    if root_vars.include? lhs
      if root_vars.include? rhs
        var_leq(lhs, rhs)
      else
        rhs.glb = lhs
        true
      end
    else
      if root_vars.include? rhs
        lhs.lub = rhs
        true
      else
        rhs.lub <= lhs.glb && lhs.lub <= rhs.glb
      end
    end
  end

  def var_leq(lhs, rhs)
    raise AbsyntheError, "Unimplemented!"
  end

  def val_leq(lhs, rhs)
    raise AbsyntheError, "Unimplemented!"
  end
end
