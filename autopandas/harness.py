import io
import subprocess
import json
from benchmarks import Benchmark

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

# for cls in Benchmark.__subclasses__():
#     obj = cls()
#     print(obj.output)
#     print('======')

proc = subprocess.Popen(['bundle', 'exec', 'bin/autopandas'], stdout=subprocess.PIPE, stdin=subprocess.PIPE, cwd=r'..')
p = Protocol(proc)
p.write('{"status": 0}')
data = p.read()
print(data)
