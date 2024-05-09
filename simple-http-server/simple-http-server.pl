use strict;
use warnings;
use HTTP::Server::Simple::CGI;
use Cwd qw(abs_path);
use File::Basename qw(dirname);
use File::Spec::Functions qw(catfile); # Correct import of catfile
use Win32::Process;
use Win32;

# Determine the current directory
my $root_dir = dirname(abs_path($0));

# HTTP-Server-Class
{
    package MyWebServer;
    use base qw(HTTP::Server::Simple::CGI);
    use File::Slurp;
    use URI::Escape;
    use File::Spec::Functions qw(catfile); # Importing catfile from package

    sub handle_request {
        my ($self, $cgi) = @_;
        
        my $path = uri_unescape($cgi->path_info());
        my $full_path = catfile($root_dir, $path); # Direct call to catfile

        if (-d $full_path) {
            if (-e catfile($full_path, 'index.html')) {
                $full_path = catfile($full_path, 'index.html');
            } else {
                print "HTTP/1.0 200 OK\r\n";
                print $cgi->header('text/html'),
                      $cgi->start_html('Directory Listing'),
                      $cgi->h1('Directory Listing'),
                      $cgi->start_ul;

                opendir(my $dh, $full_path) or die "Cannot open directory: $!";
                while (my $file = readdir($dh)) {
                    next if $file =~ /^\./;
                    print $cgi->li($file);
                }
                closedir($dh);

                print $cgi->end_ul,
                      $cgi->end_html;
                return;
            }
        }

        if (-f $full_path) {
            my $content = read_file($full_path, binmode => ':raw');
            print "HTTP/1.0 200 OK\r\n";
            print $cgi->header(-type => 'text/html', -charset => 'UTF-8'),
                  $content;
        } else {
            print "HTTP/1.0 404 Not Found\r\n";
            print $cgi->header('text/html'),
                  $cgi->start_html('Not Found'),
                  $cgi->h1('Not Found'),
                  $cgi->end_html;
        }
    }
}

# start the server
my $server = MyWebServer->new(8080); # We're using port 8080
$server->host('127.0.0.1');
$server->background();

# Open standard browser
my $url = 'http://127.0.0.1:8080';
Win32::Process::Create(my $process, $ENV{SYSTEMROOT} . '\\system32\\cmd.exe', "cmd /c start $url", 0, NORMAL_PRIORITY_CLASS, ".");

print "Server is up and running: $url\n";