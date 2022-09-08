import pandas as pd
import numpy as np
import itertools

def flatten(xs):
    try:
        return list(itertools.chain(*xs))
    except:
        return xs

class Abstraction:
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

    def _infer_rownum(df):
        # return list(df.index)
        return list(set(flatten(list(df.index))))

    def types(b):
        inp = list(map(Abstraction._infer_type, b.inputs))
        out = Abstraction._infer_type(b.output)
        return [inp, out]

    def rownums(b):
        inp = list(map(Abstraction._infer_rownum, b.inputs))
        out = Abstraction._infer_rownum(b.output)
        return [inp, out]

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

    def consts(b):
        filtered_vals = list(filter(lambda v: isinstance(v, pd.DataFrame), b.inputs + [b.output]))
        val_indexes = map(Abstraction.index2const, map(lambda v: v.index, filtered_vals))
        val_columns = map(Abstraction.index2const, map(lambda v: v.columns, filtered_vals))

        consts = flatten(list(val_indexes) + list(val_columns))

        # NOTE: only support int and strings in JSON serialization
        supported_consts = filter(lambda v: type(v) in [int, str], consts)
        return set(supported_consts)

    def cols_inp(b):
        idx = 0
        ret = {}
        df_inps = map(lambda x: x.columns, filter(lambda x: type(x) == DataFrame, b.inputs))
        for i in df_inps:
            


    def all(b):
        tyin, tyout = Abstraction.types(b)
        # rownumin, rownumout = Abstraction.rownums(b)
        return {
            'argsty': tyin,
            'outputty': tyout,
            # 'rownumin': rownumin,
            # 'rownumout': rownumout,
            'cols_same': Abstraction.cols_same(b),
            'consts': list(Abstraction.consts(b)),
            'seqs': len(b.seqs[0])
        }

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
