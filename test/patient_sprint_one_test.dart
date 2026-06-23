import 'package:flutter_test/flutter_test.dart';
import 'package:salamtak_mobile/features/patient/data/models/patient_dashboard_model.dart';
import 'package:salamtak_mobile/features/patient/data/models/patient_doctor_model.dart';
import 'package:salamtak_mobile/features/patient/data/models/patient_profile_model.dart';

void main() {
  test('dashboard parses backend PascalCase contract defensively', () {
    final dashboard = PatientDashboardModel.fromJson({
      'UpcomingAppointments': [
        {
          'AppointmentID': 4,
          'DoctorName': 'Dr Test',
          'AppointmentDate': '2026-07-01',
          'Time': '10:30:00',
          'Status': 'scheduled',
        },
      ],
      'Notifications': [
        {'NotificationID': 8, 'IsRead': false},
      ],
    });

    expect(dashboard.upcomingAppointments.single.id, 4);
    expect(dashboard.upcomingAppointments.single.doctorName, 'Dr Test');
    expect(dashboard.notifications.single.isRead, isFalse);
  });

  test('doctor parses rating and experience', () {
    final doctor = PatientDoctorModel.fromJson({
      'DoctorID': 3,
      'FullName': 'Dr Example',
      'Specialization': 'Cardiology',
      'YearsOfExperience': 8,
      'AverageRating': 4.6,
      'ReviewsCount': 12,
    });

    expect(doctor.id, 3);
    expect(doctor.yearsOfExperience, 8);
    expect(doctor.averageRating, 4.6);
  });

  test(
    'profile supports snake case and update sends supported fields only',
    () {
      final profile = PatientProfileModel.fromJson({
        'PatientID': 2,
        'full_name': 'Patient Name',
        'contact_number': '01000000000',
        'gender': 'female',
        'date_of_birth': '2000-01-01',
        'email': 'patient@example.com',
        'username': 'patient',
      });
      const update = PatientProfileUpdate(
        fullName: 'Updated Name',
        contactNumber: '01011111111',
        address: 'Cairo',
        bloodType: 'O+',
        medicalHistory: 'None',
      );

      expect(profile.gender, 'female');
      expect(update.toJson().keys, {
        'full_name',
        'contact_number',
        'address',
        'blood_type',
        'medical_history',
      });
      expect(update.toJson().containsKey('email'), isFalse);
    },
  );
}
