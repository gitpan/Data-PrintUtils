package Data::PrintUtils;

use 5.006;
use strict;
use warnings;
use feature 'say';
use XML::Simple;
use Data::Dumper;

=head1 NAME

Data::PrintUtils - The great new Data::PrintUtils!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Provides a collection of pretty print routines

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 formatList

=head2 formatOneLineHash

=head2 formatHash

=head2 formatTable

=head2 pivotTable

=head2 joinTable

=cut
package Data::PrintUtils;
BEGIN {
    use Exporter ();
    our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
# set the version for version checking
    $VERSION = '0.01';
    @ISA = qw(Exporter);
    @EXPORT_OK = qw();
    %EXPORT_TAGS = ( ALL => [ qw!&print_pid &say_pid &formatList &formatOneLineHash &formatHash
        &formatTable &pivotTable &tableJoin $USE_PIDS $USE_TIME! ], ); # eg: TAG => [ qw!name1 name2! ],

#your exported package globals go here,
#as well as any optionally exported functions
    @EXPORT_OK = qw(&print_pid &say_pid &formatList &formatOneLineHash &formatHash
        &formatTable &pivotTable &tableJoin $USE_PIDS $USE_TIME);
}


use Getopt::CommandLineExports qw(:ALL);



our $USE_PIDS = 0;
our $USE_TIME = 0;
use Time::HiRes qw(gettimeofday);

=head2 print_pid

A replacement for print that will optionally prepend the processID and the timestamp to a line

These two fields are turned off/on with the package variables:

    $Data::PrintUtils::USE_PIDS = 1 or 0;
    $Data::PrintUtils::USE_TIME = 1 or 0;
    

=cut

sub print_pid { CORE::print "$$ : " if $USE_PIDS; CORE::print join(".", gettimeofday()) . " : " if $USE_TIME; CORE::print @_;};

=head2 say_pid

A replacement for say that will optionally prepend the processID and the timestamp to a line

These two fields are turned off/on with the package variables:

    $Data::PrintUtils::USE_PIDS = 1 or 0;
    $Data::PrintUtils::USE_TIME = 1 or 0;
    
=cut

sub say_pid   { CORE::print "$$ : " if $USE_PIDS; CORE::print join(".", gettimeofday()) . " : " if $USE_TIME; CORE::say   @_;};

=head2 formatList

Formats a list as a single line of comma seperated values in '(' ')'

=cut

sub formatList
{
    return "(" . join (", ",@_) . ")";
}


=head2 formatOneLineHash

Formats a hash as a single line of => and comma separated values in '{' '}'

=cut

sub formatOneLineHash
{
    my $href = shift;
    my %h = (
        PRIMARY_KEY_ORDER   => undef,
        ( parseArgs \@_, 'PRIMARY_KEY_ORDER=s@'),
    );    
    my %x = %$href;
    my $s = "{";
    my @primeKeys  =  defined $h{PRIMARY_KEY_ORDER}    ? @{$h{PRIMARY_KEY_ORDER}}   : keys %$href;    
    my @keyvals = ();
    for( @primeKeys )
    {
        push @keyvals , "$_ => $href->{$_}" if defined     $href->{$_};
        push @keyvals , "$_ => undef" unless defined $href->{$_};
    }
    $s = $s . join (", ",  @keyvals) . "}";
}



=head2 formatHash

=cut


sub formatHash
{
    my $hash_ref = shift;
    my %h = (
            KEY_JUSTIFCATION    => 'Right',
            VALUE_JUSTIFICATION => 'Left',
            MAX_KEY_WIDTH       => 10000,
            MAX_VALUE_WIDTH     => 10000,
            PRIMARY_KEY_ORDER   => undef,
            SECONDARY_KEY_ORDER => undef,
        ( parseArgs \@_, 'KEY_JUSTIFCATION=s', 'VALUE_JUSTIFICATION=s', 'MAX_KEY_WIDTH=i', 'MAX_VALUE_WIDTH=i', 'PRIMARY_KEY_ORDER=s@', 'SECONDARY_KEY_ORDER=s@'),
    );
    my $maxKeyLen = 0;
    my $maxValLen = 0;
    $maxKeyLen = (length > $maxKeyLen) ? length : $maxKeyLen foreach (keys %$hash_ref);
    $maxValLen = (defined  $_) ? (length > $maxValLen) ? length : $maxValLen : 1 foreach (values %$hash_ref);
    $maxKeyLen = ($maxKeyLen > $h{MAX_KEY_WIDTH})   ? $h{MAX_KEY_WIDTH}   : $maxKeyLen;
    $maxValLen = ($maxValLen > $h{MAX_VALUE_WIDTH}) ? $h{MAX_VALUE_WIDTH} : $maxValLen;
    my $s ="";
    my $keyFormat   = $h{KEY_JUSTIFCATION}      eq 'Right' ? "%*.*s => " : "%-*.*s => ";
    my $valueFormat = $h{VALUE_JUSTIFICATION}   eq 'Right' ? "%*.*s\n"   : "%-*.*s\n";
	my $undefinedFormat = "undef\n";
    my @primeKeys  =  defined $h{PRIMARY_KEY_ORDER}    ? @{$h{PRIMARY_KEY_ORDER}}   : keys %$hash_ref;
#    my @secondKeys =  defined $h{SECONDARY_KEY_ORDER}  ? @{$h{SECONDARY_KEY_ORDER}} : undef;
    
    for(@primeKeys)
    {
        $s = $s . sprintf($keyFormat,   $maxKeyLen, $h{MAX_KEY_WIDTH},    $_);
        $s = $s . sprintf($valueFormat, $maxValLen, $h{MAX_VALUE_WIDTH}, formatList(@{$hash_ref->{$_}}))          if  (ref $hash_ref->{$_} eq "ARRAY");
        $s = $s . sprintf($valueFormat, $maxValLen, $h{MAX_VALUE_WIDTH}, formatOneLineHash(\%{$hash_ref->{$_}}, {PRIMARY_KEY_ORDER => $h{SECONDARY_KEY_ORDER} } )) if  (ref $hash_ref->{$_} eq "HASH" and defined $h{SECONDARY_KEY_ORDER});
        $s = $s . sprintf($valueFormat, $maxValLen, $h{MAX_VALUE_WIDTH}, formatOneLineHash(\%{$hash_ref->{$_}}))  if  (ref $hash_ref->{$_} eq "HASH" and not defined $h{SECONDARY_KEY_ORDER});
        $s = $s . sprintf($valueFormat, $maxValLen, $h{MAX_VALUE_WIDTH}, $$hash_ref{$_} )                         if  (ref $hash_ref->{$_} eq "" and defined $hash_ref->{$_} );
        $s = $s . sprintf($undefinedFormat)                         											  if  (ref $hash_ref->{$_} eq "" and not defined $hash_ref->{$_} );
    }
    return $s;
}


=head2 formatTable

Formats a table (given as an array of hash references (as returned from DBI) ) into
a somewhat pleasant display.  With the Columns argument, you can chose to only
print a subset of the columns (and you can define the column ordering).

=over

=item ROWS
This is a reference to the table (which should be an array of hashes refs)

=item COLUMNS
This is a list of columns (in order) to be displayed

=item UNDEF_VALUE
This is a string value to be displayed whenever an item is "undefined"

=back

=cut

sub formatTable
{
    my %h = (
#        ROWS    => undef,
#        COLUMNS => undef,
        XML_REPORT              => undef,
        UNDEF_VALUE             => '',
        START_FIELD_DELIMITER   => '',
        END_FIELD_DELIMITER     => ' ',
        ROW_NAME 				=> 'row',
        ( parseArgs \@_, 'ROWS=s@', 'COLUMNS:s{0,99}', 'UNDEF_VALUE=s', 'START_FIELD_DELIMITER=s', 'END_FIELD_DELIMITER=s'),
    );
    my $array_of_hash_ref = $h{ROWS};
    my $listOfColumns = $h{COLUMNS};
  	if (defined $h{XML_REPORT})
	{
		my @List =(defined $listOfColumns ? @$listOfColumns : keys  %{$array_of_hash_ref->[0]});
        my $s ="";
        my @trimedArrayOfHashRefs = ();
		foreach my $hash_ref (@$array_of_hash_ref)
		{
	        my %x = ();
			$x{$_} = defined $hash_ref->{$_} ? $hash_ref->{$_} : $h{UNDEF_VALUE} foreach (@List);
			push @trimedArrayOfHashRefs, \%x;
		}
		$s .= XML::Simple::XMLout($_, NoAttr => 1, RootName => $h{ROW_NAME} ) foreach @trimedArrayOfHashRefs;
		return $s;        
	}

    my %maxColumnWidth;
    foreach my $hash_ref (@$array_of_hash_ref)
    {
        my @List = (keys %$hash_ref, (defined $listOfColumns ? @$listOfColumns : undef ));
        pop @List unless defined $listOfColumns;
        foreach (@List)
        {
            $maxColumnWidth{$_} = (length > (defined $maxColumnWidth{$_} ? $maxColumnWidth{$_} : 0)) ? length : $maxColumnWidth{$_};
            if (defined $$hash_ref{$_})
            {
                $maxColumnWidth{$_} = (length $$hash_ref{$_} > (defined $maxColumnWidth{$_} ? $maxColumnWidth{$_} : 0)) ? length $$hash_ref{$_}: $maxColumnWidth{$_};
            }
        }
    }
    $maxColumnWidth{$_} = $maxColumnWidth{$_} > length $h{UNDEF_VALUE} ? $maxColumnWidth{$_} : length $h{UNDEF_VALUE} foreach (keys %maxColumnWidth);
#print header

    @$listOfColumns = keys %maxColumnWidth if (not defined $listOfColumns);
    my $s = "";
    $s = $s . sprintf("$h{START_FIELD_DELIMITER}%*s$h{END_FIELD_DELIMITER}", (defined $maxColumnWidth{$_}) ? ($maxColumnWidth{$_}) : length , $_) foreach (@$listOfColumns);
    $s = $s . "\n";
    foreach my $hash_ref (@$array_of_hash_ref)
    {
        $s = $s . sprintf("$h{START_FIELD_DELIMITER}%*s$h{END_FIELD_DELIMITER}", $maxColumnWidth{$_}, (defined $$hash_ref{$_} ? $$hash_ref{$_} : $h{UNDEF_VALUE})) foreach (@$listOfColumns);
        $s = $s . "\n";
    }
    return $s;
}

=head2 pivotTable

pivots an attribute-value table (given as an array of hash references (as returned from DBI) ) 
into a new table with a row for each unique PIVOT_KEY and a column for each attribute

example:
my @table = 
(
{COL1 => 1, Name => 'PID',  VALUE => '1a', XTRA1 => '111'},
{COL1 => 1, Name => 'SID',  VALUE => 's1', XTRA1 => '112'},
{COL1 => 1, Name => 'XV1',  VALUE => 'YY', XTRA1 => '116'},
{COL1 => 1, Name => 'XV2',  VALUE => 'XX', XTRA1 => '117'},

{COL1 => 2, Name => 'PID',  VALUE => '2a', XTRA1 => '221'},
{COL1 => 2, Name => 'SID',  VALUE => 's2', XTRA1 => '222'},
{COL1 => 2, Name => 'XV2',  VALUE => 'XX2', XTRA1 => '224'},
);
my @newTable1 = pivotTable { ROWS => \@table, PIVOT_KEY => 'COL1', VALUE_HEADER_KEY=> 'Name', VALUE_KEY => 'VALUE'};
say formatTable { ROWS => \@newTable1, UNDEF_VALUE => 'NULL'} if @newTable1;

results in 
COL1 PID SID  XV1 XV2
   1  1a  s1   YY  XX
   2  2a  s2 NULL XX2

=cut

sub pivotTable
{
    my %h = (
#            ROWS                => undef,
            PIVOT_KEY           => undef,
            VALUE_HEADER_KEY    => undef,
            VALUE_KEY           => undef,
        ( parseArgs \@_, 'ROWS=s@', 'PIVOT_KEY=s', 'VALUE_HEADER_KEY=s', 'VALUE_KEY=s'),
    );
    my $table_ref = $h{ROWS}; 
    my %newKeys;
    my @newTable = ();
    foreach (@{$table_ref} )
    {
        my $newKey      = $_->{ $h{PIVOT_KEY} };
        my $newColKey   = $_->{ $h{VALUE_HEADER_KEY} };
        my $newColValue = $_->{ $h{VALUE_KEY} };
        $newKeys{ $_->{ $h{PIVOT_KEY} } } = {%{$newKeys{ $_->{ $h{PIVOT_KEY} } }}, $newColKey => $newColValue}  if      defined $newKeys{ $_->{ $h{PIVOT_KEY} } };
        $newKeys{ $_->{ $h{PIVOT_KEY} } } = {$newColKey => $newColValue}                                        unless  defined $newKeys{ $_->{ $h{PIVOT_KEY} } };
    }
    push @newTable, {%{$newKeys{ $_ }}, $h{PIVOT_KEY} => $_} foreach (keys %newKeys) ;
    return @newTable;
}

=head2 joinTable

Formats a table (given as an array of hash references (as returned from DBI) ) into
a somewhat pleasant display.  With the Columns argument, you can chose to only
print a subset of the columns (and you can define the column ordering).

=cut

sub joinTable
{
    my %h = (
            LEFT_TABLE          => undef,
            RIGHT_TABLE         => undef,
            JOIN_KEY            => undef,
            LEFT_JOIN_KEY_UNIQUE     => 0,
        ( parseArgs \@_, 'LEFT_TABLE=s@','RIGHT_TABLE=s@','JOIN_KEY=s','LEFT_JOIN_KEY_UNIQUE'),
    );
    my @newTable = ();
    my %rekeyedTable = ();
    
    if ($h{LEFT_JOIN_KEY_UNIQUE}) {
        foreach (@{$h{LEFT_TABLE}})
        {
            $rekeyedTable{ $_->{$h{JOIN_KEY}}} = \%{$_};
        }
        foreach (@{$h{RIGHT_TABLE}})
        {
            push @newTable, {%{$_}, %{$rekeyedTable{$_->{$h{JOIN_KEY}}}}} if defined $rekeyedTable{$_->{$h{JOIN_KEY}}};
        }
    }
    else 
    {
        foreach my $leftRow (@{$h{LEFT_TABLE}})
        {
            foreach my $rightRow (@{$h{RIGHT_TABLE}})
            { 
                push @newTable, {%{$leftRow}, %{$rightRow}} if $leftRow->{ $h{JOIN_KEY} } eq  $rightRow->{ $h{JOIN_KEY} }
            }        
        }
    }
    return @newTable;
}



END { } # module clean-up code here (global destructor)


=head1 AUTHOR

Robert Haxton, C<< <robert.haxton at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-Data-printutils at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-PrintUtils>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::PrintUtils


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-PrintUtils>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-PrintUtils>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-PrintUtils>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-PrintUtils/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2008-2011 Robert Haxton.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Data::PrintUtils
