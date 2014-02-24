#!/bin/bash

CERT_FILE="/etc/ssl/certs/ca-certificates.crt"
CERT_OLD_STRING1="MIIDqDCCA1KgAwIBAgIQXDYmJ05G4I1GHbz4kEaL/jANBgkqhkiG9w0BAQUFADCB"
LEN_OLD_CERT1=21

CERT_OLD_STRING2="MIIFNjCCBB6gAwIBAgIQZXwrLeIjN4BKHDyQJvbXrDANBgkqhkiG9w0BAQUFADCB"
LEN_OLD_CERT2=29

CERT_NEW_STRING="MIIFUjCCBDqgAwIBAgIRAIpICyLS/B4U+D4AbhKMUuYwDQYJKoZIhvcNAQEFBQAw"
CERT_FILE_NEW="-----BEGIN CERTIFICATE-----
MIIEpjCCA46gAwIBAgIQEOd26KZabjd+BQMG1Dwl6jANBgkqhkiG9w0BAQUFADCB
lzELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAlVUMRcwFQYDVQQHEw5TYWx0IExha2Ug
Q2l0eTEeMBwGA1UEChMVVGhlIFVTRVJUUlVTVCBOZXR3b3JrMSEwHwYDVQQLExho
dHRwOi8vd3d3LnVzZXJ0cnVzdC5jb20xHzAdBgNVBAMTFlVUTi1VU0VSRmlyc3Qt
SGFyZHdhcmUwHhcNMDYwNDEwMDAwMDAwWhcNMjAwNTMwMTA0ODM4WjBiMQswCQYD
VQQGEwJVUzEhMB8GA1UEChMYTmV0d29yayBTb2x1dGlvbnMgTC5MLkMuMTAwLgYD
VQQDEydOZXR3b3JrIFNvbHV0aW9ucyBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkwggEi
MA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDD3TbMg8MYVbCW2RMl0yaGSDi7
Fn/xnyn2/QPx7U0mmlbwtRoazebMhVVApLXQDcoi7z0jxn5szLyh6XxQRuC9FK1l
EsILEWlSCgeSH3NvwbrXYvDOAC40pcjmLw/sDepEYXVo5eTcgDZP2nhdUyWUlPVP
Ljpgbwym2bP2Ki4DEtUmQgdRsmRXcdwhHInHaaPm+8J7bu8Mh/tQZOhOS+/ncZuD
Y2HJMo2M7BSn5ImtPysmZOSFQvKJUOE6vhXjRSXiWsuMP+AzHjUJWoTqfl2h9ZGA
CigGt8sxQSVhiwHpVqL2Pl8v88RD9hmUdYNMoYJCOsa6xAkwpuF1AlG5XmSLAgMB
AAGjggEgMIIBHDAfBgNVHSMEGDAWgBShcl8mGyiYQ5VdBzfVhZadS9LDRTAdBgNV
HQ4EFgQUPEHijwgIqUwliY1txTjQ/IWMYhcwDgYDVR0PAQH/BAQDAgEGMBIGA1Ud
EwEB/wQIMAYBAf8CAQAwGQYDVR0gBBIwEDAOBgwrBgEEAYYOAQIBAwEwRAYDVR0f
BD0wOzA5oDegNYYzaHR0cDovL2NybC51c2VydHJ1c3QuY29tL1VUTi1VU0VSRmly
c3QtSGFyZHdhcmUuY3JsMFUGCCsGAQUFBwEBBEkwRzBFBggrBgEFBQcwAoY5aHR0
cDovL3d3dy51c2VydHJ1c3QuY29tL2NhY2VydHMvVVROQWRkVHJ1c3RTZXJ2ZXJf
Q0EuY3J0MA0GCSqGSIb3DQEBBQUAA4IBAQBoq/zvgGsYsrCzo0WJy1PFouavCKn9
/w9JrP/kn9dBfKPFouiq4FchLcOqfAxMKAt59O5MMq15Dn6iXjQYT99U8b1ofOPT
10ZebWTC922IgnMM75mF6qnvMkrwg59zkQykPisxUaZijxWE+aY6EjA/2m74zMcZ
kg9c9P4X8ZUIR1IsUI/om6XurnAziZGC/jCqdnZZ12wY0ysSWx0oHXhx9s02oukH
SEQ751duggqtxYrd6FO0ca8T0gadN21TP4o1CPr+ohbmuW9cVjnWxqrvGWfOE8W4
lQX7CkTJn6lAJUsyEa8H/gjVQnHp4VOLFR/dKgeVcCRvZF7Tt5AuiyHY
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIFUjCCBDqgAwIBAgIRAIpICyLS/B4U+D4AbhKMUuYwDQYJKoZIhvcNAQEFBQAw
YjELMAkGA1UEBhMCVVMxITAfBgNVBAoTGE5ldHdvcmsgU29sdXRpb25zIEwuTC5D
LjEwMC4GA1UEAxMnTmV0d29yayBTb2x1dGlvbnMgQ2VydGlmaWNhdGUgQXV0aG9y
aXR5MB4XDTA5MTExMzAwMDAwMFoXDTEzMTExOTIzNTk1OVowgeYxCzAJBgNVBAYT
AklUMQ4wDAYDVQQREwUyMDAxMTELMAkGA1UECBMCTUkxETAPBgNVBAcTCENvcmJl
dHRhMSMwIQYDVQQJExpWaWFsZSBBbGRvIEJvcmxldHRpLCA2MS82MzEfMB0GA1UE
ChMWTWFnbmV0aSBNYXJlbGxpIFMucC5BLjEfMB0GA1UECxMWTWFnbmV0aSBNYXJl
bGxpIFMucC5BLjEhMB8GA1UECxMYU2VjdXJlIExpbmsgU1NMIFdpbGRjYXJkMR0w
GwYDVQQDFBQqLm1hZ25ldGltYXJlbGxpLmNvbTCBnzANBgkqhkiG9w0BAQEFAAOB
jQAwgYkCgYEAkt4ihJLQIQo0zZDDt5p8CSklOr3g+TCRO1MfYDKRxyM/kSxMuPCu
fXR+gXtQkRRO8yq2GIlKEk9vD3Jd0kPkC6XAFPKbYgEQ4qLWk09oOarr9JuoYxZq
tFQaq+BJjD9zngfzDapEVSZXhmr7goR73i6Y3NGfCLMH4poAcDSZivUCAwEAAaOC
AgAwggH8MB8GA1UdIwQYMBaAFDxB4o8ICKlMJYmNbcU40PyFjGIXMB0GA1UdDgQW
BBTBr68s+ONbr1pVL4Z1ixba6szyDDAOBgNVHQ8BAf8EBAMCBaAwDAYDVR0TAQH/
BAIwADAdBgNVHSUEFjAUBggrBgEFBQcDAQYIKwYBBQUHAwIwawYDVR0gBGQwYjBg
BgwrBgEEAYYOAQIBAwEwUDBOBggrBgEFBQcCARZCaHR0cDovL3d3dy5uZXR3b3Jr
c29sdXRpb25zLmNvbS9sZWdhbC9TU0wtbGVnYWwtcmVwb3NpdG9yeS1jcHMuanNw
MHoGA1UdHwRzMHEwNqA0oDKGMGh0dHA6Ly9jcmwubmV0c29sc3NsLmNvbS9OZXR3
b3JrU29sdXRpb25zX0NBLmNybDA3oDWgM4YxaHR0cDovL2NybDIubmV0c29sc3Ns
LmNvbS9OZXR3b3JrU29sdXRpb25zX0NBLmNybDBzBggrBgEFBQcBAQRnMGUwPAYI
KwYBBQUHMAKGMGh0dHA6Ly93d3cubmV0c29sc3NsLmNvbS9OZXR3b3JrU29sdXRp
b25zX0NBLmNydDAlBggrBgEFBQcwAYYZaHR0cDovL29jc3AubmV0c29sc3NsLmNv
bTAfBgNVHREEGDAWghQqLm1hZ25ldGltYXJlbGxpLmNvbTANBgkqhkiG9w0BAQUF
AAOCAQEAofREjzEFdzEVbzwyip2H459p03+BJVD00jaYXambwAJoAqyoKfXC1C6W
lkV+uqOZCoLRzEZ/r7l57l+FuF1wk1PWM5+hZOZBrj0YOUP/0jm8UZlUf1gLeIk1
9Ex0i/eg+koAwOuKDLCtsVO5xulcPjhS/cOAN4co/sI5WlYpwXQFWIFqNyqyaupn
Z+GFbMv+3RKZ0jbO6MLJ/bMuLl/h8qhf1aqxEhGCz/0iEHNdaGIqFXD4Ht2z6g4n
b8KrkKNAQrGP5VQtqGn1PU0UcJlrGHFvo+zGgdmzb8ZEeFeZQJA+a9ey+ZhbeOM1
4mx9//OVeTRfczj9BVv2GqCEca0yAA==
-----END CERTIFICATE-----"

#
# MAIN
#

echo "Adding new repositories ..."
echo "Old repositories will be available in /etc/apt/sources.list.`date +%F-%R`..."
if [ -f /etc/apt/sources.list ]
then
  if [ ! -f "/etc/apt/sources.list.`date +%F-%R`" ]
  then
        mv /etc/apt/sources.list /etc/apt/sources.list.`date +%F-%R`

echo "#New HTTPS Amazon Repositories:

deb https://ftpbin:Reply.2@itpsmgit1.magnetimarelli.com/ftpbin/outgoing/ubuntu-bins-pu0314 lucid main windriver
deb https://ftpsrc:Concept.2@itpsmgit1.magnetimarelli.com/ftpsrc/outgoing/ubuntu-srcs-pu0314 lucid main windriver" > /etc/apt/sources.list

  fi
fi

echo "Installing new certificate for HTTPS ..."
if [ -f ${CERT_FILE} ]
then

  grep "${CERT_NEW_STRING}" ${CERT_FILE} 2>&1 > /dev/null
  if [ $? -ne 0 ]
  then
    cp -p ${CERT_FILE} ${CERT_FILE}.`date +%F-%R`
#   echo "${CERT_FILE_NEW}" >> ${CERT_FILE}
#   sed -i "1i${CERT_FILE_NEW}" ${CERT_FILE}
    t=$(echo "${CERT_FILE_NEW}" | cat - ${CERT_FILE}); echo "$t" > ${CERT_FILE}
  fi

  grep "${CERT_OLD_STRING1}" ${CERT_FILE} 2>&1 > /dev/null
  if [ $? -eq 0 ]
  then
    n=`grep -n "${CERT_OLD_STRING1}" ${CERT_FILE} | awk -F ":" '{print $1}'`

    if [ ! -z $n ]
      then
        first_line=`expr \( $n \- 1 \)`
        last_line=`expr \( $first_line \+ $LEN_OLD_CERT1 \)`
        (echo "${first_line},${last_line}d"; echo 'wq') | ex -s "${CERT_FILE}"
    fi 
  fi

  grep "${CERT_OLD_STRING2}" ${CERT_FILE} 2>&1 > /dev/null
  if [ $? -eq 0 ]
  then
    n=`grep -n "${CERT_OLD_STRING2}" ${CERT_FILE} | awk -F ":" '{print $1}'`

    if [ ! -z $n ]
      then
        first_line=`expr \( $n \- 1 \)`
        last_line=`expr \( $first_line \+ $LEN_OLD_CERT2 \)`
        (echo "${first_line},${last_line}d"; echo 'wq') | ex -s "${CERT_FILE}"
    fi 
  fi
fi

echo "Installation completed successfully"
echo ""
echo "############################################"
echo "#        Remember to check proxies         #"
echo "############################################"
