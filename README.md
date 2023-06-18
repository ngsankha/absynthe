# Absynthe

## Installation

Absynthe can also be installed on a local system outside the artifact environment.

* Install `rbenv` using the `rbenv-installer` scripts [here](https://github.com/rbenv/rbenv-installer).
* Once `rbenv` is setup, install Ruby 3.1.2: `rbenv install 3.1.2`
* Make Ruby 3.1.2 the global Ruby: `rbenv global 3.1.2`
* Install bundler: `gem install bundler -v 2.3.22`
* Enter the provided `absynthe` directory and install all dependencies: `bundle install`
* Install Python dependencies for AutoPandas benchmarks: `pip3 install numpy scipy matplotlib plumbum pandas pygments`

This will produce a working setup for Absynthe on a local system. All commands to reproduce Absynthe results should work.

## Getting started

You can try to play with the implementation of Absynthe, the purpose of some of the key modules are given in the file structure section above.

You can add/modify a benchmark for SyGuS by adding a new `sl` file to `sygus-strings` folder. You can use existing benchmarks as an example to help you write your own benchmark. You may have to add/update the benchmark abstract specification in `test/sygus_bench.rb` file. To run the benchmark suite you can use the command: `bundle exec rake bench`. We explain how to write abstract specifications in the following section.

Similarly for the AutoPandas benchmark suite you can add/modify a new benchmark in the `autopandas/benchmarks.py` file. If you added a new benchmark, you'll need to add the file to the `benches` list in `autopandas/harness.py`. To run the Autopandas benchmark suite using Absynthe, use the command: `python3 harness.py` in the `autopandas` directory.

To use Absynthe on a different benchmark suite, you'll need to define your own abstract domain and semantics using the Absynthe framework and build a synthesizer from it's API. Sample definitions of abstract domains and semantics are given in the `lib/python` or `lib/sygus` folders. The file `bin/autopandas` defines a self-contained synthesizer using the Absynthe API functions. Lines 10-61 contain the type signatures of the Pandas API methods, and the lines after contain the definition of the synthesizer. This file can be adapted to target to a new domain. We are planning to explore a better API design for enabling easier development of synthesis tools with the core Absynthe framework in the future.

### Abstract Specfications

Abstract specifications are provided as two values:

1. The environment hash that maps the variable names to the abstract values
2. The abstract value of the expected output of the function

So if a function takes two arguments, `firstname` and `lastname` the first part of the specification looks like: `{:firstname => AbstractValue, :lastname => AbstractValue}`. These `AbstractValue`s can be constructed as a top, bot, constant or a variable of a particular domain. As an example consider:

```
{:name => StringLenExt.top}, StringLenExt.top) \\ ⊤ -> ⊤
{:name => StringLenExt.top}, StringLenExt.val(3)) \\ ⊤ -> 3
{:name => StringLenExt.val(11)}, StringLenExt.val(3)) \\ 11 -> 3
{:name => StringLenExt.var('foo')}, StringLenExt.val(3)) \\ foo -> 3
{:name => StringLenExt.var('foo')}, StringLenExt.var('foo') - StringLenExt.val(3)) \\ foo -> foo - 3
```

The abstract variable name in StringLenExt.var is useful only in the last case. When you want to define output values in terms of the input values. The StringLenExt can be replaced with other domains of choice as needed.

## Paper

The ideas behind Absynthe are explained in detail in our PLDI 2023 paper: [Absynthe: Abstract Interpretation-Guided Synthesis](https://sankhs.com/static/absynthe-pldi23.pdf).

## Reproduce paper evaluation

To reproduce the benchmarks in the paper, we recommend you try the [Absynthe artifact](https://zenodo.org/record/7824175). The artifact comes with a README that will guide you with the setup. You can run the benchmarks on your local Absynthe setup using the following commands:

### Table 1

Producing Table 1 requires the benchmarks to be run 11 times. We provide a Python script that will run the benchmark multiple times and gather the data as a CSV file `table1.csv`. To run it:

```
cd scripts/
python3 run_sygus_benchmarks.py # Runs SyGuS strings benchmarks
```

Do note, that running these benchmarks 11 times will take long time and it is expected that certain benchmarks will timeout (same in the paper). If running the benchmark 11 times is too time consuming, you can pass an additional flag to the above script `-t N` where N is the number of times the benchmarks should be run. The script with executed with `-h` will present these options.

**Note:** The number of times the benchmark suite will be run is `N + 2`, where `N` is the number passed with `-t` flag. The extra 2 is because the benchmarks are run once to gather numbers without template inference and without caching small expressions.

It is common to see benchmarks that passed before, fail as they are run in other configurations. The `run_sygus_benchmarks` script executes programs using all features of Absynthe (N times), template inference disabled (1 time), and caching of small expressions disabled (1 time). It is expected that some benchmarks will timeout through these configurations.

`table1.csv` will mirror the numbers from Table 1. There might be differences in time for benchmarks because these were run on different machines. We have fixed some bugs in the tool during the paper review period, so there may be some differences in the number of programs tested (`Tested Progs` column). This CSV file can be found on your local machine in the path `scripts/` where you extracted the artifact zip file. This supports the claims made in the Table 1 of the paper.

### Table 2

Producing Table 2 requires the benchmarks to be run 11 times. We provide a Python script that will run the benchmark multiple times and gather the data as a CSV file `table2.csv`. To run it:

```
cd scripts/
python3 run_autopandas_benchmarks.py # Runs AutoPandas benchmarks
```

Do note, that running these benchmarks 11 times will take long time and it is expected that certain benchmarks will timeout (same in the paper). If running the benchmark 11 times is too time consuming, you can pass an additional flag to the above script `-t N` where N is the number of times the benchmarks should be run. The script with executed with `-h` will present these options.

`table2.csv` will mirror the numbers from Table 2. There might be differences in time for benchmarks because these were run on different machines. We have fixed some bugs in the tool during the paper review period, so there may be some differences in the number of programs tested (`Tested Progs` column). This CSV file can be found on your local machine in the path `absynthe/scripts/` where you extracted the artifact zip file. This supports the claims made in the Table 2 of the paper.

**Note:** The `Depth` column of produced `table2.csv` file is a part of the input of the benchmark suite. This can be verified by going to the file `autopandas/benchmarks.py`, where each length of the first array in `self.seqs` is the depth of the benchmark. The `AP Neural` and `AP Baseline` columns are sourced from the [AutoPandas paper](https://people.eecs.berkeley.edu/~ksen/papers/autopandas2.pdf).

## Code documentation

_We are working on better formatted documentation of the Absynthe internals._

* `autopandas/`: The AutoPandas benchmarks
  * `benchmarks.py`: The benchmarks from AutoPandas paper ([source](https://github.com/rbavishi/autopandas/blob/master/autopandas_v2/evaluation/benchmarks/stackoverflow.py))
  * `harness.py`: The benchmarks runner harness
  * `protocol.py`: The inter-process communication protocol between the benchmark harness (Python) and Absynthe (Ruby)
  * `runner.py`: Infers abstractions from the input/output examples of the Autopandas benchmark
* `bin/autopandas`: Sample implementation of the Absynthe framework for the AutoPandas framework
* `lib/absynthe/`: Main directory containing Absynthe implementation:
  * `passes/`: All visitor passes including that walks over AST holes and fills candidates (`expand_hole.rb` and `py_expand_hole.rb`), calculates program size (`prog_size.rb` and `py_prog_size.rb`), etc.
  * `python/`: Python specific abstract domain and semantics definition
    * `abstract-interpreters/`: `pytype_interpreter.rb` and `pandacol_interpreter.rb` are defintions of abstract interpreters for the Python type checker and Pandas columns abstract interpreter respectively.
    * `domains/`: `pytype.rb` and `pandas_cols.rb` are defintion of the Python Types and Pandas Columns abstract domains. `product.rb` is a Product domain for Python abstractions.
  * `sygus/`: Sygus specific abstract domain and semantics definition
    * `abstract-interpreters`: `length_ext_interpter.rb`, `prefix_interpter.rb`, and `suffix_interpter.rb` are defintions of abstract interpreters for the solver-aided string length, string prefix, and string suffix abstract interpreter respectively.
    * `domains`: `string_length_extended.rb`, `string_prefix.rb`, and `string_suffix.rb` are defintion of the solver-aided string length, string prefix, string suffix abstract domains. `product.rb` is a Product domain for all these individual abstract domains.
  * `cache.rb`: Cache for small expressions that enables reuse of terms during synthesis.
  * `domain.rb`: Base class and common methods (including the $\subseteq$ relation) for the abstract domains.
  * `instrument.rb`: Instrumentation used to capture benchmark statistics, finally presented in the tables.
  * `python.rb`: Python specific libraries import
  * `sygus.rb`: Sygus specific libraries import
  * `synthesizer.rb`: The core worklist algorithm to explore candidates during the synthesis process and prune the search space based on abstract intrepretation. This also calls the methods to run the inference on the abstract holes.
  * `template_infer.rb`: Infers the template for a candidate based on testing certain examples.
* `scripts/*.py`: Automation to run the benchmark suites multiple times and prepare the final tables in the paper.
* `sygus-strings/`: The SyGuS strings benchmark suite.
* `test/`: A few unit tests for Absynthe and the SyGuS synthesizer built from Absynthe framework (`test_helper.rb`).

## Contact

We would like to receive suggestions/comments about further improving Absynthe. Please file an issue on GitHub.

