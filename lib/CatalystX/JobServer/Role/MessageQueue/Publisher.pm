package CatalystX::JobServer::Role::MessageQueue::Publisher;
use CatalystX::JobServer::Moose::Role;

with 'CatalystX::JobServer::Role::MessageQueue::DeclaresExchange';

method publish_message ($message, $routing_key, $exchange_name) {
    $exchange_name ||= $self->exchange_name;
    $self->_channel->publish(
        body => $message,
        exchange => $exchange_name,
        routing_key => $routing_key,
    );
}

1;
