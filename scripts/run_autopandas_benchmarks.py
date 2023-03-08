import json
import numpy as np
from scipy.stats import iqr
import os
import argparse
import sys
import csv

sys.path.insert(1, os.path.abspath('../autopandas/'))
from harness import run_benchmarks, benches, smallbenches

parser = argparse.ArgumentParser(description='Run Absynthe AutoPandas benchmarks')
parser.add_argument('--times', '-t', dest='times', action='store',
                    default=11, help='number of times to run the benchmark')
parser.add_argument('--smallbench', dest='benchtype', action='store_const',
                    const='smallbench', default='bench',
                    help='use the small benchmark suite for data collection')

args = parser.parse_args()

# if str(args.benchtype) == 'smallbench':
#     print("Small bench not supported yet!")
#     sys.exit(0)

ABSYNTHE_PATH = '..'
MY_CWD = os.getcwd()
IGNORE_LIST = []

def collect(output_file, times, **opts):
    merged = None
    for i in range(times):
        if str(args.benchtype) == 'smallbench':
            data, skips = run_benchmarks(smallbenches, IGNORE_LIST)
        else:
            data, skips = run_benchmarks(benches, IGNORE_LIST)
        IGNORE_LIST.extend(skips)
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

    with open(output_file, 'w') as out:
        json.dump(merged, out)

def to_table(data, filename):
    with open(filename, 'w', newline='') as csvfile:
        tablewriter = csv.writer(csvfile)
        tablewriter.writerow(['Name', 'Time Median (s)', 'Time SIQR (s)', 'Size', 'Tested Progs'])
        for k, v in data.items():
            tablewriter.writerow([k, v['median_time'], v['time_siqr'], v['size'], v['tested_progs']])

collect('autopandas_data.json', int(args.times))
with open('autopandas_data.json', 'r') as f:
    data = json.load(f)
to_table(data, 'table2.csv')
