import io
import subprocess
import benchmarks
import unittest
import warnings
import time
import random
import sys
import os
from pygments import highlight
from pygments.lexers import PythonLexer
from pygments.formatters import TerminalFormatter
from protocol import Protocol, handle_action

benches = [
  benchmarks.SO_11881165_depth1(),
  benchmarks.SO_11941492_depth1(),
  benchmarks.SO_13647222_depth1(),
  benchmarks.SO_18172851_depth1(),
  benchmarks.SO_49583055_depth1(),
  benchmarks.SO_49583055_depth1(),
  benchmarks.SO_49592930_depth1(),
  benchmarks.SO_49572546_depth1(),
  benchmarks.SO_12860421_depth1(), # slow; not in AutoPandas paper
  benchmarks.SO_13261175_depth1(),
  benchmarks.SO_13793321_depth1(),
  benchmarks.SO_14085517_depth1(),
  benchmarks.SO_11418192_depth2(),
  benchmarks.SO_49567723_depth2(),
  benchmarks.SO_49987108_depth2(), # not in AutoPandas paper
  benchmarks.SO_13261691_depth2(),
  benchmarks.SO_13659881_depth2(),
  benchmarks.SO_13807758_depth2(),
  benchmarks.SO_34365578_depth2(), # slow
  benchmarks.SO_10982266_depth3(), # fail
  benchmarks.SO_11811392_depth3(),
  benchmarks.SO_49581206_depth3(), # slow
  benchmarks.SO_12065885_depth3(), # slow
  benchmarks.SO_13576164_depth3(),
  benchmarks.SO_14023037_depth3(),
  benchmarks.SO_53762029_depth3(),
  benchmarks.SO_21982987_depth3(), # not tried
  benchmarks.SO_39656670_depth3(),
  benchmarks.SO_23321300_depth3()
]
random.shuffle(benches)

smallbenches = [
  benchmarks.SO_11881165_depth1(),
  benchmarks.SO_11418192_depth2(),
  benchmarks.SO_13659881_depth2()
]
random.shuffle(smallbenches)

def pprint_color(obj):
    print(highlight(obj, PythonLexer(), TerminalFormatter()))

def run_benchmarks(benches, ignore_list):
  skips = []
  results = {}
  for bench in benches:
    print(type(bench).__name__)

    if bench in ignore_list:
      print('SKIPPED!')
      continue

    try:
      with warnings.catch_warnings():
        warnings.simplefilter("ignore")
        data = bench.absynthe_input()
        data['action'] = 'start'
        env = os.environ
        env['RUBYOPT'] = '-W0'


        proc = subprocess.Popen(['bundle', 'exec', 'bin/autopandas'],
                                stdout=subprocess.PIPE,
                                stdin=subprocess.PIPE,
                                # stderr=subprocess.PIPE,
                                cwd=r'..',
                                env=env)
        p = Protocol(proc, log=True)
        p.write(data)
        final_out = handle_action(p, bench)
        if final_out is None: # timeout
          skips.append(bench)
          final_out = {}
          final_out['depth'] = len(bench.seqs[0])
          final_out['time'] = '-'
          results[type(bench).__name__] = final_out
        else:
          prog = final_out['prog']
          pprint_color(prog)
          print(final_out['time'])
          results[type(bench).__name__] = final_out
        proc.wait()
        proc.stdin.close()
        proc.stdout.close()
        # proc.stderr.close()
    except:
      print("ERROR!")
      print(sys.exc_info())

  return (results, skips)

if __name__ == '__main__':
  run_benchmarks(benches, [])
