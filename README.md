# Security hardened OpenBSD templates

## Beta

This project is currently in beta phase. Expect bugs, problems, etc. Lots of things still need a lot of love. We invite everyone to test, audit and improve the project.

## Background

Security hardened [OpenBSD](https://www.openbsd.org) templates with complete firewall and [Tor](https://www.torproject.org) configurations. They are specifically designed for environments which require a high degree of security, privacy and anonymity. This makes them a good fit for crypto currency environments.

## Template overview

The following OpenBSD templates are currently available:
- Basic firewall with nat
- Tor gateway with socks support
- Tor gateway with transparent torification
- Tor gateway with socks and transparent torification
- Tor with socks support for single network card systems
- Tor with transparent torification for single network card systems
- Tor with socks and transparent torification for single network card systems

All templates will:
- Configure the PF firewall with pretty strict rules. Example: block all traffic destined to RFC1918 addresses.
- Set OpenBSD to the highest securelevel. This can prevent changes to the firewall configuration even when the root account is compromised.
- Setup most filesystems in read-only mode
- Setup the remaining filesystems with the memory filesystem (MFS) for files and folders that need write access. This information is stored in RAM and will be cleared on reboot.
- Set immutable flags on most files on the system
- Set random mac addresses
- Disable SSH and NTP by default

The Tor templates provide:
- A simple way to setup Tor .onion services, including 'stealth' and 'next generation v3' onion services
- A simple way to setup authorization data for remote stealth onion services

Our plan is to extend the list of security hardened templates with [Monero](https://getmonero.org), [Bitcoin](https://www.bitcoin.org) and [Kovri/I2P](https://getkovri.org). We are exploring other applications as well and are open for suggestions.

## Instructions for automated custom OpenBSD iso generation

The instructions are tailored for a Debian/Tails like system. For security reasons we highly recommend to use [Tails](https://tails.boum.org) to generate the custom OpenBSD isos.

Select one of the templates and rename it to install.site.

Copy install.site to the same directory as the '*custom-openbsd-iso.sh*' script.

*Optional*: Make some changes to install.site, example: edit the firewall or configure some Tor .onion services.

Run the custom-openbsd-iso.sh script:

    ./custom-openbsd-iso.sh

The script should produce a custom OpenBSD iso.

Burn the iso to a CD/DVD.

## Custom OpenBSD installation instructions

This is a mini version of our installation instructions. See our [website](https://garlicgambit.wordpress.com) for the full instructions.

Boot the custom OpenBSD iso and follow the standard [OpenBSD](https://www.openbsd.org) installation procedure. Use the network configuration from install.site to configure the network. A '*Gateway*' will use ip address 172.16.1.1 with netmask 255.255.255.0 for the internal interface by default.

Once you get to the following line you need to type '`E`' to edit the auto layout and delete the swap partition:
'*Use (A)uto layout, (E)dit auto layout, or create (C)ustom layout.*'

Below the line starting with '*Label editor*' you need to type the following sequence to delete the swap partition:

    d b
    w
    q

When you get to '*Set name(s)*' you need to select '*siteXX.tgz*' and de-select all sets starting with '*x*, '*games*' and '*comp*'

Select the siteXX.tgz set:

    +s*

De-select the x, game and comp sets:

    -x*
    -g*
    -c*

The checksum and verification test for siteXX.tgz will fail. This is expected behavior. Type '`yes`' to continue the installation.

When you see "*CONGRATULATIONS*" you can reboot the system.

Upon first boot the custom installation will run a script once that will automatically reboot the system. After this is done you will see the login prompt and your system is ready for use.

## TODO

- [ ] Add Monero P2P daemon, RPC service and wallet support
- [ ] Add Kovri/I2P support
- [ ] Improve installation process
- [ ] Improve templates and scripts
- [ ] Improve documentation
- [ ] Explore methods to securely set system time
- [ ] Explore methods to create an OpenBSD iso from the 'stable' branch
- [ ] Add Tor controlport (filter) support
- [ ] Add automatic download of non-free firmware drivers
- [ ] Improve Tails support
- [ ] Add Whonix support
- [ ] Add Qubes support
- [ ] Add (offline) QR code signing support
- [ ] Add hardware recommendations
- [ ] Add hardware wallet support
- [ ] Add USB boot support
- [ ] Add ARM architecture support
- [ ] Add live cd option
- [ ] Add templates for other operating systems
- [ ] Explore layer 2 filtering
- [ ] Explore virtualization technologies (VMM) to compartmentalize services
- [ ] Explore and promote (reproducible) Monero and Kovri packages for OpenBSD and other operating systems
- [ ] Explore and promote the integration of OpenBSD's pledge in Monero, Kovri, Tor and other applications

## License

MIT

## Website and contact

Website: [garlicgambit.wordpress.com](https://garlicgambit.wordpress.com)

## Donations

Support this project by donating to:

**Bitcoin:**
    1Ndk6vc9PST9aCHiyd8R2PAXZ68HxeKSgn

**Monero:**
    463DQj1ebHSWrsyuFTfHSTDaACx3WZtmMFMwb6QEX7asGyUBaRe2fHbhMchpZnaQ6XKXcHZLq8Vt1BRSLpbqdr283QinCRK
