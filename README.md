# pansnaps

* checkout in `$OMD_ROOT/etc/thruk/plugins-available/pansnaps`
* symlink `$OMD_ROOT/etc/thruk/plugins-available/pansnaps` to `$OMD_ROOT/etc/thruk/plugins-enabled/pansnaps`
* copy `pansnaps.conf` to `$OMD_ROOT/etc/apache/conf.d`
* copy `pansnaps.crontab` to `$OMD_ROOT/etc/cron.d/pansnaps`
* `mkdir -p $OMD_ROOT/var/pansnaps/htdocs`
* omd reload apache
* omd reload crontab
