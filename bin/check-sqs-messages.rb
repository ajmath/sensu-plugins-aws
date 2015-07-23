#! /usr/bin/env ruby
#
# check-sqs-messages
#
# DESCRIPTION:
#   This plugin checks the number of messages in an Amazon Web Services SQS queue.
#
# OUTPUT:
#   plain-text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: aws-sdk-v1
#   gem: sensu-plugin
#
# USAGE:
#   #YELLOW
#
#
# NOTES:
#
# LICENSE:
#   Copyright (c) 2013, Justin Lambert <jlambert@letsevenup.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'aws-sdk-v1'

#
# Check SQS Messages
#
class SQSMsgs < Sensu::Plugin::Check::CLI
  option :aws_access_key,
         short: '-a AWS_ACCESS_KEY',
         long: '--aws-access-key AWS_ACCESS_KEY',
         description: "AWS Access Key. Either set ENV['AWS_ACCESS_KEY'] or provide it as an option",
         default: ENV['AWS_ACCESS_KEY']

  option :aws_secret_access_key,
         short: '-k AWS_SECRET_KEY',
         long: '--aws-secret-access-key AWS_SECRET_KEY',
         description: "AWS Secret Access Key. Either set ENV['AWS_SECRET_KEY'] or provide it as an option",
         default: ENV['AWS_SECRET_KEY']

  option :aws_region,
         short: '-r AWS_REGION',
         long: '--aws-region REGION',
         description: 'AWS Region (defaults to us-east-1).',
         default: 'us-east-1'

  option :queue,
         short: '-q SQS_QUEUE',
         long: '--queue SQS_QUEUE',
         description: 'The name of the SQS you want to check the number of messages for',
         required: true

  option :warn_over,
         short: '-w WARN_OVER',
         long: '--warnnum WARN_OVER',
         description: 'Number of messages in the queue considered to be a warning',
         default: -1,
         proc: proc(&:to_i)

  option :crit_over,
         short: '-c CRIT_OVER',
         long: '--critnum CRIT_OVER',
         description: 'Number of messages in the queue considered to be critical',
         default: -1,
         proc: proc(&:to_i)

  option :warn_under,
         short: '-W WARN_UNDER',
         long: '--warnunder WARN_UNDER',
         description: 'Minimum number of messages in the queue considered to be a warning',
         default: -1,
         proc: proc(&:to_i)

  option :crit_under,
         short: '-C CRIT_UNDER',
         long: '--critunder CRIT_UNDER',
         description: 'Minimum number of messages in the queue considered to be critical',
         default: -1,
         proc: proc(&:to_i)

  def aws_config
    { access_key_id: config[:aws_access_key],
      secret_access_key: config[:aws_secret_access_key],
      region: config[:aws_region]
    }
  end

  def run
    AWS.config aws_config
    sqs = AWS::SQS.new
    messages = sqs.queues.named(config[:queue]).approximate_number_of_messages

    if (config[:crit_under] >= 0 && messages < config[:crit_under]) || (config[:crit_over] >= 0 && messages > config[:crit_over])
      critical "#{messages} message(s) in #{config[:queue]} queue"
    elsif (config[:warn_under] >= 0 && messages < config[:warn_under]) || (config[:warn_over] >= 0 && messages > config[:warn_over])
      warning "#{messages} message(s) in #{config[:queue]} queue"
    else
      ok "#{messages} messages in #{config[:queue]} queue"
    end
  end
end
