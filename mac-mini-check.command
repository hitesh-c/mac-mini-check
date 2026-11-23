#!/bin/bash
# Run in Terminal on the Mac being inspected.
export LC_ALL=C
smartctl=$(command -v smartctl)
if [[ -z "$smartctl" ]]; then
  for candidate in /opt/homebrew/sbin/smartctl /opt/homebrew/bin/smartctl /usr/local/sbin/smartctl /usr/local/bin/smartctl; do
    if [[ -x "$candidate" ]]; then smartctl=$candidate; break; fi
  done
fi
printf '\n=== Mac hardware ===\n'
hardware=$(system_profiler SPHardwareDataType)
printf '%s\n' "$hardware" | awk '!/UUID|UDID/'
field() {
  awk -F ': ' -v key="$1" '{sub(/^[[:space:]]+/, "", $1); if ($1 == key) {print $2; exit}}'
}
graphics=$(system_profiler SPDisplaysDataType)
printf '\n=== Graphics ===\n'
echo "$graphics" | awk '/Chipset Model:|Total Number of Cores:/'
gpu=$(echo "$graphics" | field 'Total Number of Cores')
[[ -n "$gpu" ]] || echo 'GPU core count unavailable from macOS.'

printf '\n=== macOS ===\n'
sw_vers
printf '\n=== Current device enrollment ===\n'
profiles status -type enrollment || echo 'Enrollment status unavailable. Verify online during Setup Assistant.'
printf '\n=== Internal physical storage ===\n'
disks=$(diskutil list | awk '/^\/dev\/disk[0-9]+ \(internal, physical\)/ {print $1}')
if [[ -z "$disks" ]]; then
  echo 'Could not identify an internal physical disk. Inspect the disk list manually.'
  diskutil list
fi
for disk in $disks; do
  echo "$disk"
  diskutil info "$disk" | awk '/Device \/ Media Name|Disk Size|Total Size|Protocol:|SMART Status|Solid State|Device Location/'
  if [[ -n "$smartctl" ]]; then
    echo 'Drive health and lifetime counters (where supported)'
    "$smartctl" -a "$disk"
    result=$?
    if (( result & 2 )) && [[ -t 0 ]]; then
      read -r -p 'Retry this drive with administrator access? [y/N] ' retry
      if [[ "$retry" == [Yy] ]]; then sudo "$smartctl" -a "$disk"; result=$?; fi
    fi
    if (( result != 0 )); then echo "smartctl status $result. Review errors or health warnings above."; fi
  else
    echo 'Detailed SSD usage unavailable. Install smartmontools and rerun to read supported lifetime counters.'
  fi
done

printf '\n=== Compare with the listing or invoice ===\n'
shopt -s nocasematch
compare() {
  local label="$1" actual="$2" expected
  [[ -n "$actual" ]] || { echo "UNCHECKED: $label unavailable."; return; }
  read -r -p "Expected $label (Return to skip): " expected
  [[ -n "$expected" ]] || return 0
  if [[ "$actual" == "$expected" ]]; then
    echo "Match: $label."
  else
    echo "WARNING: $label differs. Expected '$expected', detected '$actual'."
  fi
}
model=$(echo "$hardware" | field 'Model Name')
if [[ -n "$model" && "$model" != 'Mac mini' ]]; then echo "WARNING: macOS identifies this computer as $model."; fi
if [[ -t 0 ]]; then
  chip=$(echo "$hardware" | field Chip)
  compare 'chip or processor (include Apple or Intel as shown)' "${chip:-$(echo "$hardware" | field 'Processor Name')}"
  compare 'CPU cores' "$(echo "$hardware" | field 'Total Number of Cores' | awk '{print $1}')"
  compare 'GPU cores (first reported GPU)' "$gpu"
  compare 'memory (include GB)' "$(echo "$hardware" | field Memory)"
  compare 'serial from the underside or invoice' "$(echo "$hardware" | field 'Serial Number (system)')"
  if [[ -n "$disks" ]]; then
    read -r -p 'Does the internal drive configuration above match the advertised storage? [y/n/Return to skip] ' storage
    [[ "$storage" != [Nn] ]] || echo 'WARNING: You flagged a storage discrepancy. Verify the capacity and drive type with the seller.'
  fi
else
  echo 'Run interactively to compare the advertised specifications.'
fi
printf '\n=== Repair history ===\n'
version=$(sw_vers -productVersion)
if [[ $(sysctl -n hw.optional.arm64 2>/dev/null) == 1 && ${version%%.*} -ge 26 ]]; then
  echo 'Open System Settings > General > About. Look for Parts & Service.'
  echo 'On Mac mini this check covers the logic board. Other repairs can go unreported.'
  if [[ -t 0 ]]; then
    read -r -p 'What do you see? 1 Genuine, 2 Used, 3 Unknown, 4 Unverified, 5 Finish Repair, 6 no entry, Return to skip: ' repair
    case "$repair" in
      1) echo 'REPAIR REPORTED: Apple identifies a genuine repair. Ask for its service record.' ;;
      2) echo 'WARNING: Apple reports a part previously installed in another Mac.' ;;
      3) echo 'WARNING: Apple labels the part Unknown. Ask the seller for a service assessment.' ;;
      4) echo 'WARNING: Apple reports an unverified replacement logic board.' ;;
      5) echo 'WARNING: Apple reports an unfinished repair. Ask the seller to complete it before purchase.' ;;
      6) echo 'No entry observed. Previous repairs are still possible.' ;;
      *) echo 'UNCHECKED: Repair history has not been reviewed.' ;;
    esac
  else
    echo 'UNCHECKED: Review Parts & Service in person.'
  fi
else
  echo 'UNCHECKED: Apple requires Apple silicon and macOS 26 or later to display Parts & Service. Ask for repair receipts.'
fi
