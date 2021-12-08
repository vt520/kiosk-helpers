# kiosk-helpers 
> A very quick overview of the the sdios install system

## Basic Architecture
1. The Reflector Server (covered elsewhere)
    * At it's most basic, a Unix like service, running an OpenSSH server and nginx.

    * The Reflector is primarily responsible for routing the incoming api requests to the correct kiosk without needing direct access to that kiosk.

2. The **sdios** Installer
    * The installer [bootstrap.sh](bootstrap.sh) fetches the latest zip package of the kiosk-helpers repository, unpacks it, and transfers control to [setup/install](setup/install)
    * [setup/install](setup/install) upgrades the extracted zip into a git repository, and optionally updates the sources to the current version.
    * [setup/postgit](setup/postgit) processes the rest of the installation steps
    
3. The **sdios** Software
    * **sdios** is a modular set of scripts designed for single application kiosk uses where handling sensitive documents is a priority.
    * There are three primary operating modes
        * Virtualized: **sdios** builds a custom virtualized domain for every user serssion.  Presents a desktop view of the domain.
        * Native: **sdios** presents a native Linux applications inside of a read-only (non-persistent) environment.
        * Hybrid: Using remoteapp, seamlessly blends together a Windows Embedded virtual machine with Linux client applications for 100% assurance of zero PII retention on the client machine.

