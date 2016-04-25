# configure a Simple WebAuth "SP"

class scottylogan::webserver (
){

  include ::stdlib

  class { 'apache':
    default_vhost     => false,
    default_ssl_vhost => false,
  }

  class { 'apache::mod::ssl':
    ssl_compression => true,
    ssl_cipher      => join([
      'ECDHE-RSA-AES128-GCM-SHA256',
      'ECDHE-ECDSA-AES128-GCM-SHA256',
      'ECDHE-RSA-AES256-GCM-SHA384',
      'ECDHE-ECDSA-AES256-GCM-SHA384',
      'DHE-RSA-AES128-GCM-SHA256',
      'DHE-DSS-AES128-GCM-SHA256',
      'kEDH+AESGCM',
      'ECDHE-RSA-AES128-SHA256',
      'ECDHE-ECDSA-AES128-SHA256',
      'ECDHE-RSA-AES128-SHA',
      'ECDHE-ECDSA-AES128-SHA',
      'ECDHE-RSA-AES256-SHA384',
      'ECDHE-ECDSA-AES256-SHA384',
      'ECDHE-RSA-AES256-SHA',
      'ECDHE-ECDSA-AES256-SHA',
      'DHE-RSA-AES128-SHA256',
      'DHE-RSA-AES128-SHA',
      'DHE-DSS-AES128-SHA256',
      'DHE-RSA-AES256-SHA256',
      'DHE-DSS-AES256-SHA',
      'DHE-RSA-AES256-SHA',
      'AES128-GCM-SHA256',
      'AES256-GCM-SHA384',
      'AES128-SHA256',
      'AES256-SHA256',
      'AES128-SHA',
      'AES256-SHA',
      'AES',
      'CAMELLIA',
      'DES-CBC3-SHA',
      '!aNULL',
      '!eNULL',
      '!EXPORT',
      '!DES',
      '!RC4',
      '!MD5',
      '!PSK',
      '!aECDH',
      '!EDH-DSS-DES-CBC3-SHA',
      '!EDH-RSA-DES-CBC3-SHA',
      '!KRB5-DES-CBC3-SHA'
    ], ':'),
  }
  
  class { 'apache::mod::php': }
  class { 'apache::mod::rewrite': }
  
  # this will work, once we have Apache >2.4.7 and openssl >1.01
  #apache::custom_config { 'dhparams':
  #  ensure  => present,
  #  content => 'SSLOpenSSLConfCmd DHParameters "/etc/apache2/dhparams.pem"',
  #  notify  => Exec['create dhparams'],
  #}

  apache::vhost { 'scottylogan.com non-ssl':
    servername      => 'scottylogan.com',
    port            => '80',
    docroot         => '/var/www',
    redirect_status => 'permanent',
    redirect_dest   => 'https://scottylogan.com/',
  }

  apache::vhost { 'scottylogan.com ssl':
    servername    => 'scottylogan.com',
    port          => '443',
    docroot       => '/var/www',
    docroot_owner => 'root',
    docroot_group => 'www-data',
    ssl           => true,
    ssl_cert      => '/etc/ssl/certs/server.pem',
    ssl_key       => '/etc/ssl/private/server.key',
    logroot_mode  => '0755',
  }

  exec { 'create dhparams':
    command => '/usr/bin/openssl dhparam -out /etc/apache2/dhparams.pem',
    creates => '/etc/apache2/dhparams.pem',
  }
  ->
  exec { 'concat cert and dhparams':
    command => '/bin/sh -c "cat /etc/ssl/certs/server.pem; echo; cat /etc/apache2/dhparams.pem" >/tmp/server.pem',
    creates => '/tmp/server.pem',
  }
  ->
  exec { 'fix server.pem':
    command => '/bin/grep -v "^ *$" /tmp/server.pem > /tmp/server2.pem',
    creates => '/tmp/server2.pem',
  }
  ->
  file { '/etc/ssl/certs/server.pem': 
    ensure => file,
    owner  => 0,
    group  => 0,
    mode   => '0644',
    source => 'file:///tmp/server2.pem'
  }
  ->
  exec { 'cleanup tmp certs':
    command => '/bin/rm -f /tmp/server.pem /tmp/server2.pem',
  }
}

