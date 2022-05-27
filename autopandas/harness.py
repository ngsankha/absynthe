import io
import subprocess
import json
from benchmarks import Benchmark, SO_11881165_depth1

class Action:
  pass

class Protocol:
  def __init__(self, proc):
    self.proc = proc
  
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

# for cls in Benchmark.__subclasses__():
#     obj = cls()
#     print(obj.output)
#     print('======')

proc = subprocess.Popen(['bundle', 'exec', 'bin/autopandas'], stdout=subprocess.PIPE, stdin=subprocess.PIPE, cwd=r'..')
p = Protocol(proc)
# p.write('{"status": "hello"}')
# data = p.read()
# print(data)

bench = SO_11881165_depth1()
# print(bench.absynthe_input())
data = bench.absynthe_input()
data['action'] = 'start'
# print(data)
p.write(data)
print(handle_action(p, bench))

# print(bench.test_candidate('arg0.loc[[0, 2, 4]]'))
# print(bench.test_candidate('arg0.loc[[0, 2]]'))
