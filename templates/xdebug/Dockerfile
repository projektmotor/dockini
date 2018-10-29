RUN pecl install xdebug

RUN echo "extension=zip.so"  >> /usr/local/etc/php/conf.d/zip.ini
RUN echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)"  >  /usr/local/etc/php/conf.d/xdebug.ini
RUN echo "xdebug.remote_enable=1"                                                 >> /usr/local/etc/php/conf.d/xdebug.ini
RUN echo "xdebug.remote_autostart=1"                                              >> /usr/local/etc/php/conf.d/xdebug.ini
RUN echo "xdebug.remote_host=172.17.0.1"                                          >> /usr/local/etc/php/conf.d/xdebug.ini
