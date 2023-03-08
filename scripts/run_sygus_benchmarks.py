from plumbum import local, FG, TF
from plumbum.cmd import bundle
import json
import numpy as np
from scipy.stats import iqr
import os
import argparse
import sys
import csv

parser = argparse.ArgumentParser(description='Run Absynthe SyGuS benchmarks')
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
JSON_LOG_FILE = 'test_log.json'

def benchmark(**opts):
    local.cwd.chdir(ABSYNTHE_PATH)
    bundle.with_env(**opts)['exec', 'rake', str(args.benchtype)] & TF(FG=True)
    local.cwd.chdir(MY_CWD)

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

    with open(output_file, 'w') as out:
        json.dump(merged, out)

def combine_results(base, no_template, no_cache):
    for k, v in no_template.items():
        if k not in base:
            base[k] = {}
        base[k]['no_template'] = v['time'][0]
    for k, v in no_cache.items():
        if k not in base:
            base[k] = {}
        base[k]['no_cache'] = v['time'][0]
    return base

def to_table(data, filename):
    with open(filename, 'w', newline='') as csvfile:
        tablewriter = csv.writer(csvfile)
        tablewriter.writerow(['Name', 'Time Median (s)', 'Time SIQR (s)', 'Size', '# Ex', 'Tested Progs', 'No cache', 'No template'])
        for k, v in data.items():
            tablewriter.writerow([k, v['median_time'], v['time_siqr'], v['size'], v['specs'], v['tested_progs'], v['no_cache'], v['no_template']])

collect('sygus_data.json', int(args.times))
collect('sygus_template_infer.json', 1, TEMPLATE_INFER='1')
collect('sygus_no_cache.json', 1, NO_CACHE='1')

with open('sygus_data.json', 'r') as f:
    base = json.load(f)
with open('sygus_template_infer.json', 'r') as f:
    no_template = json.load(f)
with open('sygus_no_cache.json', 'r') as f:
    no_cache = json.load(f)

data = combine_results(base, no_template, no_cache)
to_table(data, 'table1.csv')
