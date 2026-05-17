import '../models/dashboard_data_model.dart';

abstract class StudentDashboardRepository {
  Future<DashboardDataModel> fetchDashboardData();
  DashboardDataModel? getCached() => null;
  void clearCache() {}
}
