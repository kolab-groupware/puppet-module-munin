class munin {
    class server inherits munin {
        file { "/etc/munin/munin.conf":
            source => [
                "puppet://$server/private/$environment/munin/munin.conf.$hostname",
                "puppet://$server/private/$environment/munin/munin.conf",
                "puppet://$server/modules/files/munin/munin.conf.$hostname",
                "puppet://$server/modules/files/munin/munin.conf",
                "puppet://$server/modules/munin/munin.conf"
            ],
            require => Package["munin"],
            noop => false
        }

        file { "/var/log/munin/":
            ensure => directory,
            owner => "munin",
            group => "munin",
            mode => "770"
        }

        File <<| tag == "munin_node_conf" |>>

        package { "munin":
            ensure => installed,
            noop => false
        }

        munin::plugin { [
                "munin_graph",
                "munin_update"
            ]:
            enable => true,
            require => Package["munin-node"]
        }
    }

    package { "munin-node":
        ensure => installed,
        noop => false
    }

    @@file { "/etc/munin/node.d/$fqdn.conf":
        owner => "munin",
        group => "apache",
        mode => "640",
        content => template("munin/node.erb"),
        tag => "munin_node_conf",
        backup => false,
        noop => false
    }

    file { "/etc/munin/munin-node.conf":
        source => [
            "puppet://$server/private/$environment/munin/munin-node.conf.$hostname",
            "puppet://$server/private/$environment/munin/munin-node.conf",
            "puppet://$server/modules/files/munin/munin-node.conf.$hostname",
            "puppet://$server/modules/files/munin/munin-node.conf",
            "puppet://$server/modules/munin/munin-node.conf"
        ],
        require => Package["munin-node"],
        notify => Service["munin-node"],
        noop => false
    }

    file { "/etc/munin/plugins/":
        source => [
            "puppet://$server/private/$environment/munin/plugins/",
            "puppet://$server/modules/files/munin/plugins/",
            "puppet://$server/modules/munin/plugins/"
        ],
        require => Package["munin-node"],
        notify => Service["munin-node"],
        noop => false
    }

    file { "/var/log/munin/":
        ensure => directory,
        mode => "750",
        owner => munin,
        group => munin,
        require => Package["munin-node"],
        noop => false
    }

    service { "munin-node":
        ensure => running,
        enable => true,
        hasrestart => true,
        noop => false,
        require => [
            File["/etc/munin/munin-node.conf"],
            Package["munin-node"]
        ]
    }

    class mysql_server {
        # An entire collection of things that have
        # to do with MySQL server monitoring
        munin::plugin { "cpuload_mysqld":
            enable => true,
            source => true,
            plugin_name => "cpuload_"
        }

        munin::plugin { [
                "mysql_connections",
                "mysql_qcache",
                "mysql_qcache_mem"
            ]:
            enable => true,
            conf => [
                    "puppet://$server/private/$environment/munin/plugin-conf.d/mysql.$hostname",
                    "puppet://$server/private/$environment/munin/plugin-conf.d/mysql",
                    "puppet://$server/modules/files/munin/plugin-conf.d/mysql.$hostname",
                    "puppet://$server/modules/files/munin/plugin-conf.d/mysql",
                    "puppet://$server/modules/munin/plugin-conf.d/mysql.$hostname",
                    "puppet://$server/modules/munin/plugin-conf.d/mysql"
                ],
            source => true,
            conf_name => "mysql",
            require => Package["munin-node"]
        }

        munin::plugin { [
                "mysql_bytes",
                "mysql_queries",
                "mysql_slowqueries",
                "mysql_threads"
            ]:
            enable => true,
            conf => [
                    "puppet://$server/private/$environment/munin/plugin-conf.d/mysql.$hostname",
                    "puppet://$server/private/$environment/munin/plugin-conf.d/mysql",
                    "puppet://$server/modules/files/munin/plugin-conf.d/mysql.$hostname",
                    "puppet://$server/modules/files/munin/plugin-conf.d/mysql",
                    "puppet://$server/modules/munin/plugin-conf.d/mysql.$hostname",
                    "puppet://$server/modules/munin/plugin-conf.d/mysql"
                ],
            conf_name => "mysql",
            require => Package["munin-node"]
        }
    }

    define plugin (
            $enable = true,
            $plugin_name = false,
            $source = false,
            $conf = false,
            $conf_name = false
        ) {

        file { "/etc/munin/plugins/$name":
            ensure => $enable ? {
                true => $plugin_name ? {
                    false => "/usr/share/munin/plugins/$name",
                    default => "/usr/share/munin/plugins/$plugin_name"
                },
                default => absent
            },
            links => manage,
            noop => false,
            require => $plugin_name ? {
                    false => [
                            File["/usr/share/munin/plugins/$name"],
                            Package["munin-node"]
                        ],
                    default => [
                            File["/usr/share/munin/plugins/$plugin_name"],
                            Package["munin-node"]
                        ],
                },
            notify => Service["munin-node"]
        }

        if $source {
            if $plugin_name {
                if !defined(File["/usr/share/munin/plugins/$plugin_name"]) {
                    file { "/usr/share/munin/plugins/$plugin_name":
                        mode => "755",
                        owner => "root",
                        group => "root",
                        ensure => $enable ? {
                            true => file,
                            default => absent
                        },
                        noop => false,
                        source => $source ? {
                            true => [
                                    "puppet://$server/private/$environment/munin/plugins/$plugin_name",
                                    "puppet://$server/modules/files/munin/plugins/$plugin_name",
                                    "puppet://$server/modules/munin/plugins/$plugin_name"
                                ],
                            default => $source
                        },
                        notify => Service["munin-node"],
                        require => Package["munin-node"]
                    }
                }
            } else {
                if !defined(File["/usr/share/munin/plugins/$name"]) {
                    file { "/usr/share/munin/plugins/$name":
                        mode => "755",
                        owner => "root",
                        group => "root",
                        ensure => $enable ? {
                            true => file,
                            default => absent
                        },
                        noop => false,
                        source => $source ? {
                            true => [
                                    "puppet://$server/private/$environment/munin/plugins/$name",
                                    "puppet://$server/modules/files/munin/plugins/$name",
                                    "puppet://$server/modules/munin/plugins/$name"
                                ],
                            default => $source
                        },
                        notify => Service["munin-node"],
                        require => Package["munin-node"]
                    }

                }
            }
        } else {
            if $plugin_name {
                if !defined(File["/usr/share/munin/plugins/$plugin_name"]) {
                    file { "/usr/share/munin/plugins/$plugin_name":
                        mode => "755",
                        owner => "root",
                        group => "root",
                        ensure => $enable ? {
                            true => file,
                            default => absent
                        },
                        noop => false,
                        notify => Service["munin-node"],
                        require => Package["munin-node"]
                    }
                }
            } else {
                if !defined(File["/usr/share/munin/plugins/$name"]) {
                    file { "/usr/share/munin/plugins/$name":
                        mode => "755",
                        owner => "root",
                        group => "root",
                        ensure => $enable ? {
                            true => file,
                            default => absent
                        },
                        noop => false,
                        notify => Service["munin-node"],
                        require => Package["munin-node"]
                    }
                }
            }
        }

        if $conf {
            if !defined(File["/etc/munin/plugin-conf.d/$conf_name"]) {
                file { "/etc/munin/plugin-conf.d/$conf_name":
                    path => $conf_name ? {
                        false => "/etc/munin/plugin-conf.d/$name",
                        default => "/etc/munin/plugin-conf.d/$conf_name"
                    },
                    owner => "munin",
                    group => "munin",
                    mode => "640",
                    ensure => $enable ? {
                        true => file,
                        default => absent
                    },
                    noop => false,
                    source => $conf,
                    notify => Service["munin-node"],
                    require => Package["munin-node"]
                }
            }
        }

    }

}
