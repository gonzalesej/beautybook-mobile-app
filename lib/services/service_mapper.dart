import '../models/beauty_models.dart';
import 'service_repository.dart';

/// The only place the new UI touches your existing ServiceRepository.
Future<List<ServiceItem>> loadServices() async {
  final raw = await ServiceRepository().getServices();
  return raw.map(ServiceItem.fromMap).toList();
}