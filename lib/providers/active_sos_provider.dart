import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';

class ActiveSosProvider extends ChangeNotifier {
  Map<String, dynamic>? _activeSosCase;
  bool _isLoading = false;

  Map<String, dynamic>? get activeSosCase => _activeSosCase;
  bool get hasActiveCase => _activeSosCase != null;
  bool get isLoading => _isLoading;

  /// Save active SOS case to memory + SharedPreferences
  Future<void> setActiveCase(Map<String, dynamic> sosData) async {
    _activeSosCase = sosData;
    notifyListeners();

    // Persist to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_sos_case', jsonEncode(sosData));
    print('✅ Active SOS case saved to SharedPreferences');
  }

  /// Load active SOS case from SharedPreferences on app start
  Future<void> loadActiveCaseFromStorage() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final activeCaseStr = prefs.getString('active_sos_case');

      if (activeCaseStr != null) {
        final caseData = jsonDecode(activeCaseStr);

        // Verify case is still active by calling API
        final caseId = caseData['case']?['_id'];
        if (caseId != null) {
          try {
            final response = await ApiService.getSosCaseDetails(caseId);
            final currentCase = response['data']['case'];

            // Check if case is still ACCEPTED or IN_PROGRESS
            if (['ACCEPTED', 'IN_PROGRESS'].contains(currentCase['status'])) {
              _activeSosCase = response['data'];
              print('✅ Active SOS case loaded: $caseId');
            } else {
              // Case completed or cancelled, clear storage
              await clearActiveCase();
              print('ℹ️ Active case is no longer active, cleared.');
            }
          } catch (e) {
            print('❌ Error verifying active case: $e');
            // Keep local data for now, will retry later
            _activeSosCase = caseData;
          }
        }
      }
    } catch (e) {
      print('❌ Error loading active case: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear active SOS case (when completed)
  Future<void> clearActiveCase() async {
    _activeSosCase = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_sos_case');
    print('🗑️ Active SOS case cleared');
  }

  /// Complete the rescue
  Future<void> completeRescue() async {
    if (_activeSosCase == null) return;

    final caseId = _activeSosCase!['case']['_id'];

    try {
      await ApiService.completeSosCase(caseId);
      await clearActiveCase();
      print('✅ Rescue completed');
    } catch (e) {
      print('❌ Error completing rescue: $e');
      rethrow;
    }
  }
}
