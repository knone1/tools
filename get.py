#!/usr/bin/python

import getopt
import sys
import wget
import os.path
import subprocess
import string
import shutil

##############################################################################
# you should defenetly edit these:
PKG_ID = "TEGRA_E14254A"
BUILD_SCRIPT = "/home/mmes/tools/build.sh"
BUILD_DIR = "/home/mmes/build"
SUDOPASS = "axelh"

# not so much these:
PKG_VER = "ubuntu-bins-pu1114"
BASE_DIR = "/home/mmes/get"

#not at all these:
URL1 = "https://ftpbin:Reply.2@itpsmgit1.magnetimarelli.com/ftpbin/outgoing/"
#
# WARNING! The order of this list is important, pkgs have dependencies
# on each other and need to be installed and removed in the right order.
#
PKG0 = [URL1, PKG_VER, "/pool/windriver/a/", "arm-linux-kernel-entrynav"]
PKG1 = [URL1, PKG_VER, "/pool/windriver/a/", "arm-rootfs-entrynav"]
PKG2 = [URL1, PKG_VER, "/pool/windriver/a/", "arm-sysroot-entrynav"]
PKG3 = [URL1, PKG_VER, "/pool/windriver/e/", "entrynav"]
PKG4 = [URL1, PKG_VER, "/pool/windriver/e/", "entrynav-layers"]
PKG5 = [URL1, PKG_VER, "/pool/windriver/m/", "mmbp"]
PKG6 = [URL1, PKG_VER, "/pool/windriver/a/", "arm-toolchain-mmbp"]
PKG7 = [URL1, PKG_VER, "/pool/windriver/a/", "arm-host-tools-mmbp"]
PKG8 = [URL1, PKG_VER, "/pool/windriver/w/", "wrlinux-mmbp"]

LIST = [PKG0, PKG1,PKG2, PKG3, PKG4, PKG5, PKG6, PKG7, PKG8]
#LIST = [PKG0]

FORCE = False
DEBUG = False

# the id of these pkgs is *not* the same as the release id
##############################################################################
def is_file_present(file_path):
	return os.path.isfile(file_path)

def pr_err(string):
	print string

def pr_dbg(string):
	if (DEBUG == True):
		print string
##############################################################################
def prep_env():
	dir_ok = os.path.exists(BASE_DIR)
	if dir_ok == False:
		os.mkdir(BASE_DIR)

	dir_ok = os.path.exists(BUILD_DIR)
	if dir_ok == False:
		os.mkdir(BUILD_DIR)

	dir_ok = is_file_present(BUILD_SCRIPT)
	if dir_ok == False:
		print "No build script. Fail."
		sys.exit(2)


def get_version(input_string):
		#use entrynav-layers pkg to figure out dependencies.
		#p = subprocess.Popen(["apt-cache", "show", "entrynav-layers"], stdout=subprocess.PIPE)
		ref_pkg = BASE_DIR +"/"+ "entrynav-layers" + "-" + PKG_ID + ".deb"
		file_ok = is_file_present(ref_pkg)
		if file_ok == False:
			pr_err("Reference packege not found!" + ref_pkg)
			sys.exit(2)

		p = subprocess.Popen(["dpkg", "-I", ref_pkg], stdout=subprocess.PIPE)
		out, err = p.communicate()
		lines = string.split(out, "\n")
		i = 0
		for l in lines:
			if ("Depends: " in l):
				version_string = lines[i]
				break
			i += 1

		words = string.split(version_string, " ")
		version = PKG_ID
		i = 0
		for w in words:
			if (input_string == w):
				version = words[i + 2]
				# remove crappy characters
				version = version.translate(None, '),')
				break
			i += 1
		pr_err(input_string +" = "+version)
		return version

def download():
	pr_err("Downloading pkgs...")
	for PKG in LIST:
		#example pkg name: "mmbp-TEGRA_E14195A.deb"
		file_name = PKG[3] + "-" + get_version(PKG[3]) + ".deb"
		dest_file_name = BASE_DIR + "/" + file_name

		# HACK - some stupid guy messed up the pkg name
		if (file_name == "mmbp-TEGRA_E14195A.deb"):
			file_name = "mmbp_TEGRA_E14195A.deb"

		url = PKG[0] + PKG[1] + PKG[2] + file_name
		pr_err(url)
		pr_err(dest_file_name)

		if (is_file_present(dest_file_name) == False):
			wget.download(url)
			os.rename(file_name, dest_file_name)
		else:
			if (FORCE == True):
				os.remove(dest_file_name)
				wget.download(url)
				os.rename(file_name, dest_file_name)
			else:
				pr_err("File exists, not downloading")

def install():
	pr_err("Checking if all pkg's are present:")
	for PKG in reversed(LIST):
		file_name = BASE_DIR + "/" + PKG[3] + "-" + get_version(PKG[3]) + ".deb"
		if is_file_present(file_name) == True:
			print file_name + " is Present"
		else:
			print file_name + " Not Found!"
			sys.exit()

	pr_err("Installing pkg's:")
	for PKG in reversed(LIST):
		file_name = BASE_DIR + "/" + PKG[3] + "-" + get_version(PKG[3]) + ".deb"
		os.system("echo "+SUDOPASS+" | sudo -S echo")
		os.system("sudo dpkg -i " + file_name)
def remove():
	pr_err("Removing pkg's:")
	for PKG in LIST:
		file_name = PKG[3]
		#trick to get sudo
		os.system("echo "+SUDOPASS+" | sudo -S echo")
		os.system("sudo dpkg -r " + file_name)


def build():
	pr_err("Building...")
	if (FORCE == True):
		print "Cleaning old build..."
		shutil.rmtree(BUILD_DIR)
		os.mkdir(BUILD_DIR)
		shutil.copyfile(BUILD_SCRIPT, BUILD_DIR + "/build.sh")
		os.chmod(BUILD_DIR, 0777)
		os.chmod(BUILD_DIR + "/build.sh", 0777)
		os.chdir(BUILD_DIR)
		os.system("./build.sh")
	os.chdir(BUILD_DIR)
	os.system("make all")

def usage():
	print "Usage is: \n\
		-h show help \n\
		-d download \n\
		-i install \n\
		-r remove \n\
		-b build \n\
		-v debug \n\
		-f force \n\
		--i-feel-lucky = download, remove, install, build \n\
		"

def main():

	# extract command line parameters
	try:
		opts, args = getopt.getopt(sys.argv[1:], "hdigfrvbx", ["help", "i-feel-lucky"])
	except getopt.GetoptError, err:
		print str(err)
		usage()
		sys.exit(2)

	# first set global flags
	for o, a in opts:
		if o in ("-f"):
			global FORCE 
			FORCE = True
		if o in ("-v"):
			global DEBUG 
			DEBUG = True

	prep_env()
	# now run actions
	for o, a in opts:
		if o in ("-h", "--help"):
			usage()
			sys.exit()
		if o in ("-d"):
			download()
		if o in ("-i"):
			install()
		if o in ("-r"):
			remove()
		if o in ("-b"):
			build()
		if o == "--i-feel-lucky":
			download()
			remove()
			install()
			build()
		if o in ("-x"):
			get_version("mmbp")
main()
