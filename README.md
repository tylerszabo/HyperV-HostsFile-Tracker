# Hyper-V HostsFile Tracker

## Overview

This script will update `%WINDIR%\System32\drivers\etc\hosts` with entries for Hyper-V guests (or another file with the `-HostsFilePath` argument).

Host names can be customized by editing the hosts file. For instance, the entries can be altered so long as the id in the JSON string in the comment is preserved. The hostname bound to the full Adapter ID (which contains the VM ID and the Adapter ID).

```conf
# ExampleVM [Default Switch]
172.91.92.21 9ADC2172-20A2-42E0-9F73-22709ACB8CD0.ec9941cb-bbf9-41d5-b242-259b6d9fade7.hyper-v.localhost # {"Id":"Microsoft:EC9941CB-BBF9-41D5-B242-259B6D9FADE7\\9ADC2172-20A2-42E0-9F73-22709ACB8CD0","Modified":"2020-04-22T22:26:23-07:00"}
fe80::192a:f88a:2e6b:3eeb 9ADC2172-20A2-42E0-9F73-22709ACB8CD0.ec9941cb-bbf9-41d5-b242-259b6d9fade7.hyper-v.localhost # {"Id":"Microsoft:EC9941CB-BBF9-41D5-B242-259B6D9FADE7\\9ADC2172-20A2-42E0-9F73-22709ACB8CD0","Modified":"2020-04-22T22:26:23-07:00"}
```

After modification:

```conf
# ExampleVM [Default Switch]
172.91.92.21 example-vm.example.com # {"Id":"Microsoft:EC9941CB-BBF9-41D5-B242-259B6D9FADE7\\9ADC2172-20A2-42E0-9F73-22709ACB8CD0","Modified":"2020-04-22T22:26:23-07:00"}
fe80::192a:f88a:2e6b:3eeb example-vm.example.com # {"Id":"Microsoft:EC9941CB-BBF9-41D5-B242-259B6D9FADE7\\9ADC2172-20A2-42E0-9F73-22709ACB8CD0","Modified":"2020-04-22T22:26:23-07:00"}
```

## Installing

Run `Install.ps1` as an Administrator

## Uninstalling

Remove `%ProgramFiles%\Hyper-V HostsFile Tracker` directory and its contents and the `\Hyper-V HostsFile Tracker` Scheduled Task.

## Alternatives

If you just need to have stable hostnames for changing IP address consider using the automatically-created entries in `%WINDIR%\System32\drivers\etc\hosts.ics` (do not modify this file).
