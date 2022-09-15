import json

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

# TODO: convert to `Action` objects for better handling of the return value
def handle_action(protocol, bench):
  while True:
    data = protocol.read()
    if data['action'] == 'test':
      res = bench.test_candidate(data['prog'])
      protocol.write({'action': 'test_res', 'res': res})
    elif data['action'] == 'done':
      data.pop('action', None)
      return data
    elif data['action'] == 'timeout':
      return None
    else:
      raise Exception("Unexpected RPC message")
