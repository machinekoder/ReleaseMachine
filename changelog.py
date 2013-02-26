#!/usr/bin/python3
#
# Copyright 2012 Alexander Rössler <mail.aroessler@gmail.com>
#
# changelog.py
# Script for creating rpm and deb changelogs
#
# changelog.py is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# changelog.py is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with changelog.py.  If not, see <http://www.gnu.org/licenses/>.

import time, datetime
import sys

f = open("changelog.txt", "r")
debLog = open("changelog-deb.txt", "w")
rpmLog = open("changelog-rpm.txt","w")

author =  sys.argv[2]
name = sys.argv[1]

lines=f.readlines()

for line in lines:
   list=line.split(":")
   list[0] = list[0].strip()
   list[1] = list[1].strip()
   list[2] = list[2].strip()
   
   timeFormat="%d.%m.%Y"
   rpmOutputFormat="%a %b %d %Y"
   debOutputFormat="%a, %d %b %Y %H:%M:%S +0100"
   dateTime = datetime.datetime.fromtimestamp(time.mktime(time.strptime(list[1], timeFormat)))
   
   rpmLog.write("* " + dateTime.strftime(rpmOutputFormat) + " " + author + "\n")
   rpmLog.write("- " + list[2] + "\n")
   
   debLog.write(name + " (" + list[0] + ") stable; urgency=high\n\n")
   debLog.write("  * " + list[2] + "\n\n")
   debLog.write(" -- " + author + "  " + dateTime.strftime(debOutputFormat) + "\n\n")
   
f.close()
debLog.close()
rpmLog.close()