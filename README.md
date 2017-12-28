# PKI scripts and cheats (for newbies)


## Intro

Remember: 

- Sharing is caring
- Crypto is hard - so they say...
- PKI based auth is much stronger than HTTP-Basic over HTTPS - unless your CA lives on the server it's 'protecting'
- We're all lazy at times and want the "easy way"

What I wanted is to have a dedicated CA and resulting PKI infrastructure for each of my lab projects that I run on the public Internet. This gives mi granularity of access on per-project basis, so easy of creating new CAs and server/client keys becomes essential! 

That's how the small, yet useful scripts came to be.

## PKI based auth basics

You can just use the scripts provided, but it helps to understand a few things before you start, so let's get over it.

If you want your clients to authenticate to your (web)service through PKI, you need to do 3, obvious and simple things:

- Create your own, private CA - one you and all your users will trust
- Generate certificates for server(s)/client(s) - signed by your own CA
- Configure your service to use those and do what you want <-- pls RTFM!

Once you have those elements in place and add key files as required, it will start working and only your actual users that present valid key signed by your own CA will be able to connect (more on that later).

When I say 'add key files as required' I mean distribute `ca.crt` and individual client keys to each of the clients, import them to local key stores (RTFM!) and set required trust level for your private CA. That has to be done on each endpoint.

Finally, you will see a bunch of files created in the process - it helps to know what's what:

- `.key` is a **PRIVATE key** of a respective certificate; normally password protected but password can be removed if needed. Keep this one safe!
- `.csr` is a Certificate Signing Request, best explained as **public key** that is not yet signed. Once CA signs it, you can delete it.
  - when you need to renew your certificate you can send off the same CSR file for signing, but that's not the best approach
  - ideally you will rotate (generate new CSR) each time, even if it is based on the same key
  - better yet, rotate both - get new key and CSR when renewing certificates
- `.crt` is a signed version of the `.csr`
- `.pem` can contain either a private or public, or both, which is the most common situation; it's literally `.crt` file with `.key` appended to it, in that order
- `.p12` is PKCS12 formatted `.pem` equivalent, so again contains both public and private key; this file can be imported into your keychain or certificate store on your OS

The scripts here willc reate also files like `<something>-NOPASS.<something>`; those are versions that had password removed from the private key, so keep them safe.

> **Technical footnote:**
> 
> In reality, both the server and the client certificate are same thing as far as CA is concerned. If you installed in your browser the certificate intended for your server and vice versa it would still work (see CN note in client cert section).

## Creating your own CA

Extremely simple, just make sure you chose a memorable password for CA key - you will need to use it every time you issue client certificates.

> **Note to self** - I often pick one password per project and use that password for both CA and all client keys I generate. Not the best practice - I know, but as the CA is held completely off-line anyway, there's no chance for anyone else to create a key for themselves without my knowledge and support. This makes it faster and easier to generate certificates, especially in batches, as you can just paste the password when prompted and be done with it.

I've put `************` in the snippet below to show where I pasted the apssword.

```
$ ./CA.sh
Generating RSA private key, 4096 bit long modulus
...................................................................................................++
.....................................................................................................................................................................................++
e is 65537 (0x10001)
Enter pass phrase for ca.key: ************
Verifying - Enter pass phrase for ca.key: ************
Enter pass phrase for ca.key: ************
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:GB
State or Province Name (full name) [Some-State]:London
Locality Name (eg, city) []:London
Organization Name (eg, company) [Internet Widgits Pty Ltd]: project lab
Organizational Unit Name (eg, section) []:
Common Name (e.g. server FQDN or YOUR name) []: project lab CA
Email Address []:
```

That's all, now you have `ca.crt` and `ca.key` in the same folder as the script. `ca.crt` you will distribute to all clients, but `ca.key` needs to stay private - **DO NOT** put it on the server the CA is protecting, there's no excuse for that!

If you need to generate lots of client certificates, you may risk it a bit and remove password from the CA signing key, but the scripts here don't go that far. Copy and paste is good enough and I normally do handful of certs, not hundreds, so that's easily manageable.

## Generating client/server certificates

Once out CA is ready, we need to generate minimum two certificates - server and client. 

**Notes:**

- The process is exactly the same for both server and client
- For (web)server certificate, make sure to provide full server hostname (matching your URL) when answering the `Common Name (e.g. server FQDN or YOUR name)` question, or you will be getting certificate warnings
- The CN doesn't matter that much for the client certificate, but it's good idea to have it somewhat descriptive - for example you may want to write that to your access logs

Let's get one then - below is `USER1` key creation process.

```
$  ./client.sh USER1
Generating RSA private key, 4096 bit long modulus
...++
......................................................................................................................................++
e is 65537 (0x10001)
Enter pass phrase for USER1.key: ************
Verifying - Enter pass phrase for USER1.key: ************
Enter pass phrase for USER1.key: ************
writing RSA key
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [AU]:GB
State or Province Name (full name) [Some-State]:London
Locality Name (eg, city) []:London
Organization Name (eg, company) [Internet Widgits Pty Ltd]: project lab
Organizational Unit Name (eg, section) []:
Common Name (e.g. server FQDN or YOUR name) []: USER1 @ project lab
Email Address []:

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:
An optional company name []:
Signature ok
subject=/C=GB/ST=London/L=London/O=project lab/CN=USER1 @ project lab
Getting CA Private Key
Enter pass phrase for ca.key: ************
Enter Export Password: ************
Verifying - Enter Export Password: ************
```

What happened here?

- We generated client key, protected with the password (it is required) - file `USER1.key`
- We removed the password from the key file so services don't complain when they (auto) start - file `USER1-NOPASS.key` **<-- INSECURE** 
- We created client's Certificate Signing Request matching the key generated earlier - file `USER1.csr`
- Our CA has signined the CSR and created `USER1.crt`
- Finally convert all of that into password protected PKCS12 file, so it can be moved and imported into user key stores - the import password is the same as for our CA (for reasons explained earlier)

There's also one more line in the script (but commented out), that generates similar in PEM format. Please uncomment it if you need it - I've included it for completeness only.

## Checking certificate information

```
$ openssl x509 -in USER1.crt -noout -text
Certificate:
    Data:
        Version: 1 (0x0)
        Serial Number: 15 (0xf)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=GB, ST=London, L=London, O=project lab, CN=project lab CA
        Validity
            Not Before: Dec 28 00:25:14 2017 GMT
            Not After : Dec 28 00:25:14 2018 GMT
        Subject: C=GB, ST=London, L=London, O=project lab, CN=USER1 @ project lab
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (4096 bit)
                Modulus:
                    00:b2:74:c6:0b:72:b0:a8:bc:34:51:f7:eb:64:ad:
                    7f:fe:64:c2:a9:dd:d1:35:b6:38:82:ec:a4:37:66:
                    [...]
```
The important lines are `Issuer` and `Subject` - this is what you want to see, right?

## Making it work - nginx reverse proxy configuration

I use this one to reverse proxy traffic to my ELK docker instance, just because original ELK has no auth at all (unless you install X-Pack plugin), so PKI on reverse proxy is a fairly reasonable approach.


```
server {
    listen 443 ssl;
    server_name SERVER_NAME_MATCHING_CN_IN_CERTIFICATE;

    ssl_certificate      /etc/nginx/certs/server.crt;
    ssl_certificate_key  /etc/nginx/certs/server-NOPASS.key;

    # add our CA certificate
    ssl_client_certificate /etc/nginx/certs/ca.crt;

    # enable client auth (PKI) as required [on/optional]
    ssl_verify_client on;

    ssl_protocols       TLSv1.1 TLSv1.2;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://127.0.0.1:5601;
    }
}
```

## Security - what do others see?

If you put your stuff up on the internet, expect someone to scan you within seconds, so let's do the same and see how our web endpoint shows up after PKI authentication is required.

```
$ sslscan --no-failed somehost.somedomain.tld:443
                   _
           ___ ___| |___  ___ __ _ _ __
          / __/ __| / __|/ __/ _` | '_ \
          \__ \__ \ \__ \ (_| (_| | | | |
          |___/___/_|___/\___\__,_|_| |_|

                  Version 1.8.2
             http://www.titania.co.uk
        Copyright Ian Ventura-Whiting 2009

Testing SSL server somehost.somedomain.tld on port 443

  Supported Server Cipher(s):

  Prefered Server Cipher(s):

  SSL Certificate:
    Version: 0
    Serial Number: 1
    Signature Algorithm: sha256WithRSAEncryption
    Issuer: /C=GB/ST=London/L=London/O=project lab/CN=project lab CA
    Not valid before: Dec 22 18:45:35 2017 GMT
    Not valid after: Dec 22 18:45:35 2018 GMT
    Subject: /C=GB/ST=London/L=London/O=project lab/CN=somehost.somedomain.tld
    Public Key Algorithm: rsaEncryption
    RSA Public Key: (4096 bit)
      Public-Key: (4096 bit)
      Modulus:
          00:aa:b3:61:ca:92:14:68:eb:10:57:80:49:9c:6d:
          85:db:94:c4:d5:81:eb:87:27:73:e4:31:6b:b8:c0:
          [...]
      Exponent: 65537 (0x10001)
  Verify Certificate:
    self signed certificate in certificate chain
```

No ciphers confirmed because all PKI handshakes failed - scanner didn't have valid client certificate, so all it can gather is the public key of the server - that's it :-)
