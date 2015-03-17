#!/usr/bin/env python

"""
Create a certificate request and sign it with an existing CA certificate
"""

import sys, getopt, os, time, shutil, zipfile, cgi
from M2Crypto import RSA, X509, EVP, ASN1, m2
from _pyio import open

keystorepass = 'secret'

zip_file = None

def passphrase_callback(v):
    return keystorepass

def keyGenCallback(p, n, out):
    out = open("/dev/null", 'w')
    #if we don't do this, RSA.gen_key will write to stdout

def generateRSAKey():
    return RSA.gen_key(1024, m2.RSA_F4, keyGenCallback)

def makePKey(key):
    pkey = EVP.PKey()
    pkey.assign_rsa(key)
    return pkey

def makeRequest(pkey, server_dns):
    req = X509.Request()
    req.set_version(3)
    req.set_pubkey(pkey)
    name = X509.X509_Name()
    name.CN = server_dns
    req.set_subject_name(name)
    req.set_pubkey(pkey)
    req.sign(pkey, 'sha1')
    return req

def createJKS(fqdn):
    java_home = os.environ['JAVA_HOME']
    if java_home is None:
        raise 'JAVA_HOME needs to be set.'

    # an empty Java keystore         
    jks_template = 'template.jks'
    jksfile = ''.join([fqdn, '.jks'])
    certfile = ''.join([fqdn, '.crt'])
    #keyfile = ''.join([fqdn, '.der'])
    shutil.copyfile(jks_template, jksfile)

    #os.spawnlp(os.P_WAIT, ''.join([java_home, '/bin/java']), 'java', '-cp', '.', 'KeyStoreImport', jksfile, keystorepass, fqdn, certfile, keyfile, keystorepass)
    os.spawnlp(os.P_WAIT, 'keytool', 'keytool', '-importcert', '-noprompt', '-alias', fqdn,  '-file', certfile, '-keystore', jksfile, '-storepass', keystorepass)

def signWithCACert(req, validity):
    cert = X509.X509()
    cert.set_serial_number(getSerialNumber())
    t = long(time.time())
    now = ASN1.ASN1_UTCTIME()
    now.set_time(t)
    nowPlusYear = ASN1.ASN1_UTCTIME()
    nowPlusYear.set_time(t + 60 * 60 * 24 * validity)
    cert.set_not_before(now)
    cert.set_not_after(nowPlusYear)
    issuerCert = X509.load_cert('CA/cacert.pem', X509.FORMAT_PEM)
    cert.set_issuer(issuerCert.get_subject())
    cert.set_subject(req.get_subject())
    cert.set_pubkey(req.get_pubkey())
    issuerKey = EVP.load_key('CA/private/cakey.pem', passphrase_callback)
    cert.sign(issuerKey, 'sha1')
    return cert

def getSerialNumber():
    s_file = open("serial", 'rb')
    serial = int(s_file.read())
    s_file.close()
    s_file = open("serial", "wb")
    s_file.write("".join([str(serial + 1), "\n"]))
    s_file.close()
    return serial

def createPFX(fqdn):
    certfile = ''.join([fqdn, '.crt'])
    keyfile = ''.join([fqdn, '.key'])
    pfxfile = ''.join([fqdn, '.pfx'])
    inpass = ":".join(['pass', keystorepass])
    outpass = ":".join(['pass', keystorepass])
    os.spawnlp(os.P_WAIT, 'openssl', 'openssl', 'pkcs12', '-export', '-inkey', keyfile, \
            '-in', certfile, '-out', pfxfile, '-passin', inpass, '-passout', outpass)
    
def deleteFiles(fqdn):
    os.remove('.'.join([fqdn, 'key']))
    os.remove('.'.join([fqdn, 'der']))
    os.remove('.'.join([fqdn, 'crt']))
    os.remove('.'.join([fqdn, 'jks']))
    os.remove('.'.join([fqdn, 'pfx']))
    os.remove('.'.join([fqdn, 'zip']))
    
def makeZip(fqdn):
    zip_file = zipfile.ZipFile(''.join([fqdn, '.zip']), "w", zipfile.ZIP_STORED)
    zip_file.write(''.join([fqdn, '.key']))
    zip_file.write(''.join([fqdn, '.der']))
    zip_file.write(''.join([fqdn, '.crt']))
    zip_file.write(''.join([fqdn, '.jks']))
    zip_file.write(''.join([fqdn, '.pfx']))
    #zip_file.append("README"") TODO
    zip_file.close()
    
def sendZip(fqdn):
    sys.stdout = sys.__stdout__
    theFile = open(''.join([fqdn, '.zip']), "rb")
    buff = theFile.read()

    print "Content-Type: application/x-download"
    print cgi.escape("Content-Disposition: attachment;filename=") + ''.join([fqdn, '.zip'])
    print "Content-Length: " +  str(len(buff))
    print
    print buff
    theFile.close

def makeCert(fqdn, validity):
    #Generate RSA Key
    rsa = generateRSAKey()
    rsa.save_key(''.join([fqdn, '.key']), cipher=None, callback=passphrase_callback)
    rsa.save_key_der(''.join([fqdn, '.der']))

    #Generate Pub/Pri Keys
    pkey = makePKey(rsa)

    #Generate Certificate Request
    req = makeRequest(pkey, fqdn)

    #Create CA-signed certificate
    cert = signWithCACert(req, validity)

    #Save Certificate
    cert.save(''.join([fqdn, '.crt']), X509.FORMAT_PEM)
    #Concatenate CA certificate in same file
    #stream = open(''.join([fqdn, '.crt']), 'ab')
    #shutil.copyfileobj(open('CA/cacert.pem', 'rb'), stream)
    #stream.close()
    
    # Generate JKS
    createJKS(fqdn)

    # Generate PFX
    createPFX(fqdn)
    
    #Make zip archive
    makeZip(fqdn);
    
    #Send the file
    sendZip(fqdn)
    
    #Delete files
    deleteFiles(fqdn)

def usage():

    print "Usage:"
    print "python gencrt.py -n <fqdn>"

if __name__ == '__main__':
    print "in main"
    try:                             
        opts, args = getopt.getopt(sys.argv[1:], "hn:", ["help", "fqdn="])
    except getopt.GetoptError:
        usage()
        sys.exit(2)                  

    fqdn = None
    for opt, arg in opts:
        if opt in ("-h", "--help"):
            usage()  
            sys.exit()
        elif opt in ("-n", "--fqdn"):
            fqdn = arg

    if fqdn == None:
        usage()  
        sys.exit(2)
    
    makeCert(fqdn, 365)
