# join = '"outer" or "inner" or "left" or "right"'
# axis = '0 or 1'
# method = '"backfill" or "bfill" or "pad" or "ffill"'

# type DataFrame, :abs, "() -> DataFrame"
# type DataFrame, :add, "(DataFrame, axis: #{axis}, level: Integer, fill_value: Numeric) -> DataFrame"
# type DataFrame, :add_prefix, "(String) -> DataFrame"
# type DataFrame, :add_suffix, "(String) -> DataFrame"
# type DataFrame, :align, "(DataFrame, join: #{join}, axis: #{axis}, level: Integer, copy: %bool, fill_value: Numeric, method: #{method}, limit: Integer, fill_axis: #{axis}, broadcast_axis: #{axis}) -> DataFrame"
# type DataFrame, :all, "(axis: #{axis}, bool_only: %bool, skipna: %bool, level: Integer) -> DataFrame"
# type DataFrame, :any, "(axis: #{axis}, bool_only: %bool, skipna: %bool, level: Integer) -> DataFrame"
# # def apply(self, func: Function, axis: AxisOption = ..., raw: bool = ..., result_type: Optional[ApplyResultType] = ..., args: Any = ..., **kwds: Any) -> FrameOrSeries: ...
# # df.as_matrix
# type DataFrame, :astype, "(dtype: %any, copy: %bool, errors: String) -> DataFrame"
# # df.at_getitem
# type DataFrame, :axes, "() -> Array<Index>" # prop

type :DataFrame, :loc_getitem, "(Array<Integer>) -> DataFrame"
