# Base class for an abstract domain
# Any abstract domain will extend from this class and override given methods here

class AbstractDomain
  extend VarName
  attr_accessor :glb, :lub

  # The <= relation
  def <=(rhs)
    raise AbsyntheError, "Unexpected type error #{self.class} with #{rhs.class}" if rhs.class != self.class
    lhs = self
    leq_impl(lhs, rhs)
  end

  # returns a freshly instantiated variable
  def self.fresh_var
    self.var(fresh)
  end

  def solvable?
    respond_to? :solve
  end

  # common cases for the <= relation. The extender usually needs to implement
  # only val_leq and var_leq for values and variables respectively (given below)
  def leq_impl(lhs, rhs)
    if lhs.top?
      if rhs.top?
        true
      elsif rhs.bot?
        false
      elsif rhs.val?
        false
      elsif rhs.var?
        if Globals.root_vars_include? rhs
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
        if Globals.root_vars_include? rhs
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
        if Globals.root_vars_include? rhs
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
        if Globals.root_vars_include? lhs
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
      raise AbsyntheError, "Unknown abstract value variant #{lhs.variant}"
    end
  end

  # propages the greatest lower bound and least upper bound during <= comparison in variables
  def var_leq_update(lhs, rhs)
    root_vars = Globals.root_vars
    if Globals.root_vars_include? lhs
      if Globals.root_vars_include? rhs
        var_leq(lhs, rhs)
      else
        rhs.glb = lhs
        true
      end
    else
      if Globals.root_vars_include? rhs
        lhs.lub = rhs
        true
      else
        new_glb = rhs.glb
        new_lub = rhs.lub
        if rhs.glb <= lhs.glb and lhs.lub <= rhs.lub
          rhs.glb = lhs.glb
          rhs.lub = lhs.lub
          true
        elsif lhs.glb <= rhs.glb and rhs.lub <= lhs.lub
          lhs.glb = rhs.glb
          lhs.lub = rhs.lub
          true
        else
          false
        end
        # rhs.lub <= lhs.glb && lhs.lub <= rhs.glb
      end
    end
  end

  def var_leq(lhs, rhs)
    raise AbsyntheError, "Unimplemented!"
  end

  def val_leq(lhs, rhs)
    raise AbsyntheError, "Unimplemented!"
  end

  def self.replace_dep_hole!(name, args); end
end
