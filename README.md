# Auto Poweroff for Synology Diskstation

Shutdown your NAS based on network traffic statistics.

## Install

    $ scp auto-poweroff.sh root@diskstation.local:

## Usage

You can control the monitor job with `start`, `stop`, `restart` and `status`
commands:

    $ ssh root@diskstation.local
    $ ./auto-poweroff.sh [start|stop|restart|status]

The job will be killed by the OS once you close the SSH connection and neither
`nohub` nor `&` will keep it running. Either create crontab entries to start
and stop the monitor at specific times or create a symlink in `rc.d`:

    $ ln -s /root/auto-poweroff.sh /usr/syno/etc/rc.d/S99auto-poweroff.sh

## Configure

Options are defined at the top of the script as shell variables:

    $ vi auto-poweroff.sh

Config:

- `LOGFILE` Log file location. Defaults to `/var/log/auto-poweroff.log`.
- `MINUTES` Number of silent minutes before automatic poweroff. Defaults to
  `90`.
- `TOLERATE` Number of packages to tolerate per minute. Defaults to `100`.
- `DEBUG` Set to `1` to see RX/TX diffs every minute in the log file. Note that
  this will prevent disk spin-down. Defaults to `0`.

## Options

- `--minutes`, `-m` Overrides the number of minutes

## Crontab

Edit the crontab with vi:

    $ vi /etc/crontab

Change the number of minutes to wait to 15 every day at 22:30:

    #minute hour    mday    month   wday    who     command
    30      22      *       *       *       root    /root/auto-poweroff.sh restart --minutes 15

Restart crond:

    $ kill -HUP `pidof crond`

## License

MIT

