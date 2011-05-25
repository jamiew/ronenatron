#!/bin/sh

dirname=$(dirname $0)

while read line; do
  echo $line
  open -a 'Google Chrome' $line
  sleep 2
done < $dirname/urls.txt

echo "Done"
sleep 2
exit 0
