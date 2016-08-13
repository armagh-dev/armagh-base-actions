INTEGRATION TEST ENVIRONMENT
============================

FTP and SFTP
------------
The integration tests for (S)FTP assume the existence of an active (S)FTP server.  You must configure
an (S)FTP server in your environment as described below, and provide the hostname and credentials
in a json configuration in this folder.

The server you configure must have a password-protected account whose base directory has the 
following subdirectories:

   *  no_access_dir owned by a different user and group
   *  read_only_dir with 500 permissions
   *  readwrite_dir with 775 permissions, empty
   
Then you should create a JSON file in this directory named 'local_integration_test_config.json' with a hash containing members

   'test_ftp_username' => username as a string
   'test_ftp_password' => password as a Base64-encoded string
   'test_ftp_host'     => FQDN of your ftp server as a string

   'test_sftp_username' => username as a string
   'test_sftp_password' => password as a Base64-encoded string
   'test_sftp_host'     => FQDN of your sftp server as a string
   
HTTP
----
The integration tests for HTTP assume the existence of an active HTTP test server running Noragh's 
test_web_server rails application.  This server provides expected endpoints for testing.

You should add the following hash member to the 'local_integration_test_config.json' file you created above.

   'test_http_url' => url to the test_web_server (e.g. https://server.domain.com/suites)
