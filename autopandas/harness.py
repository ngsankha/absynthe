import io
import subprocess
import json
import benchmarks

class Action:
  pass

class Protocol:
  def __init__(self, proc, log=True):
    self.proc = proc
    self.log = log
  
  def read(self):
    while True:
      line = self.proc.stdout.readline()
      if not line:
        # TODO: process ended
        return
      try:
        data = json.loads(line)
        # TODO: additional parsing
        return data
      except ValueError:
        if self.log:
          print("ABSYNTHE LOG: {}".format(line.decode("UTF-8").strip()))
  
  def write(self, data):
    txt = json.dumps(data)
    self.proc.stdin.write((txt + "\n").encode("UTF-8"))
    self.proc.stdin.flush()


def handle_action(protocol, bench):
  while True:
    data = protocol.read()
    if data['action'] == 'test':
      res = bench.test_candidate(data['prog'])
      protocol.write({'action': 'test_res', 'res': res})
    elif data['action'] == 'done':
      return data['prog']
    else:
      raise Exception("Unexpected RPC message")

benches = [
  # benchmarks.SO_11881165_depth1(),
  benchmarks.SO_11941492_depth1()
]

for bench in benches:
  print("Benchmark: {}".format(type(bench).__name__))
  proc = subprocess.Popen(['bundle', 'exec', 'bin/autopandas'],
                          stdout=subprocess.PIPE,
                          stdin=subprocess.PIPE,
                          stderr=subprocess.PIPE,
                          cwd=r'..')
  p = Protocol(proc, log=True)
  data = bench.absynthe_input()
  data['action'] = 'start'
  p.write(data)
  print(handle_action(p, bench))
  print("========================")
