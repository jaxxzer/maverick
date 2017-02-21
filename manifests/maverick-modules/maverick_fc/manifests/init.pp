class maverick_fc (
    $fc_dronekit_source = "http://github.com/dronekit/dronekit-python.git",
    $mavproxy_active = true,
) {

    # Install a virtual environment for dronekit fc
    file { "/srv/maverick/code/fc":
        ensure      => directory,
        owner       => "mav",
        group       => "mav",
        mode        => 755,
    } ->
    python::virtualenv { '/srv/maverick/code/fc':
        ensure       => present,
        version      => 'system',
        systempkgs   => false,
        distribute   => true,
        venv_dir     => '/srv/maverick/.virtualenvs/fc',
        owner        => 'mav',
        group        => 'mav',
        cwd          => '/srv/maverick/code/fc',
        timeout      => 0,
    } ->
    file { "/srv/maverick/.virtualenvs/fc/lib/python2.7/no-global-site-packages.txt":
        ensure  => absent
    } ->
    oncevcsrepo { "git-fc-dronekit-python":
        gitsource   => $fc_dronekit_source,
        dest        => "/srv/maverick/code/fc/dronekit-python",
    }
    
    python::pip { 'pip-dronekit-fc':
        pkgname     => 'dronekit',
        virtualenv  => '/srv/maverick/.virtualenvs/fc',
        ensure      => present,
        owner       => 'mav',
        timeout     => 0,
    }
    python::pip { 'pip-mavproxy-fc':
        pkgname     => 'MAVProxy',
        virtualenv  => '/srv/maverick/.virtualenvs/fc',
        ensure      => present,
        owner       => 'mav',
        timeout     => 0,
    }
        
    file { "/srv/maverick/var/log/mavproxy-fc":
        ensure      => directory,
        owner       => "mav",
        group       => "mav",
        mode        => 755,
    }
    
    file { "/srv/maverick/data/config/mavproxy-fc.conf":
        ensure      => present,
        owner       => "mav",
        group       => "mav",
        replace     => false, # initialize but don't overwrite in the future
        source      => "puppet:///modules/maverick_fc/mavproxy-fc.conf",
        notify      => Service["maverick-mavproxy-fc"]
    } ->
    file { "/srv/maverick/data/config/mavproxy-fc.screen.conf":
        ensure      => present,
        owner       => "mav",
        group       => "mav",
        source      => "puppet:///modules/maverick_fc/mavproxy-fc.screen.conf",
        notify      => Service["maverick-mavproxy-fc"]
    } ->
    file { "/srv/maverick/software/maverick/bin/mavproxy-fc.sh":
        ensure      => link,
        target      => "/srv/maverick/software/maverick/manifests/maverick-modules/maverick_fc/files/mavproxy-fc.sh",
    } ->
    file { "/etc/systemd/system/maverick-mavproxy-fc.service":
        content     => template("maverick_fc/mavproxy-fc.service.erb"),
        owner       => "root",
        group       => "root",
        mode        => 644,
        notify      => [ Exec["maverick-systemctl-daemon-reload"], Service["maverick-mavproxy-fc"] ]
    }

    if $mavproxy_active == true {
        service { "maverick-mavproxy-fc":
            ensure      => running,
            enable      => true,
            require     =>[ File["/etc/systemd/system/maverick-mavproxy-fc.service"], Exec["maverick-systemctl-daemon-reload"] ]
        }
    } else {
        service { "maverick-mavproxy-fc":
            ensure      => stopped,
            enable      => false,
        }
    }
    
    # Punch some holes in the firewall for mavproxy
    if defined(Class["::maverick_security"]) {
        maverick_security::firewall::firerule { "mavproxy-fc-udp":
            ports       => [14555-14557],
            ips         => hiera("all_ips"),
            proto       => "udp"
        }
        maverick_security::firewall::firerule { "mavproxy-fc-tcp":
            ports       => [5765-5777],
            ips         => hiera("all_ips"),
            proto       => "tcp"
        }
    }
   
        
}