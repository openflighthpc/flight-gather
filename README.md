# flight-gather
A tool to obtain relevant information about a node

## Overview
Detects and stores relevant system information including:
* System model, serial number and BIOS version
* Total RAM
* ID, model and core count for each CPU
* Mac address, speed and IP for each network interface
* Disk size(s)
* GPU name and slot
* Cloud platform

## Installation
Installation via `git`:
```
git clone https://github.com/openflighthpc/flight-gather.git
cd flight-gather
bundle install
```
## Configuration
The location of the output file may be set in the config file in `/etc/`

## Operation
Three commands are included:
```
collect [--primary GROUP][--groups GROUP1,GROUP2,...][--type TYPE]
show
modify [--primary GROUP][--groups GROUP1,GROUP2,...]
```
The `collect` command will collect relevant system information into the file specified in `/etc/config.yaml`. The optional primary and secondary groups are arbitrary text labels which may be set as required. The optional argument `--type TYPE` may be either "physical" or "logical", specifying a subset of the information to collect. By default both types are collected.

The `show` command will output the collected data to the console.

The `modify` command may be used after data collection to reset the primary and secondary groups to those specified by its optional arguments. Omitting either argument will clear the respective field entirely.

# Contributing

Fork the project. Make your feature addition or bug fix. Send a pull
request. Bonus points for topic branches.

Read [CONTRIBUTING.md](CONTRIBUTING.md) for more details.

# Copyright and License

Eclipse Public License 2.0, see [LICENSE.txt](LICENSE.txt) for details.

Copyright (C) 2020-present Alces Flight Ltd.

This program and the accompanying materials are made available under
the terms of the Eclipse Public License 2.0 which is available at
[https://www.eclipse.org/legal/epl-2.0](https://www.eclipse.org/legal/epl-2.0),
or alternative license terms made available by Alces Flight Ltd -
please direct inquiries about licensing to
[licensing@alces-flight.com](mailto:licensing@alces-flight.com).

flight-gather is distributed in the hope that it will be
useful, but WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER
EXPRESS OR IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR
CONDITIONS OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR
A PARTICULAR PURPOSE. See the [Eclipse Public License 2.0](https://opensource.org/licenses/EPL-2.0) for more
details.
