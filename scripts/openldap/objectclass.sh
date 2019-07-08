#!/bin/sh
FILE=dn.txt

while read linha
do
    echo $linha >> objectclass.ldif
    echo "changetype: modify" >> objectclass.ldif
    echo "add: objectClass" >> objectclass.ldif
    echo "objectClass: organizationalNOME" >> objectclass.ldif
    echo "" >> objectclass.ldif
done < $FILE
