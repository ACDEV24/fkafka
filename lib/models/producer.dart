part of 'package:flutter_kafka/flutter_kafka.dart';

abstract class KafkaProducer {
  final kafka = Kafka();

  void created(String topic, Map<String, dynamic> data) {
    kafka.emit(
      topic,
      TopicData(
        action: KafkaAction.created,
        data: data,
      ),
    );
  }

  void edited(String topic, Map<String, dynamic> data) {
    kafka.emit(
      topic,
      TopicData(
        action: KafkaAction.created,
        data: data,
      ),
    );
  }

  void deleted(String topic, Map<String, dynamic> data) {
    kafka.emit(
      topic,
      TopicData(
        action: KafkaAction.created,
        data: data,
      ),
    );
  }
}