package CatalystX::JobServer::Web::Controller::Model::ForkedJobRunner;
use CatalystX::JobServer::Moose;
use MooseX::Types::Moose qw/ HashRef /;
use MooseX::Types::LoadableClass qw/ LoadableClass /;
use JSON::XS;
use Form::Functional::Reflector::Metaclass;
use Form::Functional::Renderer::TD;

BEGIN { extends 'Catalyst::Controller' }

sub base : Chained('/model/base') PathPart('ForkedJobRunner/job') CaptureArgs(0) {}

has jobs => (
    isa => HashRef,
    lazy => 1,
    traits => ['Hash'],
    handles => {
        jobs => 'keys',
        find_job_meta => 'get',
    },
    default => sub { return {
       map { to_LoadableClass($_); $_ => $_->meta } shift->_application->model('ForkedJobRunner')->jobs_registered->flatten
    };},
);

has rx => (
    isa => 'Data::Rx',
    is => 'ro',
    lazy => 1,
    default => sub {
        return shift->_application->model('Rx');
    },
);

sub display_jobs : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->res->body(JSON::XS->new->pretty(1)->encode({
        map { $_ => $c->uri_for_action('/model/forkedjobrunner/display_job', [$_])->as_string } $self->jobs
    }));
}

sub find_job : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $jobname) = @_;
    $c->stash(job_name => $jobname);
}

sub display_job : Chained('find_job') PathPart('') Args(0) {
    my ($self, $c) = @_;
    my $rx_reflector = Form::Functional::Reflector::MetaClass->new(
        field_outputter_class => 'Form::Functional::Reflector::FieldOutputter::Rx',
        field_composer_class => 'Form::Functional::Reflector::FieldComposer::Rx',
    );
    my $form_reflector = Form::Functional::Reflector::MetaClass->new();
    my $job_meta = $self->find_job_meta($c->stash->{job_name});

    my $form = $form_reflector->generate_output_from($job_meta->name);
    $c->res->body(
        q{<html><body><h1>Rx</h1><pre>} .
        JSON::XS->new->pretty(1)->encode($rx_reflector->generate_output_from( $job_meta ))
        . q{</pre><h1>Form:</h1>}
        . Form::Functional::Renderer::TD->new->render($form)
        . q{</body></html>}
    );
}



__PACKAGE__->meta->make_immutable;
1;
