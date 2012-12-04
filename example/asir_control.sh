#!/bin/sh
set -x
dir="$(cd "$(dirname $0)" && /bin/pwd)"
PATH="$dir/../bin:$PATH"
export RUBYLIB="$dir/../example:$dir/../lib"
asir="asir verbose=9 config_rb=$dir/config/asir_config.rb" 
args="$*"
args="${args:-ALL}"
# set -e

#############################

case "$args"
in
  *resque*|*ALL*)

$asir start beanstalk conduit
sleep 1
if $asir alive beanstalk conduit; then
  echo "beanstalk conduit alive"
fi
$asir start beanstalk worker
sleep 1
$asir pid beanstalk worker
if $asir alive beanstalk worker; then
  echo "resque worker alive"
fi

ruby "$dir/asir_control_client_beanstalk.rb"
sleep 1
$asir stop beanstalk worker
sleep 1
$asir stop beanstalk conduit

;;
esac

#############################

exit 0
