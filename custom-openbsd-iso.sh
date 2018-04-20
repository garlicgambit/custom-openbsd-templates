#!/bin/sh
#
# Quick and dirty script to create custom OpenBSD isos
#
# License: MIT
# https://garlicgambit.wordpress.com

set -u
set -e
#set -x

# Variables
system_architecture="amd64" # Use amd64 or i386
openbsd_release="snapshots" # Use snapshots or a version number, example: 6.2
template_file="install.site"
current_date=$(date +%F)
custom_iso_dir="/tmp/openbsd/${openbsd_release}/${system_architecture}/"
custom_iso_dir_extracted="${custom_iso_dir}custom-iso-${current_date}/" # This folder will be deleted
custom_iso_filename="custom-openbsd-${openbsd_release}-${system_architecture}-${current_date}.iso"
openbsd_homepage="https://www.openbsd.org/"
openbsd_mirror_file="ftp.html"

# Optional: Tor onion service variables
onion_service_import="false" # Set to true to import existing onion service backups
onion_service_create="false" # Set to true to generate onion service files on this system
onion_service_dir="hidden_service" # Base name of the onion services
onion_service_type="stealth" # Use: normal, stealth or nextgen
onion_service_stealth_clients="client1,client2,client3" # Number of clients
internal_server="172.16.1.2" # An optional server

# A list of onion services that will be generated on this system and
# copied to the OpenBSD system. This is useful if you want to have an
# external copy of the onion service files.
# Tor will only use the externally generated onion service files if
# you also enable the onion service in the Tor configuration in
# install.site. The name and configuration need to match.
# There is little harm in generating a couple of extra onion services
# as long as you don't enable them in the Tor configuration.
# Tip: Use the same naming scheme as install.site
onion_service_name="${onion_service_dir} \
                    ${onion_service_dir}_www \
                    ${onion_service_dir}_ssh_${internal_server} \
                    ${onion_service_dir}_www_${internal_server} \
                    ${onion_service_dir}_btc_p2p_${internal_server} \
                    ${onion_service_dir}_btc_rpc_${internal_server} \
                    ${onion_service_dir}_xmr_p2p_${internal_server} \
                    ${onion_service_dir}_xmr_rpc_${internal_server}"


# Don't run as root
if [ $(id -u) = '0' ]; then
  echo "ERROR: Don't run this script as root."
  echo "Please fix this and run the script again."
  exit 1
fi

# Don't run the script from the Tor Browser directory
pwd_dir="$(pwd)"
if [ "${pwd_dir}" = '/home/amnesia/Tor Browser' ]; then
  echo "ERROR: Don't run this script from the ${pwd_dir} directory."
  echo "Please fix this and run the script again."
  exit 1
fi

# Set a correct onion service type
if [ ! "${onion_service_type}" = "normal" ] &&
   [ ! "${onion_service_type}" = "stealth" ] &&
   [ ! "${onion_service_type}" = "nextgen" ]; then
  echo "ERROR: ${onion_service_type} is not a valid onion service type."
  echo "Please fix this and run the script again."
  exit 1
fi

# Check for the template configuration file and make it executable
if [ -s "${template_file}" ]; then
   chmod 0700 "${template_file}"
else
  echo "ERROR: Template file ${template_file} is missing or empty."
  echo "Please create and configure this file before you run the script."
  exit 1
fi

# Cleanup old extracted iso files
if [ -d "${custom_iso_dir_extracted}" ]; then
  rm -rf "${custom_iso_dir_extracted}"
fi

# Create the custom iso directory
if [ ! -d "${custom_iso_dir_extracted}" ]; then
  mkdir -p "${custom_iso_dir_extracted}"
fi

# Set permissions on the custom iso directory
if [ ! -d "${custom_iso_dir}" ]; then
  echo "ERROR: No ${custom_iso_dir} available."
  echo "Please diagnose the problem and run the script again."
  exit 1
else
  chmod 0700 "${custom_iso_dir}"
fi

# Copy template file to the custom iso directory
if ! cp "${template_file}" "${custom_iso_dir}"; then
  echo "ERROR: Failed to copy ${template_file} to the ${custom_iso_dir} directory."
  echo "Please diagnose the problem and run the script again."
  exit 1
fi

# Check if existing onion service backups need to be imported
if "${onion_service_import}"; then
  if [ -d "${onion_service_dir}" ]; then
    cp -r "${onion_service_dir}"* "${custom_iso_dir}"
  else
    echo "ERROR: Onion service backup import is enabled,"
    echo "but no onion service backup is found with the name: ${onion_service_dir}"
    echo "Please fix this and run the script again."
    exit 1
  fi
fi

# Copy firmware directory
if [ -d firmware ]; then
  cp -r firmware "${custom_iso_dir}"
fi

# Go to the custom iso directory
if ! cd "${custom_iso_dir}"; then
  echo "ERROR: Failed to go to the ${custom_iso_dir} directory."
  echo "Please diagnose the problem and run the script again."
  exit 1
fi

# Download the OpenBSD mirror list
if ! wget -O "${openbsd_mirror_file}" "${openbsd_homepage}""${openbsd_mirror_file}"; then
  echo "ERROR: Failed to download OpenBSD mirror list."
  echo "Please check your network settings and run the script again."
  exit 1
fi

# Select a random https mirror
random_mirror() {
  grep -o -P '<a href="https://([a-z0-9-]{1,63}\.)+[a-z]{2,63}/pub/OpenBSD/"' "${openbsd_mirror_file}" |
  sed 's#/pub/OpenBSD/"##' |
  sed 's#<a href="https://##' |
  shuf -n 1
}

# Check output random_mirror
if [ -z $(random_mirror) ]; then
  echo "ERROR: Failed to obtain hostname from the mirror list."
  echo "Please diagnose the problem and run the script again."
  exit 1
fi

# Download index.txt from the iso directory and store it as index-iso.txt
if ! wget -O index-iso.txt https://$(random_mirror)/pub/OpenBSD/"${openbsd_release}"/"${system_architecture}"/index.txt; then
  echo "ERROR: Failed to download index.txt of the iso directory."
  echo "Please diagnose the problem and run the script again."
  exit 1
fi

# Obtain the filename of the install iso
iso_filename=$(grep -o 'install[0-9]\{2\}\.iso' index-iso.txt)

# Check output iso_filename
if [ -z "${iso_filename}" ]; then
  echo "ERROR: No valid install iso filename."
  echo "Please diagnose the problem and run the script again."
  exit 1
fi

# Obtain the version number of the install iso
iso_version=$( echo -n "${iso_filename}" |
               sed 's/^install//' |
               sed 's/.iso$//')

# Check output iso_version
if [ -z "${iso_version}" ]; then
  echo "ERROR: No valid iso version number."
  echo "Please diagnose the problem and run the script again."
  exit 1
fi

# Obtain the version number with dot of the install iso
iso_version_dot=$( echo -n "${iso_version}" |
                   sed "s/^[0-9]/&./")

# Check output iso_version_dot
if [ -z "${iso_version_dot}" ]; then
  echo "ERROR: No valid iso version number."
  echo "Please diagnose the problem and run the script again."
  exit 1
fi

# Download checksum files
for i in SHA256 SHA256.sig; do
  if ! wget -O $i https://$(random_mirror)/pub/OpenBSD/"${openbsd_release}"/"${system_architecture}"/$i; then
    echo "ERROR: Failed to download $i."
    echo "Please diagnose the problem and run the script again."
    exit 1
  fi
done

# Download and/or verify checkum of the iso
if [ -f "${iso_filename}" ]; then
  if ! sha256sum --quiet --ignore-missing -c SHA256; then
    if ! wget -O "${iso_filename}" https://$(random_mirror)/pub/OpenBSD/"${openbsd_release}"/"${system_architecture}"/"${iso_filename}"; then
      echo "ERROR: Failed to download ${iso_filename}."
      echo "Please diagnose the problem and run the script again."
      exit 1
    else
      if ! sha256sum --quiet --ignore-missing -c SHA256; then
        echo "ERROR: The checksum of the iso files has failed."
        echo "Please diagnose the problem and run the script again."
        exit 1
      fi
    fi
  fi
else
  if ! wget -O "${iso_filename}" https://$(random_mirror)/pub/OpenBSD/"${openbsd_release}"/"${system_architecture}"/"${iso_filename}"; then
    echo "ERROR: Failed to download ${iso_filename}."
    echo "Please diagnose the problem and run the script again."
    exit 1
  else
    if ! sha256sum --quiet --ignore-missing -c SHA256; then
      echo "ERROR: The checksum of the iso files has failed."
      echo "Please diagnose the problem and run the script again."
      exit 1
    fi
  fi
fi

# Download index.txt from the packages directory
if ! wget -O index-packages.txt https://$(random_mirror)/pub/OpenBSD/"${openbsd_release}"/packages/"${system_architecture}"/index.txt; then
  echo "ERROR: Failed to download index.txt of the packages directory."
  echo "Please diagnose the problem and run the script again."
  exit 1
fi

# Obtain the filename of the tor package
tor_package=$( grep -o ' tor-[0-9]\.[0-9]\.[0-9]\.[0-9p]\{1,\}\.tgz' index-packages.txt |
               sed 's/ //')

# Check output tor_package
if [ $( echo -n "${tor_package}" | grep -c 'tor-') -ne 1 ]; then
  echo "ERROR: Invalid filename for the Tor package."
  echo "Please diagnose the problem and run the script again."
  exit 1
fi

# Obtain the filename of the libevent package
libevent_package=$( grep -o ' libevent-[0-9]\.[0-9]\.[0-9p]\{1,\}\.tgz' index-packages.txt |
                    sed 's/ //')

# Check output libevent_package
if [ $( echo -n "${libevent_package}" | grep -c 'libevent-') -ne 1 ]; then
  echo "ERROR: Invalid filename for the libevent package."
  echo "Please diagnose the problem and run the script again."
  exit 1
fi

# Download SHA256 file of the packages
if ! wget -O SHA256-packages https://$(random_mirror)/pub/OpenBSD/"${openbsd_release}"/packages/"${system_architecture}"/SHA256; then
  echo "ERROR: Failed to download SHA256 of the packages."
  echo "Please diagnose the problem and run the script again."
  exit 1
fi

# Download package files
for i in "${tor_package}" "${libevent_package}"; do
  if ! wget -O $i https://$(random_mirror)/pub/OpenBSD/"${openbsd_release}"/packages/"${system_architecture}"/$i; then
    echo "ERROR: Failed to download $i."
    echo "Please diagnose the problem and run the script again."
    exit 1
  fi
done

# Verify checksum of the packages. SHA256sum-packages is base64.
for i in "${tor_package}" "${libevent_package}"; do
  if ! openssl sha256 -binary $i |
       openssl base64 |
       grep -q -f - SHA256-packages; then
    echo "ERROR: The checksum of the $i package has failed."
    echo "Please diagnose the problem and run the script again."
    exit 1
  fi
done

# Create directory for non-free firmware drivers
if [ ! -d firmware ]; then
  mkdir firmware
fi

# TODO: Download non-free firmware drivers

# TODO: Verify checksum of non-free firmware drivers

# Inform about option to disconnect from the network
echo
echo "###########################################################"
echo "### All the files are stored on the local system.       ###"
echo "### You may now disconnect your system from the network ###"
echo "###########################################################"
echo

# Wait for 15 seconds
sleep 15

# Extract the install iso
if ! bsdtar -C "${custom_iso_dir_extracted}" -xf "${iso_filename}"; then
  echo "ERROR: Failed to extract ${iso_filename} to ${custom_iso_dir_extracted}"
  echo "Please diagnose the problem and run the script again."
  exit 1
fi

# Create cryptographic seeds
for i in 1 2; do
  echo "Creating cryptographic seed $i. This may take a while."
  echo "Move your mouse to generate extra entropy."
  dd if=/dev/random of=custom-random.seed$i bs=65536 count=1 iflag=fullblock status=none
  sleep 15
done

# Generate Tor .onion service files on this system
if "${onion_service_create}"; then
  pkill -u $(id -u) ^tor$ || true
  sleep 5
  for i in ${onion_service_name}; do
    if [ -d $i ]; then
      echo "Will not generate onion service $i. Directory already exists."
      echo
    else
      if [ "${onion_service_type}" = "normal" ]; then
        tor --hiddenservicedir $i \
            --hiddenserviceport 80 \
            --disablenetwork 1 \
            --ignore-missing-torrc \
            -f emptyfile \
            --quiet &
        echo "Generating normal onion service: $i"
      elif [ "${onion_service_type}" = "stealth" ]; then
        tor --hiddenservicedir $i \
            --hiddenserviceport 80 \
            --hiddenserviceauthorizeclient "stealth ${onion_service_stealth_clients}" \
            --disablenetwork 1 \
            --ignore-missing-torrc \
            -f emptyfile \
            --quiet &
        echo "Generating stealth onion service: $i"
      elif [ "${onion_service_type}" = "nextgen" ]; then
        tor --hiddenservicedir $i \
            --hiddenserviceport 80 \
            --hiddenserviceversion 3 \
            --disablenetwork 1 \
            --ignore-missing-torrc \
            -f emptyfile \
            --quiet &
        echo "Generating next generation v3 onion service: $i"
      fi
    sleep 10
    pkill -u $(id -u) ^tor$
    fi
  done
fi

# Create siteXX.tgz archive for the custom iso
if [ -d "${onion_service_dir}" ] &&
        "${onion_service_import}" ||
        "${onion_service_create}"; then
  tar -zcf site"${iso_version}".tgz "${onion_service_dir}"* "${template_file}" "${tor_package}" "${libevent_package}" custom-random.seed1 custom-random.seed2 firmware
  echo
  echo "The following Tor onion service directories are added to site${iso_version}.tgz:"
  ls -1 -d "${onion_service_dir}"*
  echo
else
  tar -zcf site"${iso_version}".tgz "${template_file}" "${tor_package}" "${libevent_package}" custom-random.seed1 custom-random.seed2 firmware
fi

# Copy siteXX.tgz and SHA256.sig to the custom iso directory
if ! cp site"${iso_version}".tgz SHA256.sig "${custom_iso_dir_extracted}""${iso_version_dot}"/"${system_architecture}"/; then
  echo "ERROR: Failed to copy files."
  echo "Please diagnose the problem and run the script again."
  exit 1
fi

# Generate the custom OpenBSD iso image
if ! genisoimage -b "${iso_version_dot}"/"${system_architecture}"/cdbr -r -no-emul-boot -c boot.catalog -o "${custom_iso_dir}""${custom_iso_filename}" "${custom_iso_dir_extracted}"; then
  echo "ERROR: Failed to generate a custom OpenBSD iso."
  echo "Please diagnose the problem and run the script again."
  exit 1
fi

# Generate sha256sum file
sha256sum "${custom_iso_filename}" > "${custom_iso_filename}".sha256sum.txt

# Inform the user that the script is finished
echo
echo "Congratulations! Your custom OpenBSD iso image is ready."
echo
echo "The iso and other files are available at:"
echo "${custom_iso_dir}"
echo
echo "OpenBSD iso filename:"
echo "${custom_iso_filename}"
echo
echo "You can burn it to a CD/DVD with Brasero."
