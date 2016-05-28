use warnings;
use strict;
sub make_image_dir {
    use File::Path qw(make_path);
    my ( $base_dir, $camera_name ) = @_;
    my ( $year, $mon, $day, $hour, $min, $sec ) = foscam_localtime();
    my $directory = "$base_dir/$year/$mon/$day/$camera_name/";
    if ( ! -e $directory ) {
        make_path($directory, { verbose => 1 }) or die "Unable to mkdir --parent $directory";
    }
    return $directory;
}


1;
