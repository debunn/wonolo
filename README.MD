# Ansible-like

## Introduction
The Ansible-like program

## Prerequisites
- Tested on version 3.0.1 of the Ruby language, may work with earlier releases (see here for installation documentation:  https://www.ruby-lang.org/en/documentation/installation/)

## Installation
- Download all included files, and place them in a directory of your choice
- From a terminal, navigate to the directory you placed the included files, and then run:
```bundle install```

## Usage
```ruby ansible-like.rb <playbook_file> <inventory_file>```

- Both the playbook and the inventory files are required.  Please see the included examples for formatting (multiple hosts may be included in the inventory - one host per line)
- Please be sure to set up your `$HOME/.ssh/config` file so that any hosts in the inventory file have been set up with the correct hostname/IP/port, SSH keys, username and password
