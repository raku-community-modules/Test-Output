use v6.d;

unit module Test::Output;
use Test;

my Bool $verbosity;

sub test-output-verbosity(Bool :$on = True, Bool :$off = False) is export {
    $verbosity =  $on ?? True !! False;
    $verbosity =  $off ?? False !! True;
}

my class IO::Bag {
    has @.err-contents;
    has @.out-contents;
    has @.all-contents;

    method err { @.err-contents.join: '' }
    method out { @.out-contents.join: '' }
    method all { @.all-contents.join: '' }
}

my class IO::Capture::Single is IO::Handle {
    has Bool    $.is-err =  False   ;
    has IO::Bag $.bag    is required;
    has IO::Handle $.orig-handle;

    submethod TWEAK {
        self.encoding: 'utf8'; # set up encoder/decoder 
    }

    method WRITE( IO::Handle:D: Blob:D \data --> Bool:D ) {
        my $str = data.decode();

        if $verbosity {
            my $saved-out = $!is-err ?? $PROCESS::ERR !! $PROCESS::OUT;
            $!is-err ?? ($PROCESS::ERR = $!orig-handle) !! ($PROCESS::OUT = $!orig-handle);
            say $str.chomp;
            $!is-err ?? ($PROCESS::ERR = $saved-out) !! ($PROCESS::OUT = $saved-out);
        }

        $.bag.all-contents.push: $str;
        $!is-err ?? $.bag.err-contents.push: $str
                 !! $.bag.out-contents.push: $str;
        True;
    }

}

my sub capture (&code) {
    my $orig-out = $PROCESS::OUT;
    my $orig-err = $PROCESS::ERR;

    my $bag = IO::Bag.new;
    my $out = IO::Capture::Single.new: :$bag, orig-handle => $orig-out;
    my $err = IO::Capture::Single.new: :$bag, orig-handle => $orig-err, :is-err;

    $PROCESS::OUT = $out;
    $PROCESS::ERR = $err;

    &code();

    $PROCESS::OUT = $orig-out;
    $PROCESS::ERR = $orig-err;

    return {:out($bag.out), :err($bag.err), :all($bag.all)};
}

sub output-is   (*@args) is export { test |<all is>,   &?ROUTINE.name, |@args }
sub output-like (*@args) is export { test |<all like>, &?ROUTINE.name, |@args }
sub stdout-is   (*@args) is export { test |<out is>,   &?ROUTINE.name, |@args }
sub stdout-like (*@args) is export { test |<out like>, &?ROUTINE.name, |@args }
sub stderr-is   (*@args) is export { test |<err is>,   &?ROUTINE.name, |@args }
sub stderr-like (*@args) is export { test |<err like>, &?ROUTINE.name, |@args }

sub output-from (&code)  is export { return capture(&code)<all> }
sub stderr-from (&code)  is export { return capture(&code)<err> }
sub stdout-from (&code)  is export { return capture(&code)<out> }

sub test (
    Str:D $output-type where { any <all err out>  },
    Str:D $op-name     where { any <is like from> },
    Str:D $routine-name,
    &code,
    $expected where Str|Regex,
    Str $test-name? is copy
)
{
    $test-name //= "$routine-name on line {callframe(4).line}";
    if ( $op-name eq 'from' ) {
        return capture(&code){ $output-type };
    }
    else {
        return &::($op-name)(
            capture(&code){ $output-type },
            $expected,
            $test-name,
        );
    }
}
