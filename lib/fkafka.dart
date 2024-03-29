library fkafka;

import 'dart:async';

import 'package:equatable/equatable.dart';

part 'package:fkafka/models/event.dart';
part 'package:fkafka/models/producer.dart';
part 'package:fkafka/models/subscriber.dart';
part 'package:fkafka/models/topic.dart';

typedef OnTopicCallBack = void Function(TopicData topic);

class Fkafka {
  static final Map<String, StreamController<FkafkaEvent>> _controllers = {};

  final Map<String, List<FkafkaSubscriber>> _subscribers = {};

  /// Should be called whenever Fkafka itself is not going to be
  /// used anymore.
  static void closeAll() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }

  /// Emit an event to all subscribers of [topic].
  void emit(String topic, [TopicData topicData = const TopicData()]) {
    _controllers.putIfAbsent(
      topic,
      () => StreamController.broadcast(),
    );

    _controllers[topic]!.add(
      FkafkaEvent(
        topic: topic,
        topicData: topicData.copyWith(
          topic: topic,
        ),
      ),
    );
  }

  /// Add a subscription to the [topic]
  void listen({
    required OnTopicCallBack onTopic,
    required String topic,
  }) {
    _controllers.putIfAbsent(
      topic,
      () => StreamController.broadcast(),
    );
    _subscribers.putIfAbsent(
      topic,
      () => [],
    );

    final subscription = _controllers[topic]!.stream.listen(
      (event) {
        onTopic(
          event.topicData,
        );
      },
    );
    _subscribers[topic]!.add(
      FkafkaSubscriber(
        isActive: true,
        onTopic: onTopic,
        subscription: subscription,
      ),
    );
  }

  /// Pause all the subscriptions from this instance of Fkafka to
  /// the [topic].
  void pauseListeningTo({
    required String topic,
  }) {
    _controllers.putIfAbsent(
      topic,
      () => StreamController.broadcast(),
    );

    final subscribers = _subscribers[topic] ?? <FkafkaSubscriber>[];

    for (var i = 0; i < subscribers.length; i++) {
      final subscriber = subscribers[i];
      subscriber.subscription.cancel();

      subscribers[i] = subscriber.copyWith(
        isActive: false,
      );
    }
  }

  /// Resume all the subscriptions from this instance of Fkafka to
  /// the [topic].
  void resumeListeningTo({
    required String topic,
  }) {
    _controllers.putIfAbsent(
      topic,
      () => StreamController.broadcast(),
    );

    final subscribers = _subscribers[topic] ?? <FkafkaSubscriber>[];

    for (var i = 0; i < subscribers.length; i++) {
      final subscriber = subscribers[i];
      subscriber.subscription.cancel();

      final subscription = _controllers[topic]!.stream.listen(
        (event) {
          subscriber.onTopic(
            event.topicData,
          );
        },
      );

      subscribers[i] = subscriber.copyWith(
        isActive: true,
        subscription: subscription,
      );
    }
  }

  /// Check if there is at least one active subscription to the
  /// [topic] in this instance of Fkafka.
  bool isListeningTo({
    required String topic,
  }) {
    return _subscribers[topic]?.isNotEmpty == true &&
        _subscribers[topic]!.any(
          (subscriber) => subscriber.isActive,
        );
  }

  /// Should be called whenever the instance of this Fkafka object is
  /// not going to be used anymore.
  void closeInstance() {
    for (final subscribers in _subscribers.values) {
      for (final subscriber in subscribers) {
        subscriber.subscription.cancel();
      }
    }
    _subscribers.clear();
  }
}
