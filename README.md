# Mac mini check

A free, read-only Terminal script for inspecting a second-hand Mac mini. Run it on the Mac you are considering buying, with the seller’s listing or invoice nearby.

## Run it

1. Download [mac-mini-check.command](https://raw.githubusercontent.com/hitesh-c/mac-mini-check/main/mac-mini-check.command) to the Mac or a USB stick.
2. Open Terminal on the Mac. Type `/bin/bash` followed by a space, drag the downloaded file into Terminal, and press Return.
3. Enter the advertised specifications when prompted. Press Return to skip any you do not know.

The script shows the model, processor, CPU and GPU core counts where available, memory, serial number, enrollment status, and internal drive details. It flags differences between the specifications you enter and the ones macOS reports.

## SSD usage and repairs

For supported drive lifetime counters, install smartmontools and rerun the script. If Homebrew is already installed, use `brew install smartmontools`. The script can also use the macOS package from the [smartmontools releases](https://github.com/smartmontools/smartmontools/releases).

On supported Macs, the script guides you through reviewing Parts & Service and explains the entry you select. Apple’s Mac mini history covers the logic board. Other repairs can go unreported. [Apple’s parts and service history guide](https://support.apple.com/en-gb/123123)
