#!/bin/bash
sed '/uid/a gidnumber: 500\
objectclass: inetOrgPerson\
objectclass: posixAccount\
objectclass: top\
userpassword: {MD5}fvA7yxL/+fUIgKPxwTvZuQ==' nomeLDIF.ldif >> NOMELDIF-FINAL.ldif
