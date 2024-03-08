# flight-gather
A tool to obtain relevant information about a node

## Overview
Detects and stores relevant system information. An explanation of each field is given below.

```
:primaryGroup:              User-specified primary group                         
:secondaryGroups: []        User-specified secondary groups
:model:                     System model
:bios:                      System BIOS version
:serial:                    System serial number
:ram:                       RAM-related information
  :total_capacity:          Total RAM capacity in GB
  :units:                   Number of RAM devices
  :capacity_per_unit:       RAM capacity per RAM device, in GB
  :ram_data:                Data for each individual RAM device
    RAM0:
      :form_factor:         Device form factor
      :size:                Device capacity in GB
      :locator:             Device locator
    ...
:cpus:                      CPU-related information
  :units:                   Number of CPUs
  :cores_per_cpu:           Number of cores per CPU
  :cpu_data:                Data for each individual CPU
    CPU0:
      :socket:              Socket in which the CPU is installed
      :model:               CPU model
      :cores:               Number of cores
      :hyperthreading:      Whether the CPU has hyperthreading
    ...
:network:                   Network-related information
  eth0:
    :mac:                   MAC address
    :speed:                 Network speed
    :ip:                    IP address
:sysuuid: 
:bootif: 
:disks:                     Disk-related information
  vda:
    :type:                  Disk type (HDD or SSD)
    :size:                  Disk capacity in GB
  ...
:gpus:                      GPU-related information
  GPU0:
    :name:                  GPU name
    :slot:                  GPU slot
:platform:                  Cloud platform of the node (or Metal)
```

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
show [FIELD][--force]
modify [--primary GROUP][--groups GROUP1,GROUP2,...]
```
The `collect` command will collect relevant system information into the file specified in `/etc/config.yaml`. The optional primary and secondary groups are arbitrary text labels which may be set as required. The optional argument `--type TYPE` may be either "physical" or "logical", specifying a subset of the information to collect. By default both types are collected.

The `show` command will output the collected data to the console. The `--force` option will run `collect` automatically if the data hasn't already been gathered. The optional `FIELD` argument will filter the data using JQ-style syntax. Some example usage:

* `gather show .model` - returns only the system model
* `gather show .ram` - returns only the information under the `:ram:` section.
* `gather show .cpus.cpu_data.[CPU0]` - returns the CPU information for the CPU called "CPU0".

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
