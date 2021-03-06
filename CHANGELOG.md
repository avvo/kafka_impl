# Change Log
All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).
CHANGELOG inspiration from http://keepachangelog.com/.

## Unreleased

## [0.4.5] - October 10, 2017
* Remove unused NullHandler
* Extract KafkaImpl.Util.kafka_ex_worker helper function

## [0.4.4] - August 30, 2017
* Rename @impl attribute for Elixir 1.5 compatibility

## [0.4.3] - June 27, 2017
* Expose KafkaImpl.Util.brokers_parse func

## [0.4.2] - January 27, 2017
* Add KafkaImpl.offset_fetch

## [0.3.3] - December 13, 2016
* Implement storage of produced messages, and TestHelper.read_messages to read them

## [0.3.1] - November 4, 2016
* Fix behavior impl for KafkaMock with new create_no_name_worker/3

## [0.3.0] - November 4, 2016
* Upgrade to KafkaEx 0.6

## [0.2.0] - November 3, 2016
* Add last_committed_offset_for
* Move agent handling to Store
* Move test helper functions to TestHelper

## [0.1.0] - October 25, 2016
* Initial release
