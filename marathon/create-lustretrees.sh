#!/bin/bash

set -euf -o pipefail

function join { local IFS="$1"; shift; echo "$*"; }

mpistat_dir="/lustre/scratch114/teams/hgi/lustre_reports/mpistat/data"
marathon_template="/nfs/humgen01/teams/hgi/conf/marathon/lustretree.json.template"
marathon_config="/home/mercury/marathonctl.config"
marathonctl="marathonctl -c ${marathon_config} -f json"

volumes=(112 113 114 115 116 117 118)
declare -A mem_gb=([112]=30 [113]=31 [114]=20 [115]=74 [116]=250 [117]=50 [118]=240)
#declare -A mem_gb=([112]=30 [113]=31 [114]=20 [115]=74 [116]=240 [117]=50 [118]=200)
#declare -A mem_gb=([108]=48 [109]=48 [110]=56 [111]=132 [112]=30 [113]=31 [114]=20 [115]=74 [116]=216 [117]=14 [118]=170)
# actual dir count and usage 2/2/2017: 
#fs combinations directory_count gb_footprint
#108 7334 3496033 54
#109 11212 3443401 48
#110 11098 4189196 57
#111 2212 10494146 127
#112 1490 2057701 32
#113 8985 2136095 29
#114 4367 1281230 15
#115 3617 5642497 65
#116 NA NA NA
#117 2023 693483 9
#118 3230 11468637 136
# new sizes based on 6GB + 10GB/1M directories:
#declare -A mem_gb=([108]=48 [109]=48 [110]=56 [111]=132 [112]=30 [113]=31 [114]=20 [115]=74 [116]=216 [117]=14 [118]=144)
#declare -A mem_gb=([108]=48 [109]=48 [110]=56 [111]=132 [112]=30 [113]=31 [114]=20 [115]=74 [116]=193 [117]=14 [118]=144)
#declare -A mem_gb=([108]=72 [109]=72 [110]=96 [111]=96 [112]=72 [113]=72 [114]=48 [115]=72 [116]=196 [117]=24 [118]=96)
#declare -A mem_gb=([108]=125 [109]=63 [110]=65 [111]=45 [113]=46 [114]=16 [115]=46 [116]=54)
# dat file sizes associated with these memory requirements
# $ ls -lhS /lustre/scratch114/teams/hgi/lustre_reports/mpistat/data/20160301_1*
# -rw-r--r-- 1 root hgi 888M Mar  1 03:28 /lustre/scratch114/teams/hgi/lustre_reports/mpistat/data/20160301_109.dat.gz
# -rw-r--r-- 1 root hgi 859M Mar  1 04:22 /lustre/scratch114/teams/hgi/lustre_reports/mpistat/data/20160301_113.dat.gz
# -rw-r--r-- 1 root hgi 858M Mar  1 03:25 /lustre/scratch114/teams/hgi/lustre_reports/mpistat/data/20160301_110.dat.gz
# -rw-r--r-- 1 root hgi 737M Mar  1 03:10 /lustre/scratch114/teams/hgi/lustre_reports/mpistat/data/20160301_108.dat.gz
# -rw-r--r-- 1 root hgi 491M Mar  1 04:00 /lustre/scratch114/teams/hgi/lustre_reports/mpistat/data/20160301_111.dat.gz
# -rw-r--r-- 1 root hgi 475M Mar  1 02:31 /lustre/scratch114/teams/hgi/lustre_reports/mpistat/data/20160301_116.dat.gz
# -rw-r--r-- 1 root hgi 353M Mar  1 04:49 /lustre/scratch114/teams/hgi/lustre_reports/mpistat/data/20160301_114.dat.gz
# -rw-r--r-- 1 root hgi 189M Mar  1 02:27 /lustre/scratch114/teams/hgi/lustre_reports/mpistat/data/20160301_115.dat.gz

# load required modules
module purge
module add hgi/mustache/1.0.2
module add hgi/jq/1.5-regex
module add hgi/marathonctl/git-20160227-3e2e8f6b

if [ $# -ge 1 ]; then
  date=$1
else
  # get most recent date with a full set of mpistat data
  date=$((cd "${mpistat_dir}" && set +f && ls *.dat.gz && set -f) | awk 'BEGIN {FS="_"} $2~/^('$(join '|' ${volumes[@]})')/ {print $1}' | sort | uniq -c | awk '$1=='${#volumes[@]}' {print $2}' | sort -rg | head -n1)
fi
>&2 echo "Will start lustretree servers for ${date}"

# check if marathon application group has already been created for this date
app_count=$(${marathonctl} group list /production/lustretree/${date} | jq '.apps | length' || echo "0")
if [[ "${app_count}" ]] && [ "${app_count}" -gt 0 ]; then
    >&2 echo "Application group /production/lustretree/${date} already exists with ${app_count} apps"
    exit 0
fi

# make group and passwd files so lustretree can resolve uids and gids to names
groupfile="${mpistat_dir}/${date}.group"
passwdfile="${mpistat_dir}/${date}.passwd"
getent group > "${groupfile}"
getent passwd > "${passwdfile}"

>&2 echo "Creating marathon app group"
declare -A apps
for vol in ${volumes[@]}; do
  apps+=(["${vol}"]=$(
  (
      echo "date: ${date}"
      echo "vol: ${vol}"
      echo "mem_gb: ${mem_gb[${vol}]}"
      echo "dat_file: ${mpistat_dir}/${date}_${vol}.dat.gz"
      echo "group_file: ${groupfile}"
      echo "passwd_file: ${passwdfile}"
  ) | mustache - "${marathon_template}"))
done
app_group=$(echo '{"id":"/production/lustretree/'${date}'","apps":['$(join ',' "${apps[@]}")']}')
>&2 echo "App group JSON: ${app_group}"
marathon_group_file="${mpistat_dir}/${date}.marathon_group.json"
echo "${app_group}" > ${marathon_group_file}
${marathonctl} group create ${marathon_group_file}

>&2 echo "Done."
echo "Created AppId: /production/lustretree/${date}"
