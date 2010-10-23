package CatalystX::JobServer::JobRunner::JobsByUUID;
use CatalystX::JobServer::Moose::Role;
use MooseX::Types::Moose qw/ HashRef /;
use aliased 'CatalystX::JobServer::Job::Running';
use namespace::autoclean;

has jobs_by_uuid => (
    is => 'ro',
    traits    => ['Hash', 'Serialize'],
    isa => HashRef[Running],
    default => sub { {} },
    handles   => {
        _add_job_by_uuid => 'set',
        _remove_job_by_uuid => 'delete',
    },
);

has _jobs_by_uuid_handles => (
    is => 'ro',
    isa => HashRef,
    default => sub { {} },
);

before _remove_job_by_uuid => sub {
    my ($self, $uuid) = @_;
    delete $self->_jobs_by_uuid_handles->{$uuid};
};

before _add_job_by_uuid => sub {
    my ($self, $uuid) = @_;
    $self->_jobs_by_uuid_handles->{$uuid} = {};
};

before _remove_running => sub {
    my ($self, $job) = @_;
    if (exists $job->job->{uuid}) {
        warn("Sending messages to handles for " . $job->job->{uuid});
        foreach my $h (values %{$self->_jobs_by_uuid_handles->{$job->job->{uuid}}}) {
            $h->send_msg($job->pack);
        }
    }
};

sub register_listener {
    my ($self, $uuid, $h) = @_;
    return unless exists $self->jobs_by_uuid->{$uuid};
    warn("Added listener for $uuid");
    $self->_jobs_by_uuid_handles->{$uuid}->{refaddr($h)} = $h;
}

sub remove_listener {
    my ($self, $uuid, $h) = @_;
    warn("Removed listener for $uuid");
    delete $self->_jobs_by_uuid_handles->{$uuid}->{refaddr($h)};
}
