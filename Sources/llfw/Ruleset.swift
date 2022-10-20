//
//  Ruleset.swift
//

/*
 Ports filtered
 22/tcp: ssh
 3283/tcp: Apple Remote Desktop
 3283/udp: Apple Remote Desktop
 5900/tcp: Apple Remote Desktop/VNC
*/

let anchorFile = "/etc/pf.anchors/edu.umich.pf.rules"

fileprivate let ruleset = """
# This file is automatically created by llfw
###############################################################

# Allow internal addresses to get to ssh and apple remote desktop.
incoming_services_tcp = "{ 22, 3283, 5900 }"
incoming_services_udp = "{ 3283 }"

# Networks allowed for access
allowed_networks = "{ 192.168.0.0/24 }"

# localhost allow
set skip on lo0

# Normalization
# scrub in all no-df

# Allow incoming ports for known networks
pass in quick proto tcp from $allowed_networks to any port $incoming_services_tcp
pass in quick proto udp from $allowed_networks to any port $incoming_services_udp

# Block from other networks
block drop in quick proto tcp from any to any port $incoming_services_tcp
block drop in quick proto udp from any to any port $incoming_services_udp
"""

extension LLFW {
    static func writePfRules() throws {
        try ruleset.write(toFile: anchorFile, atomically: true, encoding: .utf8)
    }
}

