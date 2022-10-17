# flight-gather
A tool to obtain relevant information about a node

# Installation
Installation via `git`:
```
git clone https://github.com/openflighthpc/flight-gather.git
cd flight-gather
bundle install
```
# Configuration
The location of the output file may be set in the config file in `/etc/`

# Operation
Three commands are included:
```
collect [--primary GROUP][--groups GROUP1,GROUP2,...][--type TYPE]
show
modify [--primary GROUP][--groups GROUP1,GROUP2,...]
```
The `collect` command will collect relevant system information into the file specified in `/etc/config.yaml`. The optional primary and secondary groups are arbitrary text labels which may be set as required. The optional argument `--type TYPE` may be either "physical" or "logical", specifying a subset of the information to collect. By default both types are collected.

The `show` command will output the collected data to the console.

The `modify` command may be used after data collection to reset the primary and secondary groups to those specified by its optional arguments. Omitting either argument will clear the respective field entirely.
