# This file defines the IPC protocol used by the AutoPandas Python test harness
# process to communicate with the Absynthe core process in Ruby. This is a JSON
# line protocol with each action decribing steps happening with every message.

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
        # read messages returned by Absynthe core
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
    # The cases below describe all the messages handled by the Absynthe 
    if data['action'] == 'test':
      # Absynthe core asking to test a candidate in Python
      res = bench.test_candidate(data['prog'])
      protocol.write({'action': 'test_res', 'res': res})
    elif data['action'] == 'done':
      # Absynthe core finished synthesizing a function
      data.pop('action', None)
      return data
    elif data['action'] == 'timeout':
      # Absynthe core had a timeout during synthesis
      return None
    else:
      # Unexpected message
      raise Exception("Unexpected RPC message")
