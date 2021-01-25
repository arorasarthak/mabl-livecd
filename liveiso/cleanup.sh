#!/bin/bash
set -eu -o pipefail
sudo umount ~/mabl-liveiso/livecdtmp/mnt
sudo mv ~/mabl-liveiso/livecdtmp/*.iso ~/mabl-liveiso/.
sudo rm -rf ~/mabl-liveiso/livecdtmp
