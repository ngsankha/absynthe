import pandas as pd
import numpy as np
import itertools

def flatten(xs):
    try:
        return list(itertools.chain(*xs))
    except:
        return xs

# Defines and infers the domains required by AutoPandas in Python
# Note that all the methods required by each domain is still defined in Ruby.
# The code here just reads a Python value, infers necessary abstractions,
# serializes it and then hands it as a JSON to the Absynthe core.
# This allows us to leverage native Python methods and libraries to infer
# abstractions from Python values.

class Abstraction:
    # Infers the type from a Python value
    def _infer_type(arg):
        if isinstance(arg, pd.DataFrame):
            return 'DataFrame'
        elif isinstance(arg, pd.Series):
            return 'Series'
        elif isinstance(arg, np.ndarray):
            return 'NdArray'
        elif isinstance(arg, str):
            return 'String'
        elif isinstance(arg, int):
            return 'Integer'
        elif isinstance(arg, list):
            return 'Array<{}>'.format(Abstraction._infer_type(arg[0]))
        elif callable(arg):
            # NOTE: all functions a -> b are typed as Lambda
            return 'Lambda'
        else:
            raise Exception("Unexpected input argument {}".format(arg))

    # Infers row labels as a set
    def _infer_rownum(df):
        # return list(df.index)
        return list(set(flatten(list(df.index))))

    # Gets the types for input and output examples
    def types(b):
        inp = list(map(Abstraction._infer_type, b.inputs))
        out = Abstraction._infer_type(b.output)
        return [inp, out]

    # Infers row labels as a set for input and output examples
    def rownums(b):
        inp = list(map(Abstraction._infer_rownum, b.inputs))
        out = Abstraction._infer_rownum(b.output)
        return [inp, out]

    # Infer constants from Pandas indexes
    def index2const(index):
        consts = []
        if type(index) in [pd.Index, pd.Int64Index, pd.DatetimeIndex] :
            consts.extend(list(index))
        elif type(index) == pd.RangeIndex:
            consts.extend(range(index.start, index.stop, index.step))
        elif type(index) == pd.MultiIndex:
            consts.extend(flatten(list(index)))
        else:
            print(index)
            raise RuntimeError("Unhandled index: " + str(type(index)))

        if index.name is not None:
            consts.append(index.name)
        if index.names is not None:
            consts.extend(list(index.names))

        return filter(lambda v: v is not None, consts)

    # Set of constants in rows and columns
    def consts(b):
        filtered_vals = list(filter(lambda v: isinstance(v, pd.DataFrame), b.inputs + [b.output]))
        val_indexes = map(Abstraction.index2const, map(lambda v: v.index, filtered_vals))
        val_columns = map(Abstraction.index2const, map(lambda v: v.columns, filtered_vals))

        consts = flatten(list(val_indexes) + list(val_columns))
        consts.append(0)

        # NOTE: only support int and strings in JSON serialization
        supported_consts = filter(lambda v: type(v) in [int, str], consts)
        return set(supported_consts)

    # Set of column labels as inputs
    def cols_inp(b):
        idx = 0
        colmap = {}
        for i in b.inputs:
            if type(i) == pd.DataFrame:
                colmap["arg{}".format(idx)] = i.columns
            else:
                colmap["arg{}".format(idx)] = 'bot'
            idx += 1

        if type(b.output) == pd.DataFrame:
            outcol = "outcol"
            for i in range(idx):
                if type(colmap["arg{}".format(i)]) is not str and colmap["arg{}".format(i)].equals(b.output.columns):
                    outcol = "df{}".format(i)
        else:
            outcol = 'bot'

        for i in range(idx):
            if type(colmap["arg{}".format(i)]) == str:
                continue

            replaced = False
            for j in range(i):
                if type(colmap["arg{}".format(j)]) == type(colmap["arg{}".format(i)]) == pd.DataFrame:
                    if colmap["arg{}".format(i)].equals(colmap["arg{}".format(j)]):
                        colmap["arg{}".format(i)] = colmap["arg{}".format(j)]
                        replaced = True
            if not replaced:
                colmap["arg{}".format(i)] = "df{}".format(i)

        args = []
        for i in range(idx):
            args.append(colmap["arg{}".format(i)])

        return (args, outcol)

    # Combine all these individual abstractions into the composite object
    def all(b):
        tyin, tyout = Abstraction.types(b)
        # rownumin, rownumout = Abstraction.rownums(b)
        colin, colout = Abstraction.cols_inp(b)
        return {
            'argsty': tyin,
            'outputty': tyout,
            # 'rownumin': rownumin,
            # 'rownumout': rownumout,
            'colin': colin,
            'colout': colout,
            'consts': list(Abstraction.consts(b)),
            'seqs': len(b.seqs[0])
        }

# Base class for each benchmark. We define a `test_candidate` method that
# allows one to run a candidate against a benchmark's input/output example
class Benchmark:
    def __init__(self):
        pass

    def absynthe_input(self):
        return Abstraction.all(self)

    def test_candidate(self, prog):
        env = {}
        for i in range(len(self.inputs)):
            env['arg' + str(i)] = self.inputs[i]
        try:
            ret = eval(prog, globals(), env)
            if isinstance(ret, np.ndarray):
                return np.array_equal(ret, self.output)
            elif isinstance(ret, list):
                return ret == self.output
            else:
                return ret.equals(self.output)
        except:
            # print("Eval error: {}".format(prog))
            return False
