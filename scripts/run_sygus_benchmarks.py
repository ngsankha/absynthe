from plumbum import local, FG, TF
from plumbum.cmd import bundle
import json
import numpy as np
from scipy.stats import iqr
import os
import argparse
import sys

parser = argparse.ArgumentParser(description='Run RbSyn benchmarks')
parser.add_argument('--times', '-t', dest='times', action='store',
                    default=11, help='number of times to run the benchmark')
parser.add_argument('--smallbench', dest='benchtype', action='store_const',
                    const='smallbench', default='bench',
                    help='use the small benchmark suite for data collection')

args = parser.parse_args()

if str(args.benchtype) == 'smallbench':
    print("Small bench not supported yet!")
    sys.exit(0)

ABSYNTHE_PATH = '..'
MY_CWD = os.getcwd()
JSON_LOG_FILE = 'test_log.json'

def benchmark(**opts):
    local.cwd.chdir(ABSYNTHE_PATH)
    bundle.with_env(**opts)['exec', 'rake', str(args.benchtype)] & TF(FG=True)

def collect(output_file, times, **opts):
    merged = None
    for i in range(times):
        benchmark(**opts)
        with open(ABSYNTHE_PATH + '/' + JSON_LOG_FILE) as f:
            data = json.load(f)
            if merged is None:
                merged = data
                for name, info in data.items():
                    merged[name]['time'] = [merged[name]['time']]
            else:
                for name, info in data.items():
                    merged[name]['time'].append(data[name]['time'])

    for name, info in merged.items():
        merged[name]['median_time'] = np.median(merged[name]['time'])
        merged[name]['time_siqr'] = iqr(merged[name]['time']) / 2

    local.cwd.chdir(MY_CWD)
    with open(output_file, 'w') as out:
        json.dump(merged, out)

collect('base_data.json', int(args.times))
