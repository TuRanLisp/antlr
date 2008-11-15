package ANTLR::Runtime::Lexer;
use base qw( ANTLR::Runtime::BaseRecognizer ANTLR::Runtime::TokenSource );

use English qw( -no_match_vars );
use Readonly;
use Carp;
use Switch;

use ANTLR::Runtime::Class;
use ANTLR::Runtime::Token;
use ANTLR::Runtime::CharStream;
use ANTLR::Runtime::MismatchedTokenException;

use strict;
use warnings;

ANTLR::Runtime::Class::create_attributes(__PACKAGE__, [
    qw( input token token_start_char_index token_start_line token_start_char_position_in_line channel type text )
]);

sub new {
    my ($class, $input) = @_;
    my $self = $class->SUPER::new();

    $self->{input} = $input;
    $self->{token} = undef;
    $self->{token_start_char_index} = -1;
    $self->{token_start_line} = undef;
    $self->{token_start_char_position_in_line} = undef;
    $self->{channel} = undef;
    $self->{type} = undef;
    $self->{text} = undef;

    return $self;
}

ANTLR::Runtime::Class::create_accessors(__PACKAGE__, {
    input => 'rw',
    token => 'rw',
    token_start_char_index => 'rw',
    token_start_line => 'rw',
    token_start_char_position_in_line => 'rw',
    channel => 'rw',
    type => 'rw',
});

sub reset {
    Readonly my $usage => 'reset()';
    croak $usage if @_ != 1;
    my ($self) = @_;

    # reset all recognizer state variables
    $self->SUPER::reset();

    # wack Lexer state variables
    $self->set_token(undef);
    $self->set_type(ANTLR::Runtime::Token->INVALID_TOKEN_TYPE);
    $self->set_channel(ANTLR::Runtime::Token->DEFAULT_CHANNEL);
    $self->set_token_start_char_index(-1);
    $self->set_token_start_char_position_in_line(-1);
    $self->set_start_line(-1);
    $self->set_text(undef);

    if (defined $self->get_input) {
        # rewind the input
        $self->get_input->seek(0);
    }
}

# Return a token from this source; i.e., match a token on the char
# stream.
sub next_token {
    Readonly my $usage => 'Token next_token()';
    croak $usage if @_ != 1;
    my ($self) = @_;

    while (1) {
        $self->set_token(undef);
        $self->set_channel(ANTLR::Runtime::Token->DEFAULT_CHANNEL);
        $self->set_token_start_char_index($self->get_input->index());
        $self->set_token_start_char_position_in_line($self->get_input->get_char_position_in_line);
        $self->set_token_start_line($self->get_input->get_line);
        $self->set_text(undef);

        if ($self->get_input->LA(1) eq ANTLR::Runtime::CharStream->EOF) {
            return ANTLR::Runtime::Token->EOF_TOKEN;
        }

        my $rv;
        my $op = '';
        eval {
            $self->m_tokens();
            if (!defined $self->token) {
                $self->emit();
            } elsif ($self->token == ANTLR::Runtime::Token->SKIP_TOKEN) {
                $op = 'next';
                return;
            }
            $op = 'return';
            $rv = $self->token;
        };
        return $rv if $op eq 'return';
        next if $op eq 'next';

        if ($EVAL_ERROR) {
            my $exception = $EVAL_ERROR;
            if ($exception->isa('ANTLR::Runtime::RecognitionException')) {
                $self->report_error($exception);
                $self->recover($exception);
            } else {
                croak $exception;
            }
        }
    }
}

# Instruct the lexer to skip creating a token for current lexer rule
# and look for another token.  nextToken() knows to keep looking when
# a lexer rule finishes with token set to SKIP_TOKEN.  Recall that
# if token==null at end of any token rule, it creates one for you
# and emits it.
sub skip {
    Readonly my $usage => 'skip()';
    croak $usage if @_ != 1;
    my ($self) = @_;

    $self->set_token(ANTLR::Runtime::Token->SKIP_TOKEN);
}

# This is the lexer entry point that sets instance var 'token'
sub m_tokens {
    croak "Unimplemented";
}

# Set the char stream and reset the lexer
sub set_char_stream {
    Readonly my $usage => 'set_char_stream(CharStream $input)';
    croak $usage if @_ != 2;
    my ($self, $input) = @_;

    $self->set_input(undef);
    $self->reset();
    $self->set_input($input);
}

sub emit {
    Readonly my $usage => 'void emit(Token $token) | Token emit()';
    croak $usage if @_ != 1 && @_ != 2;

    if (@_ == 1) {
        my ($self) = @_;
	# The standard method called to automatically emit a token at the
	# outermost lexical rule.  The token object should point into the
	# char buffer start..stop.  If there is a text override in 'text',
	# use that to set the token's text.  Override this method to emit
	# custom Token objects.
        my $t = ANTLR::Runtime::CommonToken->new({
            input => $self->input,
            type  => $self->type,
            channel => $self->channel,
            start => $self->token_start_char_index,
            stop => $self->get_char_index() - 1
        });

        $t->set_line($self->token_start_line);
        $t->set_text($self->text);
        $t->set_char_position_in_line($self->token_start_char_position_in_line);
        $self->emit($t);
        return $t;
    } elsif (@_ == 2) {
        my ($self, $token) = @_;
	# Currently does not support multiple emits per nextToken invocation
	# for efficiency reasons.  Subclass and override this method and
	# nextToken (to push tokens into a list and pull from that list rather
	# than a single variable as this implementation does).
        $self->token($token);
    }
}

sub match {
    Readonly my $usage => 'void match(string|char s)';
    croak $usage if @_ != 2;
    my ($self, $s) = @_;

    foreach my $c (split //, $s) {
        if ($self->input->LA(1) ne $c) {
            if ($self->backtracking > 0) {
                $self->failed(1);
                return;
            }
            my $mte = ANTLR::Runtime::MismatchedTokenException->new({
                expecting => $c,
                input => $self->input
            });
            $self->recover($mte);
            croak $mte;
        }
        $self->input->consume();
        $self->failed(0);
    }
}

sub match_any {
    Readonly my $usage => 'void match_any()';
    croak $usage if @_ != 1;
    my ($self) = @_;

    $self->consume();
}

sub match_range {
    Readonly my $usage => 'void match_range($a, $b)';
    croak $usage if @_ != 3;
    my ($self, $a, $b) = @_;

    if ($self->input->LA(1) lt $a || $self->input->LA(1) gt $b) {
        if ($self->backtracking > 0) {
            $self->failed(1);
            return;
        }

        my $mre = ANTLR::Runtime::MismatchedRangeException($a, $b, $self->input);
        $self->recover($mre);
        croak $mre;
    }

    $self->input->consume();
    $self->failed(0);
}

sub get_line {
    Readonly my $usage => 'int get_line()';
    croak $usage if @_ != 1;
    my ($self) = @_;

    return $self->input->get_line();
}

sub get_char_position_in_line {
    Readonly my $usage => 'int get_char_position_in_line()';
    croak $usage if @_ != 1;
    my ($self) = @_;

    return $self->input->get_char_position_in_line();
}

# What is the index of the current character of lookahead?
sub get_char_index {
    Readonly my $usage => 'int get_char_index()';
    croak $usage if @_ != 1;
    my ($self) = @_;

    return $self->input->index();
}

# Return the text matched so far for the current token or any
# text override.
sub get_text {
    Readonly my $usage => 'string get_text()';
    croak $usage if @_ != 1;
    my ($self) = @_;

    if (defined $self->text) {
        return $self->text;
    }
    return $self->input->substring($self->token_start_char_index, $self->get_char_index() - 1);
}

# Set the complete text of this token; it wipes any previous
# changes to the text.
sub set_text {
    Readonly my $usage => 'void set_text(string text)';
    croak $usage if @_ != 2;
    my ($self, $text) = @_;

    $self->text($text);
}

sub report_error {
    Readonly my $usage => 'void report_error(RecognitionException e)';
    croak $usage if @_ != 2;
    my ($self, $e) = @_;

    $self->display_recognition_error($self->get_token_names(), $e);
}

sub get_error_message {
    Readonly my $usage => 'String get_error_message(RecognitionException e, String[] token_names)';
    croak $usage if @_ != 3;
    my ($self, $e, $token_names) = @_;

    my $msg;
    if ($e->isa('ANTLR::Runtime::MismatchedTokenException')) {
        $msg = 'mismatched character '
          . $self->get_char_error_display($e->c)
          . ' expecting '
          . $self->get_char_error_display($e->expecting);
    } elsif ($e->isa('ANTLR::Runtime::NoViableAltException')) {
        $msg = 'no viable alternative at character ' . $self->get_char_error_display($e->c);
    } elsif ($e->isa('ANTLR::Runtime::EarlyExitException')) {
        $msg = 'required (...)+ loop did not match anything at character '
          . $self->get_char_error_display($e->c);
    } elsif ($e->isa('ANTLR::Runtime::MismatchedSetException')) {
        $msg = 'mismatched character ' . $self->get_char_error_display($e->c)
          . ' expecting set ' . $e->expecting;
    } elsif ($e->isa('ANTLR::Runtime::MismatchedNotSetException')) {
        $msg = 'mismatched character ' . $self->get_char_error_display($e->c)
          . ' expecting set ' . $e->expecting;
    } elsif ($e->isa('ANTLR::Runtime::MisMatchedRangeException')) {
        $msg = 'mismatched character ' . $self->get_char_error_display($e->c)
          . ' expecting set ' . $self->get_char_error_display($e->a)
          . '..' . $self->get_char_error_display($e->b);
    } else {
        $msg = $self->SUPER::get_error_message($e, $token_names);
    }
    return $msg;
}

sub get_char_error_display {
    Readonly my $usage => 'String get_char_error_display(int c)';
    croak $usage if @_ != 2;
    my ($self, $c) = @_;

    my $s;
    if ($c eq ANTLR::Runtime::Token->EOF) {
        $s = '<EOF>';
    } elsif ($c eq "\n") {
        $s = '\n';
    } elsif ($c eq "\t") {
        $s = '\t';
    } elsif ($c eq "\r") {
        $s = '\r';
    } else {
        $s = $c;
    }

    return "'$s'";
}

# Lexers can normally match any char in it's vocabulary after matching
# a token, so do the easy thing and just kill a character and hope
# it all works out.  You can instead use the rule invocation stack
# to do sophisticated error recovery if you are in a fragment rule.
sub recover {
    Readonly my $usage => 'void recover(RecognitionException re)';
    croak $usage if @_ != 2;
    my ($self, $re) = @_;

    $self->input->consume();
}

sub trace_in {
    Readonly my $usage => 'void trace_in(String rule_name, int rule_index)';
    croak $usage if @_ != 3;
    my ($self, $rule_name, $rule_index) = @_;

    my $input_symbol = $self->input->LT(1) . ' line=' . $self->get_line() . ':' . $self->get_char_position_in_line();
    $self->SUPER::trace_in($rule_name, $rule_index, $input_symbol);
}

sub trace_out {
    Readonly my $usage => 'void trace_out(String rule_name, int rule_index)';
    croak $usage if @_ != 3;
    my ($self, $rule_name, $rule_index) = @_;

    my $input_symbol = $self->input->LT(1) . ' line=' . $self->get_line() . ':' . $self->get_char_position_in_line();
    $self->SUPER::trace_out($rule_name, $rule_index, $input_symbol);
}

1;
