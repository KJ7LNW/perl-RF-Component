package RF::Component::Multi;

our $VERSION = do { use RF::Component; $RF::Component::VERSION };

use strict;
use warnings;
use PDL::IO::Touchstone qw/rsnp_list_to_hash/;
use PDL::IO::MDIF;
use RF::Component;
use Carp;
use 5.010;

sub new
{
	my ($class, @components) = @_;

	return bless(\@components, $class);
}

sub load
{
	my ($class, $filename, %newopts) = @_;

	my $rmdif_opts = delete $newopts{load_options};
	my $mdif_data = rmdif($filename, $rmdif_opts);

	my @ret;
	foreach my $snp (@$mdif_data)
	{
		my %data = rsnp_list_to_hash(@{ $snp->{_data} });

		my $c = RF::Component->new(%data);
		
		push @ret, $c;
	}

	return $class->new(@ret);
}

# Thanks @ikegami:
# https://stackoverflow.com/a/74229589/14055985
sub AUTOLOAD
{
	my $method_name = our $AUTOLOAD =~ s/^.*:://sr;

	my $method = sub {
		my $self = shift;
		return [ map { $_->$method_name(@_) } @$self ];
	};

	{
		no strict 'refs';
		*$method_name = $method;
	}

	goto &$method;
}

sub DESTROY {}

