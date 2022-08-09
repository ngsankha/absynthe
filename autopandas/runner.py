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
        if isinstance(arg, pd.Series):
            return 'Series'
        if isinstance(arg, np.ndarray):
            return 'NdArray'
        elif isinstance(arg, str):
            return 'String'
        elif callable(arg):
            # NOTE: all functions a -> b are typed as Lambda
            return 'Lambda'
        else:
            raise Exception("Unexpected input argument")

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

    def all(b):
        tyin, tyout = Abstraction.types(b)
        # rownumin, rownumout = Abstraction.rownums(b)
        return {
            'argsty': tyin,
            'outputty': tyout,
            # 'rownumin': rownumin,
            # 'rownumout': rownumout
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
        except:
            # print("Eval error: {}".format(prog))
            return False
        if isinstance(ret, np.ndarray):
            return np.array_equal(ret, self.output)
        else:
            return ret.equals(self.output)
