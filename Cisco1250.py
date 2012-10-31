#!/usr/bin/python

"""
@copyright: (c)Copyright 2012, Intel Corporation All Rights Reserved.
The source code contained or described herein and all documents related
to the source code ("Material") are owned by Intel Corporation or its
suppliers or licensors. Title to the Material remains with Intel Corporation
or its suppliers and licensors. The Material contains trade secrets and
proprietary and confidential information of Intel or its suppliers and
licensors.

The Material is protected by worldwide copyright and trade secret laws and
treaty provisions. No part of the Material may be used, copied, reproduced,
modified, published, uploaded, posted, transmitted, distributed, or disclosed
in any way without Intel's prior express written permission.

No license under any patent, copyright, trade secret or other intellectual
property right is granted to or conferred upon you by disclosure or delivery
of the Materials, either expressly, by implication, inducement, estoppel or
otherwise. Any license under such intellectual property rights must be express
and approved by Intel in writing.

@organization: UMG PSI GER System Integration
@summary: implementation of Cisco1250 family configurable AP
@since 06/11/2011
@author: jpstierlin
@change: 20/01/2012 ssavrimoutou
@change: 23/02/2012 apairex BZ2812
@change: 24/02/2012 jpstierlin BZ2803
@change: 13/03/2012 jpstierlin BZ2863
@change: 22/03/2012 apairex BZ2969
@change: 12/04/2012 apairex BZ2408
"""

import telnetlib
import time, re
import getopt
import sys
import traceback


def char2hexa(string):
    """
    Convert a string into a succession of hexadecimal values
    that corresponds to each char of the string
    """
    hexa = ""
    for c in string:
        hexa += "%02x" % ord(c)
    return hexa


# Logger class for unit tests
class Logger():

    def __init__(self):
        pass

    def debug(self, msg):
        print msg

    def info (self, msg):
        print msg

    def error(self, msg):
        print msg


class Cisco1250():
    """
    Implementation of Cisco1250 configurable AP
    """
    
    # Define list of global for the equipment
    WIFI_RADIOS = [0, 1]
    WIFI_WEP_KEYS = [0, 1, 2, 3]
    WIFI_CHANNELS_2G = ['least-congested','2412','2417','2422','2427','2432','2437','2442','2447','2452','2457','2462','2467','2472','2484']
    WIFI_CHANNELS_5G = ['least-congested','5180','5200','5220','5240','5260','5280','5300','5320','5745','5765','5785','5805','5825']
    WIFI_STANDARD_5G =  ['a', 'an', 'n5G']

    SUPPORTED_WIFI_STANDARD = ['a','b','g','n','an','bg','gb','bgn','ngb','n2.4G','n5G','off']
    SUPPORTED_WIFI_AUTHENTICATION = ['OPEN','WEP64','WEP128','WPA-PSK-TKIP','WPA2-PSK-AES','EAP-WPA','EAP-WPA2']
    
    def __init__(self):
        """
        Constructor
        """
        # Initialize class parent
        self.__handle = None
        
        self._ssids = []
        self._ssid = None
        self._wep_keys = [[None,None,None,None],[None,None,None,None]]
        self._standard = None
        self._logger = Logger()

    def __del__(self):
        """
        Destructor: releases all allocated resources.
        """
        self.release()

    def get_logger(self):
        """
        return the curent logger.
        """
        return self._logger

    def _connect_via_telnet(self, host, username, password):
        """
        connect Cisco1250 via telnet thus config the equipment
        
        @type host: string
        @param host: access point IP address
        
        @type username: string
        @param username: access point admin login
        
        @type password: string
        @param password: access point admin password
        
        @raise: EqIOException
        """
        self.get_logger().debug("Open telnet connection to equipment.")
        
        # Initialize telnet session
        telnet_session = telnetlib.Telnet()
        
        try:
            telnet_session.open(host)
            telnet_session.read_until("Username:", 5)
            telnet_session.write(str(username) + "\n")
            telnet_session.read_until("Password:", 5)
            telnet_session.write(str(password) + "\n")
            telnet_session.read_until(">", 5)
            telnet_session.write("enable\n")
            telnet_session.read_until("Password:", 5)
            telnet_session.write(str(password) + "\n")
            telnet_session.read_until("\n#", 5)
        except:
            msg = "Connection via telnet failed."
            raise Exception(-1, msg)
        
        try:
            # get running config
            telnet_session.write("terminal length 0\n")
            telnet_session.read_until("\n#", 5)
            telnet_session.write("show running-config\n")
            config_file = telnet_session.read_until("\n#", 10)

            # extract SSIDs
            config_file_lines = config_file.split('\r\n')
            for line in config_file_lines:
                match = "dot11 ssid "
                if line.startswith(match):
                    self._ssids.append(line[len(match):].strip())

            # extract wep keys
            for i in self.WIFI_RADIOS:
                found = None
                for line in config_file_lines:
                    if found == None:
                        match = "interface Dot11Radio" + str(i)
                        if line.startswith(match):
                            found = line
                    elif line.startswith(' '):
                        match = "encryption key "
                        if line.strip().startswith(match):
                            key_id = int(line.strip()[len(match):].strip().split(' ')[0])
                            self._wep_keys[i][key_id-1] = True
                    else:
                        break

            # extract wep keys

        except:
            msg = "Read configuration failed."
            raise Exception(-2, msg)

        # Update handle value
        self._set_handle(telnet_session)       
        
    def __disconnect_via_telnet(self):
        """
        disconnect equipment from telnet
        """
        self.get_logger().debug("Close telnet connection from the equipment.")
        if self.get_handle() != None:
            self.get_handle().close()
            self._set_handle(None)

    def _send_cmd(self, cmd, lines = 2, reply='#'):
        """
        Send command to the equipment
        
        @type cmd: string
        @param cmd: Command to send
        
        @type lines: integer
        @param lines: number of lines to read
        
        @type reply: string
        @param reply: reply string to trigger
        """
        #self.get_logger().debug("Send command %s" % str(cmd))
        
        self.get_handle().write(str(cmd) + "\n")
        ret = self.get_handle().read_until(reply, 5).strip().split('\r\n')
        if len(ret) == 0:
            raise Exception(-3, "Command timeout.")
        if len(ret) > lines:
            ret[0] = ' ' * len(ret[-1].strip()) + ret[0].strip()
            error_msg = "Command error: \n" + '\n'.join(ret[:-1])
            raise Exception(-4, error_msg)

    def get_handle(self):
        """
        Gets the connection handle
        @rtype: unsigned long
        @return: the handle of connection with the equipment, None if no
        equipment is connected
        """        
        return self.__handle

    def _set_handle(self, handle):
        """
        Sets the connection handle of the equipment
        """
        self.__handle = handle

    def _delete_ssids(self):
        """
        Delete all ssids from the Equipment
        """
        if len(self._ssids) != 0:
            for ssid in self._ssids:
                self._send_cmd("no dot11 ssid " + ssid)
            self._ssids = []

    def __delete_keys(self, radio):
        """
        Clear all security keys on the equipment
        
        @type radio : int
        @param radio : radio to use
        """
        i = int(radio)
        for k in self.WIFI_WEP_KEYS:
            if self._wep_keys[i][k] != None:
                self._send_cmd("no encryption key " + str(k+1))
                self._wep_keys[i][k] = None

    def _set_wifi_authentication_OPEN(self):
        """
        Set AP Encryption type: Open
        """
        self.get_logger().debug("Set wifi authentication to OPEN")
        
        for radio in self.WIFI_RADIOS:
            self._send_cmd("interface dot11radio " + str(radio))
            self._send_cmd("no encryption mode")
            self._send_cmd("exit") # exit interface
        self._send_cmd("dot11 ssid " + self._ssid)
        self._send_cmd("authentication open")
        self._send_cmd("exit") # exit dot11

    def _set_wifi_authentication_WEP64(self, passphrase):
        """
        Set AP Encryption type to WEP64
        
        @type passphrase: String
        @param passphrase: Passphrase used for the authentication        
        """
        self.get_logger().debug("Set wifi authentication to WEP 64 bits")

        # WEP64 uses a 40-bit key = 5 bytes
        if len(passphrase) == 5:
            # Then we should transform ascii chars into hexadecimal values
            passphrase = char2hexa(passphrase)
        elif not re.match("^[0-9a-fA-F]{10}$", passphrase) :
            msg = "WEP64 passphrase should be 5 chars or 10 hexadecimal " + \
                    "chars. Currently [%s]" % passphrase
            self._logger.error(msg)
            raise Exception(-5, msg)

        for radio in self.WIFI_RADIOS:
            self._send_cmd("interface dot11radio " + str(radio))
            self._send_cmd("no encryption mode ciphers")
            self._send_cmd("encryption mode wep mandatory")
            # Passphrase set AFTER "encryption mode wep mandatory" instruction
            self._send_cmd("encryption key 1 size 40bit 0 " + passphrase + \
                           " transmit-key")
            self._send_cmd("exit")
            
        self._send_cmd("dot11 ssid " + self._ssid)
        self._send_cmd("authentication shared")
        self._send_cmd("exit")
        
    def _set_wifi_authentication_WEP128(self, passphrase):
        """
        Set AP Encryption type to WEP128
        
        @type passphrase: String
        @param passphrase: Passphrase used for the authentication 
        """
        self.get_logger().debug("Set wifi authentication to WEP 128 bits")

        # WEP128 uses a 104-bit key = 13 bytes
        if len(passphrase) == 13:
            # Then we should transform ascii chars into hexadecimal values
            passphrase = char2hexa(passphrase)
        elif not re.match("^[0-9a-fA-F]{26}$", passphrase) :
            msg = "WEP128 passphrase should be 13 chars or 26 hexadecimal " + \
                    "chars. Currently [%s]" % passphrase
            self._logger.error(msg)
            raise Exception(-5, msg)

        for radio in self.WIFI_RADIOS:
            self._send_cmd("interface dot11radio " + str(radio))
            self._send_cmd("no encryption mode ciphers")
            self._send_cmd("encryption mode wep mandatory")
            # Passphrase set AFTER "encryption mode wep mandatory" instruction
            self._send_cmd("encryption key 1 size 128bit 0 " + passphrase + \
                           " transmit-key")
            self._send_cmd("exit")
            
        self._send_cmd("dot11 ssid " + self._ssid)
        self._send_cmd("authentication shared")
        self._send_cmd("exit")
        
    def _set_wifi_authentication_WPA_PSK_TKIP(self, passphrase):
        """
        Set AP Encryption type to WPA PSK TKIP
        
        @type passphrase: String
        @param passphrase: Passphrase used for the authentication 
        """
        self.get_logger().debug("Set wifi authentication to WPA PSK TKIP")
        
        # No radius server to set
        self._send_cmd("no aaa new-model")

        for radio in self.WIFI_RADIOS:
            self._send_cmd("interface dot11radio " + str(radio))
            self._send_cmd("encryption mode ciphers tkip")
            self._send_cmd("exit")
            
        self._send_cmd("dot11 ssid " + self._ssid)
        self._send_cmd("authentication open")
        self._send_cmd("authentication key-management wpa version 1")
        self._send_cmd("wpa-psk ascii 0 " + passphrase)
        self._send_cmd("exit")
        
    def _set_wifi_authentication_WPA2_PSK_AES(self, passphrase):
        """
        Set AP Encryption type to WPA2 PSK AES
        
        @type passphrase: String
        @param passphrase: Passphrase used for the authentication 
        """
        self.get_logger().debug("Set wifi authentication to WPA2 PSK AES")

        # No radius server to set
        self._send_cmd("no aaa new-model")

        for radio in self.WIFI_RADIOS:
            self._send_cmd("interface dot11radio " + str(radio))
            self._send_cmd("encryption mode ciphers aes-ccm")
            self._send_cmd("exit")
            
        self._send_cmd("dot11 ssid " + self._ssid)
        self._send_cmd("authentication open")
        self._send_cmd("authentication key-management wpa version 2")
        self._send_cmd("wpa-psk ascii 0 " + passphrase)
        self._send_cmd("exit")

    def init(self):
        """
        Initializes the equipment and establishes the connection.
        """
        self.get_logger().info("Initialization")

        if self.get_handle() is not None:
            return
        
        # Retrieve parameters from BenchConfig for connection
        host = str(self._bench_params.get_param_value("IP"))
        username = str(self._bench_params.get_param_value("username"))
        password = str(self._bench_params.get_param_value("password"))

        # Open telnet session
        self._connect_via_telnet(host, username, password)

    def release(self):
        """
        Release the equipment and all associated resources
        """
        self.get_logger().info("Release")
        
        self.__disconnect_via_telnet()

    def create_ssid(self, ssid):
        """
        Create ssid on the equipment
        
        @type ssid: string
        @param ssid: SSID to create
        """
        self.get_logger().info("Create ssid '%s'" % str(ssid))
        
        self._ssid = str(ssid)
        self._ssids.append(self._ssid)
        
        # Send commands to equipment
        self._send_cmd("dot11 ssid " + self._ssid)
        self._send_cmd("guest-mode")
        self._send_cmd("exit")

    def set_wifi_authentication(self, authentication_type, passphrase = "",
                                radiusip = None, radiusport = None,
                                radiussecret = None, \
                                standard_type = None):
        """
        Set the authentication on the equipment
        
        @type authentication_type: String
        @param authentication_type: Authentication supported by the equipment
        
        @type passphrase: String
        @param passphrase: Passphrase used for the authentication

        @type radiusip: string
        @param radius: Address of the radius server (optional)

        @type radiusport: string
        @param radius: port to connect to the radius server (optional)

        @type radiussecret: string
        @param radius: Password to communicate between AP and Radius server (optional)

        @type standard_type: string
        @param standard_type: The wifi standard used to determine if the \
                            channel has to be set for 2.4GHz or 5GHz
        """
        #self.get_logger().info("Set wifi authentication to '%s'" % str(authentication_type))
        
        # SSID should set before setting the authentication
        if self._ssid in (None, "None", ""):
            raise Exception(-5,
                "SSID should be set before setting wifi authentication.")

        if authentication_type == "OPEN":
            self._set_wifi_authentication_OPEN()
            
        elif authentication_type == "WEP64":
            self._set_wifi_authentication_WEP64(passphrase)
            
        elif authentication_type == "WEP128":
            self._set_wifi_authentication_WEP128(passphrase)
            
        elif authentication_type == "WPA-PSK-TKIP":
            self._set_wifi_authentication_WPA_PSK_TKIP(passphrase)
            
        elif authentication_type == "WPA2-PSK-AES":
            self._set_wifi_authentication_WPA2_PSK_AES(passphrase)
        
        else:
            raise Exception(-5,
                "Unsupported wifi authentication '%s'" % str(authentication_type))      
        
    def set_wifi_standard(self, standard):
        """
        Set wifi standard
        
        @type standard: String
        @param standard: Wifi standard to set
        """
        self.get_logger().info("Set wifi standard to '%s'" % str(standard))
        
        if standard == "a":
            self._send_cmd("interface dot11radio 0")
            self._send_cmd("shutdown")
            self._send_cmd("exit") # exit interface
            self._send_cmd("interface dot11radio 1")
            self._send_cmd("speed basic-6.0 basic-9.0 basic-12.0 basic-18.0 basic-24.0 basic-36.0 basic-48.0 basic-54.0")
            self._send_cmd("ssid " + self._ssid)
            self._send_cmd("no shutdown")
            self._send_cmd("antenna transmit diversity")
            self._send_cmd("antenna receive diversity")
            self._send_cmd("exit") # exit interface

        elif standard == "b":
            self._send_cmd("interface dot11radio 0")
            self._send_cmd("speed basic-1.0 basic-2.0 basic-5.5 basic-11.0")
            self._send_cmd("ssid " + self._ssid)
            self._send_cmd("no shutdown")
            self._send_cmd("antenna transmit diversity")
            self._send_cmd("antenna receive diversity")
            self._send_cmd("exit") # exit interface
            self._send_cmd("interface dot11radio 1")
            self._send_cmd("shutdown")
            self._send_cmd("exit") # exit interface

        elif standard == "g":
            self._send_cmd("interface dot11radio 0")
            self._send_cmd("speed 1.0 2.0 5.5 11.0 basic-6.0 basic-9.0 basic-12.0 basic-18.0 basic-24.0 basic-36.0 basic-48.0 basic-54.0")
            self._send_cmd("ssid " + self._ssid)
            self._send_cmd("no shutdown")
            self._send_cmd("antenna transmit diversity")
            self._send_cmd("antenna receive diversity")
            self._send_cmd("exit") # exit interface
            self._send_cmd("interface dot11radio 1")
            self._send_cmd("shutdown")
            self._send_cmd("exit") # exit interface

        elif standard == "gb" or standard == "bg":
            self._send_cmd("interface dot11radio 0")
            self._send_cmd("speed basic-1.0 basic-2.0 basic-5.5 basic-11.0 basic-6.0 basic-9.0 basic-12.0 basic-18.0 basic-24.0 basic-36.0 basic-48.0 basic-54.0")
            self._send_cmd("ssid " + self._ssid)
            self._send_cmd("no shutdown")
            self._send_cmd("antenna transmit diversity")
            self._send_cmd("antenna receive diversity")
            self._send_cmd("exit") # exit interface
            self._send_cmd("interface dot11radio 1")
            self._send_cmd("shutdown")
            self._send_cmd("exit") # exit interface

        elif standard == "ngb" or standard == "bgn":
            self._send_cmd("interface dot11radio 0")
            self._send_cmd("speed basic-1.0 basic-2.0 basic-5.5 basic-11.0 basic-6.0 basic-9.0 basic-12.0 basic-18.0 basic-24.0 basic-36.0 basic-48.0 basic-54.0 m0-7")
            self._send_cmd("ssid " + self._ssid)
            self._send_cmd("no shutdown")
            self._send_cmd("antenna transmit diversity")
            self._send_cmd("antenna receive diversity")
            self._send_cmd("exit") # exit interface
            self._send_cmd("interface dot11radio 1")
            self._send_cmd("shutdown")
            self._send_cmd("exit") # exit interface

        elif standard == "an":
            self._send_cmd("interface dot11radio 0")
            self._send_cmd("shutdown")
            self._send_cmd("exit") # exit interface
            self._send_cmd("interface dot11radio 1")
            self._send_cmd("speed basic-6.0 basic-9.0 basic-12.0 basic-18.0 basic-24.0 basic-36.0 basic-48.0 basic-54.0 m0. m1. m2. m3. m4. m5. m6. m7. m8. m9. m10. m11. m12. m13. m14. m15.")
            self._send_cmd("ssid " + self._ssid)
            self._send_cmd("no shutdown")
            self._send_cmd("antenna transmit diversity")
            self._send_cmd("antenna receive diversity")
            self._send_cmd("exit") # exit interface

        elif standard == "n2.4G" or standard == "n":
            self._send_cmd("interface dot11radio 0")
            self._send_cmd("speed basic-1.0 m0. m1. m2. m3. m4. m5. m6. m7. m8. m9. m10. m11. m12. m13. m14. m15.")
            self._send_cmd("ssid " + self._ssid)
            self._send_cmd("no shutdown")
            self._send_cmd("antenna transmit diversity")
            self._send_cmd("antenna receive diversity")
            self._send_cmd("exit") # exit interface
            self._send_cmd("interface dot11radio 1")
            self._send_cmd("shutdown")
            self._send_cmd("exit") # exit interface

        elif standard == "n5G":
            self._send_cmd("interface dot11radio 0")
            self._send_cmd("shutdown")
            self._send_cmd("exit") # exit interface
            self._send_cmd("interface dot11radio 1")
            self._send_cmd("speed basic-6.0 m0. m1. m2. m3. m4. m5. m6. m7. m8. m9. m10. m11. m12. m13. m14. m15.")
            self._send_cmd("ssid " + self._ssid)
            self._send_cmd("no shutdown")
            self._send_cmd("antenna transmit diversity")
            self._send_cmd("antenna receive diversity")
            self._send_cmd("exit") # exit interface

        elif standard == "off":
            self._send_cmd("interface dot11radio 0")
            self._send_cmd("shutdown")
            self._send_cmd("exit") # exit interface
            self._send_cmd("interface dot11radio 1")
            self._send_cmd("shutdown")
            self._send_cmd("exit") # exit interface

        else:
            raise Exception(-5,
                "Unsupported wifi standard '%s'." % str(standard))

        self._standard = standard
        
    def set_wifi_channel(self, standard, channel):
        """
        Set wifi channel
        
        @type standard: string
        @param standard: The wifi standard used to determine if the channel \
                         has to be set for 2.4GHz or 5GHz
        @type channel: integer
        @param channel: The wifi channel to set, 2.4GHz:1-14(0:auto), 5GHz:1-13(0:auto)
        """
        if standard not in self.WIFI_STANDARD_5G :
            self.get_logger().info("Set wifi 2.4GHz channel to '%s'" % str(channel))
    
            if int(channel) < len(self.WIFI_CHANNELS_2G):
                self._send_cmd("interface dot11radio 0")
                self._send_cmd("channel " + self.WIFI_CHANNELS_2G[int(channel)])
                self._send_cmd("exit")
            elif channel in self.WIFI_CHANNELS_2G:
                self._send_cmd("interface dot11radio 0")
                self._send_cmd("channel " + str(channel))
                self._send_cmd("exit")
            else:
                raise Exception(-5, \
                                    "channel is out of range.")
        
        else :
            self.get_logger().info("Set wifi 5GHz channel to '%s'" % str(channel))
    
            if int(channel) < len(self.WIFI_CHANNELS_5G):
		self._send_cmd("interface dot11radio 1")
                channel = self.WIFI_CHANNELS_5G[int(channel)]
                # cannot manually select DFS channels, use band
                if channel == '5240':
                    self._send_cmd("band 1")
                elif channel in ('5260','5280','5300','5320'):
                    self._send_cmd("band 2")
                else:
                    self._send_cmd("channel " + str(channel))
                self._send_cmd("exit")
            elif channel in self.WIFI_CHANNELS_5G:
                self._send_cmd("interface dot11radio 1")
                if str(channel) == '5240':
                    self._send_cmd("band 1")
                elif str(channel) in ('5260','5280','5300','5320'):
                    self._send_cmd("band 2")
                else:
                    self._send_cmd("channel " + str(channel))
                self._send_cmd("exit")
            else:
                raise Exception(-5, \
                                    "channel is out of range.")

    def set_wifi_dtim(self, dtim):
        """
        Set Wifi DTIM
        
        @type dtim: int
        @param dtim: 
        """
        self.get_logger().info("Set wifi DTIM to '%s'" % str(dtim))
        
        for radio in self.WIFI_RADIOS:
            self._send_cmd("interface dot11radio " + str(radio))
            self._send_cmd("beacon dtim-period " + str(dtim))
            self._send_cmd("exit")

    def set_wifi_wmm(self, mode):
        """
        Enable/Disable Wifi wireless Multimedia extensions
        
        @type mode: string or int
        @param mode: can be ('on', '1', 1) to enable
                            ('off', '0', 0) to disable
        """
        if mode in ("on", "1", 1):
            self._logger.info("Set wifi wmm to on")
            mode = 1
        elif mode in ("off", "0", 0):
            self._logger.info("Set wifi wmm to off")
            mode = 0
        else:
            raise Exception(-5,
                                 "Parameter mode is not valid !")
        for radio in self.WIFI_RADIOS:
            self._send_cmd("interface dot11radio " + str(radio))
            if mode == 0:
                self._send_cmd("no dot11 qos mode wmm")
            else:
                self._send_cmd("dot11 qos mode wmm")
            self._send_cmd("exit")

    def set_wifi_bandwidth(self, bandwidth):
        """
        Set wifi channel bandwidth

        @type bandwidth: integer
        @param bandwidth: The wifi bandwidth: 20 or 40MHz
        """
        if int(bandwidth) == 20:
            cmd = "channel width 20"
        elif int(bandwidth) == 40:
            cmd = "channel width 40-below"
        else:
            raise Exception(-5,
                "Unsupported wifi bandwidth '%s'." % str(bandwidth))
        for radio in self.WIFI_RADIOS:
            self._send_cmd("interface dot11radio " + str(radio))
            self._send_cmd(cmd)
            self._send_cmd("exit")

    def set_wifi_voip(self, voip):
        """
        Set wifi voip enabling

        @type voip: integer
        @param voip: on or off
        """
        if voip in ("on", "1", 1):
            self._logger.info("Set wifi voip to on")
            voip = 1
        elif voip in ("off", "0", 0):
            self._logger.info("Set wifi voip to off")
            voip = 0
        else:
            raise Exception(-5, "Parameter voip is not valid !")
        
        if voip != 0:
            self._send_cmd("class-map match-all _class_voip2")
            self._send_cmd( "match ip dscp default")
            self._send_cmd( "exit")
            self._send_cmd("class-map match-all _class_voip0")
            self._send_cmd( "match ip dscp cs6")
            self._send_cmd( "exit")
            self._send_cmd("class-map match-all _class_voip1")
            self._send_cmd( "match ip dscp cs7")
            self._send_cmd( "exit")

            self._send_cmd("policy-map voip")
            self._send_cmd( "class _class_voip0")
            self._send_cmd(  "set cos 6")
            self._send_cmd(  "exit")
            self._send_cmd( "class _class_voip1")
            self._send_cmd(  "set cos 7")
            self._send_cmd(  "exit")
            self._send_cmd( "class _class_voip2")
            self._send_cmd(  "set cos 6")
            self._send_cmd(  "exit")
            self._send_cmd( "exit")
            for radio in self.WIFI_RADIOS:
                self._send_cmd("interface dot11radio " + str(radio))
                self._send_cmd(" service-policy input voip")
                self._send_cmd(" service-policy output voip")
                self._send_cmd(" exit")
        else:
            self._send_cmd("no policy-map voip")
            self._send_cmd("no class-map match-all _class_voip2")
            self._send_cmd("no class-map match-all _class_voip0")
            self._send_cmd("no class-map match-all _class_voip1")


    def set_wifi_power(self, standard, wifi_power):
        """
        Set wifi transmit power in dBm

        @type standard: string
        @param standard: The wifi standard used to control the validity of \
                         the power value
        @type power: string or int
        @param power: wifi transmit power:
            2.4GHz: -1, 2, 5, 8, 11, 14, 17, 20, max
            5GHz:   -1, 2, 5, 8, 11, 14, 17, max
        """
        POWER_VALUES_2G = ["-1", "2", "5", "8", "11", "14", "17", "20", "max"]
        POWER_VALUES_5G = ["-1", "2", "5", "8", "11", "14", "17", "max"]
        
        # Control of the value to set
        if standard not in self.WIFI_STANDARD_5G \
                and str(wifi_power) not in POWER_VALUES_2G :
            raise Exception(-5, \
                "Unsupported wifi power value for 5GHz '%s'" % str(wifi_power))      
        elif standard in self.WIFI_STANDARD_5G \
                and str(wifi_power) not in POWER_VALUES_5G :
            raise Exception(-5, \
                "Unsupported wifi power value for 2.4GHz '%s'" \
                % str(wifi_power))

        # Set the power value
        cmd = 'power local ' + str(wifi_power)
        for radio in ('0','1'):
            self._send_cmd("interface dot11radio " + str(radio))
            self._send_cmd(cmd)
            self._send_cmd("exit") # exit interface

    def _is_supported_config(self, standard_type, authentication_type):
        """
        Check if standard and authentication type combination
        is supported by Equipment

        @type standard_type: string
        @param standard_type: wifi standard type
        
        @type authentication_type: string
        @param authentication_type: wifi authentication type
        
        @rtype: boolean
        @return: if supported or not        
        """
        if standard_type in ['n','n2.4G','n5G'] and authentication_type in \
          ['WEP64','WEP128','WPA-PSK-TKIP','EAP-WPA']:
            return False
        return True

    def set_wifi_config(self,
                        ssid,
                        standard_type,
                        authentication_type,
                        passphrase,
                        channel = None,
                        dtim = None,
                        wmm = None,
                        bandwidth = None,
                        voip = None,
                        radiusip = None,
                        radiusport = None,
                        radiussecret = None):
        """
        set wifi config, include standard and authentication
        
        @type ssid: string
        @param ssid: access point SSID
        
        @type standard_type: string
        @param standard_type: wifi standard type
        
        @type authentication_type: string
        @param authentication_type: wifi authentication type
        
        @type passphrase: string
        @param passphrase: wifi passphrase
        
        @type channel: integer
        @param channel: wifi channel number (optional)
        
        @type dtim: integer
        @param dtim: wifi DTIM interval (optional)

        @type wmm: integer
        @param wmm: Enable/Disable wifi wmm (optional)
                
        @type bandwidth: string
        @param bandwidth: bandwidth to use (optional)

        @type radiusip: string
        @param radius: Address of the radius server (optional)

        @type radiusport: string
        @param radius: port to connect to the radius server (optional)

        @type radiussecret: string
        @param radius: Password to communicate between AP and Radius server (optional)
        """
        self.get_logger().info("Set wifi configuration")
        
        # Extract time to wait for configuration of the equipment
        configuration_timer = 30
        
        # Check parameter values
        if standard_type not in self.SUPPORTED_WIFI_STANDARD:
            msg = "wifi standard type: %s not correct" % standard_type
            raise Exception(-5, msg)
        
        if authentication_type not in self.SUPPORTED_WIFI_AUTHENTICATION:
            msg = "wifi authentication type: %s not correct" % authentication_type
            raise Exception(-5, msg)
        
        if not self._is_supported_config(standard_type, authentication_type):
            msg = "wifi standard type: %s with authentication type: %s not supported" % (standard_type, authentication_type)
            raise Exception(-5, msg)

        self._send_cmd("configure terminal",3)
        try:

            # turn radios off and disable aironet extensions
            for radio in self.WIFI_RADIOS:
                self._send_cmd("interface dot11radio " + str(radio))
                self._send_cmd("shutdown")
                self.__delete_keys(radio)
                self._send_cmd("no dot11 extension aironet")
                self._send_cmd("exit") # exit interface

            # clear all existing ssids
            self._delete_ssids()
            # create specified ssid
            self.create_ssid(ssid)

            # Set the wifi authentication
            self.set_wifi_authentication(authentication_type, passphrase, \
                                         radiusip, radiusport, radiussecret, \
                                         standard_type)

            if channel != None:
                # Set the wifi channel if exists
                self.set_wifi_channel(standard_type, channel)
            if bandwidth != None:
                # Set the wifi bandwidth if exists
                self.set_wifi_bandwidth(bandwidth)
            if dtim != None:
                # Set the wifi dtim if exists
                self.set_wifi_dtim(dtim)
            if wmm != None:
                # Enable/disable the wifi wmm if exists
                self.set_wifi_wmm(wmm)
            if voip != None:
                # Enable/disable the wifi voip if exists
                self.set_wifi_voip(voip)

            # set_wifi_standard restarts the needed radios
            self.set_wifi_standard(standard_type)

        finally:
            self._send_cmd("end") # exit configure
        
        # Wait for configuration time end
        time.sleep(configuration_timer)

    def enable_wireless(self):
        """
        enable wireless
        """
        self.get_logger().info("Enable wireless")

        if self._standard == None :
            msg = "Cannot call enable_wireless() before calling " \
                  + "set_wifi_standard() method"
            self._logger.error(msg)
            raise Exception(-5, msg)

        self._send_cmd("configure terminal", 3)
        try:
            if self._standard in self.WIFI_STANDARD_5G :
                self._send_cmd("interface dot11radio " + \
                               str(self.WIFI_RADIOS[1]))
                self._send_cmd("no shutdown")
                self._send_cmd("exit")
            else :
                self._send_cmd("interface dot11radio " + \
                               str(self.WIFI_RADIOS[0]))
                self._send_cmd("no shutdown")
                self._send_cmd("exit")
        finally:
            self._send_cmd("end") # exit configure

    def disable_wireless(self):
        """
        disable wireless
        """
        self.get_logger().info("Disable wireless")

        if self._standard == None :
            msg = "Cannot call enable_wireless() before calling " \
                  + "set_wifi_standard() method"
            self._logger.error(msg)
            raise Exception(-6, msg)

        self._send_cmd("configure terminal", 3)
        try:
            if self._standard in self.WIFI_STANDARD_5G :
                self._send_cmd("interface dot11radio " + \
                               str(self.WIFI_RADIOS[1]))
                self._send_cmd("shutdown")
                self._send_cmd("exit")
            else :
                self._send_cmd("interface dot11radio " + \
                               str(self.WIFI_RADIOS[0]))
                self._send_cmd("shutdown")
                self._send_cmd("exit")
        finally:
            self._send_cmd("end") # exit configure


def usage():
    print sys.argv[0] + " [-a <ip_address>] [-l <login>] [-p <password>] [-f <Routerconfig.cfg>] [<parameter>=<value> ...]"
    print " available parameters:"
    print "  ssid=<SSID>"
    print "  std=<a|b|g|n|bg|bgn|an|n5G>"
    print "  auth=<OPEN|WEP64|WEP128|WPA-PSK-TKIP|WPA2-PSK-AES>"
    print "  pass=<passphrase>"
    print "  channel=<0-14>"
    print "  dtim=<0-10>"
    print "  wmm=<0|1>"
    print "  bandwidth=<20|40>"
    print "  voip=<0|1>"

# ./Cisco1250.py ssid=Cisco1252 standard=bgn auth=OPEN channel=1
# ./Cisco1250.py ssid=Cisco1252 standard=bgn auth=WPA2-PSK-AES pass=1234567890123 channel=1

def main():
    # default values
    hostName = '192.168.1.6'
    userName = 'Cisco'
    password = 'Cisco'
    fileName = None

    # extract command line parameters
    try:
        opts, args = getopt.getopt(sys.argv[1:], "ha:l:p:f:", ["help", "address=", "login=", "password=", "filename="])
    except getopt.GetoptError, err:
        print str(err)
        usage()
        sys.exit(2)

    for o, a in opts:
        if o in ("-h", "--help"):
            usage()
            sys.exit()
        elif o in ("-a", "--address"):
            hostName = a
        elif o in ("-l", "--login"):
            userName = a
        elif o in ("-p", "--password"):
            password = a
        elif o in ("-f", "--filename"):
            fileName = a
        else:
            assert False, "unhandled option"

    ssid = 'pmbot-1252'
    standard = 'bgn' # 'a','b','g','n','an','bg','gb','bgn','ngb','n2.4G','n5G','off'
    auth = 'OPEN' # WEP64, WEP128, WPA-PSK-TKIP, WPA2-PSK-AES
    passphrase = ''
    channel = 1
    dtim = 3
    wmm = 1
    bandwidth = 20
    voip = 0

    for a in args:
        p = a.split('=')
        p[1] = p[1].replace('"', '').strip()
        if p[0] == 'ssid': ssid = p[1]
        elif p[0] == 'std' or p[0] == 'standard': standard = p[1]
        elif p[0] == 'auth': auth = p[1]
        elif p[0] == 'pass' or p[0] == 'passphrase': passphrase = p[1]
        elif p[0] == 'channel': channel = p[1]
        elif p[0] == 'dtim': dtim = p[1]
        elif p[0] == 'wmm': wmm = p[1]
        elif p[0] == 'bandwidth': bandwidth = p[1]
        elif p[0] == 'voip': voip = p[1]
        else: raise Exception(-6, "Unknown parameter %s" % p[0])

    ret = 1
    try:
        ap = Cisco1250()
        # Open telnet session
        ap._connect_via_telnet(hostName, userName, password)
        ap.set_wifi_config(ssid,
                            standard,
                            auth,
                            passphrase,
                            channel,
                            dtim,
                            wmm,
                            bandwidth,
                            voip,
                            radiusip = "192.168.0.150",
                            radiusport = "1812",
                            radiussecret = "RadiusPass")
        ret = 0
    except:
        print "### error: {0} {1} {2}".format(sys.exc_info()[0], sys.exc_info()[1], traceback.print_tb(sys.exc_info()[2]))
    sys.exit(ret)


if __name__ == "__main__":
    main()

