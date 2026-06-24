import 'package:flutter_test/flutter_test.dart';
import 'package:salamtak_mobile/features/patient/data/models/patient_appointment_model.dart';
import 'package:salamtak_mobile/features/patient/data/models/patient_availability_slot_model.dart';
import 'package:salamtak_mobile/features/patient/data/models/patient_doctor_profile_model.dart';

void main() {
  test('appointment parses backend response fields defensively', () {
    final appointment = PatientAppointmentModel.fromJson({
      'AppointmentID': 12,
      'PatientID': 3,
      'DoctorID': 4,
      'HospitalID': 1,
      'DoctorName': 'Dr Salma',
      'Date': '2026-07-01',
      'Time': '09:30:00',
      'Status': 'scheduled',
      'InvoiceID': 44,
      'PaymentStatus': 'paid',
      'RefundLogged': false,
      'email_status': 'sent',
      'CanReview': false,
      'HasReview': false,
    });

    expect(appointment.id, 12);
    expect(appointment.displayDoctorName, 'Dr Salma');
    expect(appointment.isActive, isTrue);
    expect(appointment.paymentStatus, 'paid');
  });

  test('availability slot parses PascalCase backend shape', () {
    final slot = PatientAvailabilitySlotModel.fromJson({
      'Date': '2026-07-01',
      'Time': '10:00:00',
      'Status': 'Available',
      'AppointmentID': 0,
    });

    expect(slot.date, '2026-07-01');
    expect(slot.time, '10:00:00');
    expect(slot.displayTime, '10:00');
    expect(slot.available, isTrue);
  });

  test('doctor profile parses recent reviews and achievements', () {
    final profile = PatientDoctorProfileModel.fromJson({
      'DoctorID': 4,
      'FullName': 'Dr Salma',
      'Specialization': 'Cardiology',
      'YearsOfExperience': 9,
      'AverageRating': 4.8,
      'ReviewsCount': 2,
      'Achievements': 'Board certified; Heart clinic lead',
      'RecentReviews': [
        {
          'ReviewID': 1,
          'AppointmentID': 12,
          'Rating': 5,
          'Comment': 'Excellent',
          'PatientName': 'Patient',
        },
      ],
    });

    expect(profile.id, 4);
    expect(profile.achievementItems, hasLength(2));
    expect(profile.recentReviews.single.rating, 5);
  });
}
